import type { Schema } from '../../data/resource.js';
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { randomUUID } from 'crypto';

const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);
const s3Client = new S3Client({});

export const handler: Schema["exportData"]["functionHandler"] = async (event: any) => {
  console.log("Export request received");
  
  const TRANSLATION_HISTORY_TABLE = process.env.TRANSLATION_HISTORY_TABLE;
  const SAVED_TRANSLATIONS_TABLE = process.env.SAVED_TRANSLATIONS_TABLE;
  const EXPORT_BUCKET = process.env.EXPORT_BUCKET;
  
  const userId = event.identity?.sub || event.arguments.user_id;
  if (!userId) throw new Error("Unauthorized");

  try {
      const { exportType, format, startDate, endDate } = event.arguments;
      
      if (!['history', 'saved', 'both'].includes(exportType)) throw new Error("Invalid exportType");
      if (!['json', 'csv'].includes(format.toLowerCase())) throw new Error("Invalid format");
      
      const results: any[] = [];
      
      if (['history', 'both'].includes(exportType)) {
          let req: any = {
              TableName: TRANSLATION_HISTORY_TABLE,
              KeyConditionExpression: "userId = :uid",
              ExpressionAttributeValues: { ":uid": userId }
          };
          if (startDate && endDate) {
              req.KeyConditionExpression += " AND #ts BETWEEN :start AND :end";
              req.ExpressionAttributeValues[":start"] = parseInt(startDate);
              req.ExpressionAttributeValues[":end"] = parseInt(endDate);
              req.ExpressionAttributeNames = { "#ts": "timestamp" };
          }
          
          let response = await docClient.send(new QueryCommand(req));
          let items = response.Items || [];
          items.forEach(i => i._type = 'history');
          results.push(...items);
      }
      
      if (['saved', 'both'].includes(exportType)) {
           let req: any = {
              TableName: SAVED_TRANSLATIONS_TABLE,
              KeyConditionExpression: "userId = :uid",
              ExpressionAttributeValues: { ":uid": userId }
          };
          // ... similarly fetching saved translations with pagination ...
          let response = await docClient.send(new QueryCommand(req));
          let items = response.Items || [];
          items.forEach(i => i._type = 'saved');
          results.push(...items);
      }
      
      if (results.length === 0) throw new Error("No data found to export");
      
      // Sort unified results by timestamp/savedAt descending
      results.sort((a, b) => {
          const timeA = parseFloat(a.timestamp || a.savedAt || 0);
          const timeB = parseFloat(b.timestamp || b.savedAt || 0);
          return timeB - timeA;
      });
      
      let fileContent = '';
      let contentType = '';
      let extension = '';
      
      if (format.toLowerCase() === 'json') {
          fileContent = JSON.stringify(results, null, 2);
          contentType = 'application/json';
          extension = 'json';
      } else {
          // crude CSV conversion
          const header = ['Type', 'Date', 'Source Language', 'Target Language', 'Original Text', 'Translated Text', 'Tags', 'Notes'].join(',') + '\n';
          const rows = results.map(item => {
              const dt = item.timestamp || item.savedAt || 0;
              const dateStr = dt ? new Date(Number(dt)).toISOString() : '';
              const tags = item.tags ? item.tags.join(';') : '';
              return [
                  item._type, dateStr, item.sourceLang, item.targetLang, 
                  `"${(item.sourceText||'').replace(/"/g, '""')}"`, 
                  `"${(item.targetText||'').replace(/"/g, '""')}"`, 
                  tags, `"${(item.notes||'').replace(/"/g, '""')}"`
              ].join(',');
          }).join('\n');
          fileContent = header + rows;
          contentType = 'text/csv';
          extension = 'csv';
      }
      
      const fileKey = `exports/${userId}/${Date.now()}_${randomUUID().substring(0,8)}.${extension}`;
      
      const command = new PutObjectCommand({
          Bucket: EXPORT_BUCKET,
          Key: fileKey,
          Body: fileContent,
          ContentType: contentType,
      });
      
      await s3Client.send(command);
      
      const url = await getSignedUrl(s3Client, { Bucket: EXPORT_BUCKET, Key: fileKey } as any, { expiresIn: 3600 });
      
      return {
          downloadUrl: url,
          expiresAt: Date.now() + 3600000,
          recordCount: results.length,
          exportDate: Date.now()
      };
      
  } catch (error) {
      console.error("Export operation failed:", error);
      throw error;
  }
};

import type { Schema } from '../../data/resource.js';
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand, DeleteCommand, PutCommand } from "@aws-sdk/lib-dynamodb";

const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);

export const handler: Schema["getHistory"]["functionHandler"] | Schema["addHistoryItem"]["functionHandler"] | Schema["deleteHistoryItem"]["functionHandler"] = async (event: any) => {
  console.log("History request received", event.info.fieldName);
  
  const TRANSLATION_HISTORY_TABLE = process.env.TRANSLATION_HISTORY_TABLE;
  if (!TRANSLATION_HISTORY_TABLE) {
    console.error("TRANSLATION_HISTORY_TABLE environment variable missing");
    // In AppSync Gen 2, if we use a1.model(), standard operations are auto-generated.
    // If we use custom functions, we need to bind the table name.
    // For this migration, we will map table names in the backend definition.
  }

  // AppSync provides identity information in event.identity
  const userId = event.identity?.sub || event.arguments.user_id;

  if (!userId) {
      throw new Error("Unauthorized: Missing userId");
  }

  const fieldName = event.info.fieldName;

  try {
      if (fieldName === 'getHistory') {
          const { page, pageSize, startDate, endDate } = event.arguments;
          const limit = Math.min(Math.max(pageSize || 20, 1), 100);
          
          let keyCondition = "userId = :uid";
          let expressionValues: any = { ":uid": userId };

          if (startDate && endDate) {
              keyCondition += " AND #ts BETWEEN :start AND :end";
              expressionValues[":start"] = parseInt(startDate);
              expressionValues[":end"] = parseInt(endDate);
          } else if (startDate) {
              keyCondition += " AND #ts >= :start";
              expressionValues[":start"] = parseInt(startDate);
          } else if (endDate) {
              keyCondition += " AND #ts <= :end";
              expressionValues[":end"] = parseInt(endDate);
          }

          const queryParams: any = {
              TableName: TRANSLATION_HISTORY_TABLE,
              KeyConditionExpression: keyCondition,
              ExpressionAttributeValues: expressionValues,
              Limit: limit,
              ScanIndexForward: false
          };

          if (startDate || endDate) {
             queryParams.ExpressionAttributeNames = { "#ts": "timestamp" };
          }

          const response = await docClient.send(new QueryCommand(queryParams));
          
          return {
              items: response.Items || [],
              count: (response.Items || []).length,
              lastEvaluatedKey: response.LastEvaluatedKey ? JSON.stringify(response.LastEvaluatedKey) : null,
              hasMore: !!response.LastEvaluatedKey
          };

      } else if (fieldName === 'addHistoryItem') {
          const { sourceText, sourceLang, targetText, targetLang, type, backend, processingTime } = event.arguments;
          const timestamp = event.arguments.timestamp || Date.now();

          const item = {
              userId,
              timestamp,
              sourceText,
              targetText,
              sourceLang,
              targetLang,
              backend: backend || 'offline',
              processingTime: processingTime || 0,
              type: type || 'translation'
          };

          await docClient.send(new PutCommand({
              TableName: TRANSLATION_HISTORY_TABLE,
              Item: item
          }));

          return { message: 'History item created', item };

      } else if (fieldName === 'deleteHistoryItem') {
          const { id } = event.arguments;
          // In original python, id was timestamp. We will assume id is timestamp string here.
          const timestamp = parseInt(id);

          if (!isNaN(timestamp)) {
              await docClient.send(new DeleteCommand({
                  TableName: TRANSLATION_HISTORY_TABLE,
                  Key: { userId, timestamp }
              }));
              return { message: 'History item deleted' };
          } else {
             // Delete all - ignoring for now as it requires complex batch deletes in DDB, 
             // but could be implemented if needed.
             throw new Error("Bulk delete not fully implemented in this port yet");
          }
      }

      throw new Error(`Unsupported operation: ${fieldName}`);

  } catch (error) {
      console.error("History operation failed:", error);
      throw error;
  }
};

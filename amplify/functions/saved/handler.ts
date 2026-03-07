import type { Schema } from '../../data/resource.js';
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand, DeleteCommand, PutCommand, UpdateCommand, TransactWriteCommand } from "@aws-sdk/lib-dynamodb";
import { randomUUID } from 'crypto';

const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);

const MAX_SAVED = 500;

export const handler: Schema["getSavedTranslations"]["functionHandler"] | Schema["saveTranslation"]["functionHandler"] | Schema["deleteSavedTranslation"]["functionHandler"] = async (event: any) => {
  console.log("Saved request received", event.info.fieldName);
  
  const SAVED_TRANSLATIONS_TABLE = process.env.SAVED_TRANSLATIONS_TABLE;
  const userId = event.identity?.sub || event.arguments.user_id;

  if (!userId) throw new Error("Unauthorized");

  const fieldName = event.info.fieldName;

  try {
      if (fieldName === 'getSavedTranslations') {
          const { page, pageSize, search } = event.arguments;
          
          const response = await docClient.send(new QueryCommand({
              TableName: SAVED_TRANSLATIONS_TABLE,
              KeyConditionExpression: "userId = :uid",
              ExpressionAttributeValues: { ":uid": userId }
          }));
          
          let items = response.Items || [];
          
          if (search) {
              const searchTerm = search.toLowerCase();
              items = items.filter(item => {
                  const tags = item.tags || [];
                  const text = `${item.sourceText || ''} ${item.targetText || ''} ${tags.join(' ')}`.toLowerCase();
                  return text.includes(searchTerm);
              });
          }
          
          return { items, count: items.length };

      } else if (fieldName === 'saveTranslation') {
          const { translation_id, source_text, source_lang, translated_text, target_lang, tags } = event.arguments;
          
          const now = Date.now();
          const item = {
              userId,
              translationId: translation_id || randomUUID(),
              sourceText: source_text,
              targetText: translated_text,
              sourceLang: source_lang,
              targetLang: target_lang,
              tags: tags || [],
              savedAt: now,
              updatedAt: now,
              usageCount: 1,
              lastAccessedAt: now
          };

          try {
              await docClient.send(new TransactWriteCommand({
                  TransactItems: [
                      {
                          Update: {
                              TableName: SAVED_TRANSLATIONS_TABLE,
                              Key: { userId, translationId: 'METADATA#COUNT' },
                              UpdateExpression: 'ADD savedCount :inc',
                              ConditionExpression: 'attribute_not_exists(savedCount) OR savedCount < :max',
                              ExpressionAttributeValues: { ':inc': 1, ':max': MAX_SAVED }
                          }
                      },
                      {
                          Put: {
                              TableName: SAVED_TRANSLATIONS_TABLE,
                              Item: item
                          }
                      }
                  ]
              }));
          } catch (e: any) {
              if (e.name === 'TransactionCanceledException' && e.message.includes('ConditionalCheckFailed')) {
                  throw new Error(`Limit exceeded: Maximum ${MAX_SAVED} saved translations allowed per user`);
              }
              throw e;
          }

          return { message: 'Translation saved', item };

      } else if (fieldName === 'deleteSavedTranslation') {
          const { id } = event.arguments;

          try {
              await docClient.send(new TransactWriteCommand({
                  TransactItems: [
                      {
                          Update: {
                              TableName: SAVED_TRANSLATIONS_TABLE,
                              Key: { userId, translationId: 'METADATA#COUNT' },
                              UpdateExpression: 'ADD savedCount :dec',
                              ExpressionAttributeValues: { ':dec': -1 }
                          }
                      },
                      {
                          Delete: {
                              TableName: SAVED_TRANSLATIONS_TABLE,
                              Key: { userId, translationId: id }
                          }
                      }
                  ]
              }));
          } catch (e) {
              // Fallback
              await docClient.send(new DeleteCommand({
                  TableName: SAVED_TRANSLATIONS_TABLE,
                  Key: { userId, translationId: id }
              }));
          }
          
          return { message: 'Translation unsaved' };
      }

      throw new Error(`Unsupported operation: ${fieldName}`);

  } catch (error) {
      console.error("Saved operation failed:", error);
      throw error;
  }
};

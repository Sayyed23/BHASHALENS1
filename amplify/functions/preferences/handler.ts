import type { Schema } from '../../data/resource.js';
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const ddbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(ddbClient);

const DEFAULT_PREFERENCES = {
    theme: 'system',
    defaultSourceLang: 'en',
    defaultTargetLang: 'hi',
    dataUsagePolicy: 'standard',
    accessibilitySettings: {
        highContrast: false,
        largeText: false,
        reduceMotion: false
    },
    notificationSettings: {
        dailyReminders: false,
        appUpdates: true
    },
    version: 1
};

export const handler: Schema["getPreferences"]["functionHandler"] | Schema["updatePreferences"]["functionHandler"] = async (event: any) => {
  console.log("Preferences request received", event.info.fieldName);
  
  const USER_PREFERENCES_TABLE = process.env.USER_PREFERENCES_TABLE;
  const userId = event.identity?.sub || event.arguments.user_id;

  if (!userId) throw new Error("Unauthorized");

  const fieldName = event.info.fieldName;

  try {
      if (fieldName === 'getPreferences') {
          const response = await docClient.send(new GetCommand({
              TableName: USER_PREFERENCES_TABLE,
              Key: { userId }
          }));
          
          if (response.Item) {
              return response.Item;
          }
          
          const prefs = { ...DEFAULT_PREFERENCES, userId, version: 0, createdAt: Date.now(), updatedAt: Date.now() };
          return prefs;

      } else if (fieldName === 'updatePreferences') {
          let { preferences } = event.arguments;
          if (typeof preferences === 'string') preferences = JSON.parse(preferences);
          
          const now = Date.now();
          const clientVersion = preferences.version || 0;
          
          let newItem: any = { ...DEFAULT_PREFERENCES };
          
          const allowedKeys = ['theme', 'defaultSourceLang', 'defaultTargetLang', 'dataUsagePolicy'];
          for (const k of allowedKeys) {
              if (preferences[k] !== undefined) newItem[k] = preferences[k];
          }
          if (preferences.accessibilitySettings) {
             newItem.accessibilitySettings = { ...newItem.accessibilitySettings, ...preferences.accessibilitySettings };
          }
          if (preferences.notificationSettings) {
             newItem.notificationSettings = { ...newItem.notificationSettings, ...preferences.notificationSettings };
          }

          newItem.userId = userId;
          newItem.updatedAt = now;
          newItem.lastSyncedAt = now;

          if (clientVersion === 0) {
              newItem.version = 1;
              newItem.createdAt = now;
              try {
                  await docClient.send(new PutCommand({
                      TableName: USER_PREFERENCES_TABLE,
                      Item: newItem,
                      ConditionExpression: 'attribute_not_exists(userId)'
                  }));
              } catch (e: any) {
                  if (e.name === 'ConditionalCheckFailedException') throw e;
              }
          } else {
              newItem.version = clientVersion + 1;
              const existing = await docClient.send(new GetCommand({
                  TableName: USER_PREFERENCES_TABLE,
                  Key: { userId }
              }));
              newItem.createdAt = existing.Item?.createdAt || now;
              
              try {
                  await docClient.send(new PutCommand({
                      TableName: USER_PREFERENCES_TABLE,
                      Item: newItem,
                      ConditionExpression: 'version = :cv',
                      ExpressionAttributeValues: { ':cv': clientVersion }
                  }));
              } catch (e: any) {
                  if (e.name === 'ConditionalCheckFailedException') {
                      throw new Error("Version conflict: The provided version does not match the current server version.");
                  }
                  throw e;
              }
          }
          
          return newItem;
      }

      throw new Error(`Unsupported operation: ${fieldName}`);

  } catch (error) {
      console.error("Preferences operation failed:", error);
      throw error;
  }
};

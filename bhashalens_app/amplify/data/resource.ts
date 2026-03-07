// @ts-ignore
import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

// Define the Data models that map to DynamoDB
const schema = a.schema({
  TranslationHistory: a.model({
    originalText: a.string().required(),
    translatedText: a.string().required(),
    sourceLanguage: a.string(),
    targetLanguage: a.string(),
    timestamp: a.datetime().required(),
    userId: a.string(), // Optional for anonymous usage initially
  }).authorization((allow: any) => [allow.publicApiKey()]),

  SavedTranslations: a.model({
    phrase: a.string().required(),
    intent: a.string(),
    translatedPhrase: a.string().required(),
    timestamp: a.datetime().required(),
    userId: a.string(),
  }).authorization((allow: any) => [allow.publicApiKey()]),

  UserPreferences: a.model({
    userId: a.string().required(),
    preferredSource: a.string(),
    preferredTarget: a.string(),
    theme: a.string(),
    voiceOutputEnabled: a.boolean(),
  }).authorization((allow: any) => [allow.publicApiKey()]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'apiKey',
    apiKeyAuthorizationMode: {
      expiresInDays: 30, // For development purposes
    },
  },
});

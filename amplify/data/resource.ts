import { type ClientSchema, a, defineData } from '@aws-amplify/backend';
import { translationFunction } from '../functions/translation/resource.js';
import { assistanceFunction } from '../functions/assistance/resource.js';
import { simplificationFunction } from '../functions/simplification/resource.js';
import { historyFunction } from '../functions/history/resource.js';
import { savedFunction } from '../functions/saved/resource.js';
import { preferencesFunction } from '../functions/preferences/resource.js';
import { exportFunction } from '../functions/export/resource.js';

const schema = a.schema({
  translate: a
    .query()
    .arguments({
      source_text: a.string().required(),
      source_lang: a.string().required(),
      target_lang: a.string().required(),
      user_id: a.string()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(translationFunction)),

  assist: a
    .query()
    .arguments({
      request_type: a.string().required(),
      text: a.string().required(),
      language: a.string().required(),
      context: a.string(),
      conversation_history: a.json(),
      user_id: a.string()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(assistanceFunction)),

  simplify: a
    .query()
    .arguments({
      text: a.string().required(),
      target_complexity: a.string().required(),
      language: a.string().required(),
      explain: a.boolean(),
      user_id: a.string()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(simplificationFunction)),

  getHistory: a
    .query()
    .arguments({
      page: a.integer(),
      pageSize: a.integer(),
      startDate: a.string(),
      endDate: a.string()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(historyFunction)),

  addHistoryItem: a
    .mutation()
    .arguments({
      sourceText: a.string().required(),
      sourceLang: a.string().required(),
      targetText: a.string().required(),
      targetLang: a.string().required(),
      timestamp: a.integer(),
      type: a.string(),
      backend: a.string(),
      processingTime: a.integer()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(historyFunction)),

  deleteHistoryItem: a
    .mutation()
    .arguments({
      id: a.string().required()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(historyFunction)),

  getSavedTranslations: a
    .query()
    .arguments({
      page: a.integer(),
      pageSize: a.integer(),
      search: a.string()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(savedFunction)),

  saveTranslation: a
    .mutation()
    .arguments({
      translation_id: a.string().required(),
      source_text: a.string().required(),
      source_lang: a.string().required(),
      translated_text: a.string().required(),
      target_lang: a.string().required(),
      tags: a.string().array()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(savedFunction)),

  deleteSavedTranslation: a
    .mutation()
    .arguments({
      id: a.string().required()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(savedFunction)),

  getPreferences: a
    .query()
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(preferencesFunction)),

  updatePreferences: a
    .mutation()
    .arguments({
      preferences: a.json().required()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(preferencesFunction)),

  exportData: a
    .mutation()
    .arguments({
      exportType: a.string().required(),
      format: a.string().required(),
      startDate: a.string(),
      endDate: a.string()
    })
    .returns(a.json())
    .authorization((allow: any) => [allow.guest()])
    .handler(a.handler.function(exportFunction))
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'iam',
  },
});

import { defineBackend } from '@aws-amplify/backend';
import { translationFunction } from './functions/translation/resource.js';
import { assistanceFunction } from './functions/assistance/resource.js';
import { simplificationFunction } from './functions/simplification/resource.js';
import { historyFunction } from './functions/history/resource.js';
import { savedFunction } from './functions/saved/resource.js';
import { preferencesFunction } from './functions/preferences/resource.js';
import { exportFunction } from './functions/export/resource.js';
import { auth } from './auth/resource.js';
import { data } from './data/resource.js';
import { storage } from './storage/resource.js';

const backend = defineBackend({
  auth,
  data,
  storage,
  translationFunction,
  assistanceFunction,
  simplificationFunction,
  historyFunction,
  savedFunction,
  preferencesFunction,
  exportFunction
});

backend.translationFunction.addEnvironment('TRANSLATION_HISTORY_TABLE', backend.data.resources.tables['TranslationHistory']?.tableName || '');
backend.historyFunction.addEnvironment('TRANSLATION_HISTORY_TABLE', backend.data.resources.tables['TranslationHistory']?.tableName || '');
backend.savedFunction.addEnvironment('SAVED_TRANSLATIONS_TABLE', backend.data.resources.tables['SavedTranslations']?.tableName || '');
backend.preferencesFunction.addEnvironment('USER_PREFERENCES_TABLE', backend.data.resources.tables['UserPreferences']?.tableName || '');

backend.exportFunction.addEnvironment('TRANSLATION_HISTORY_TABLE', backend.data.resources.tables['TranslationHistory']?.tableName || '');
backend.exportFunction.addEnvironment('SAVED_TRANSLATIONS_TABLE', backend.data.resources.tables['SavedTranslations']?.tableName || '');

backend.exportFunction.addEnvironment('EXPORT_BUCKET', backend.storage.resources.bucket.bucketName);

// Grant permissions to functions
backend.storage.resources.bucket.grantReadWrite(backend.exportFunction.resources.lambda);

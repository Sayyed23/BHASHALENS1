import { defineFunction } from '@aws-amplify/backend';

export const preferencesFunction = defineFunction({
  name: 'preferences',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

import { defineFunction } from '@aws-amplify/backend';

export const translationFunction = defineFunction({
  name: 'translation',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

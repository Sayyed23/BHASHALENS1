import { defineFunction } from '@aws-amplify/backend';

export const savedFunction = defineFunction({
  name: 'saved',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

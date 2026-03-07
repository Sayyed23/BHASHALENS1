import { defineFunction } from '@aws-amplify/backend';

export const historyFunction = defineFunction({
  name: 'history',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

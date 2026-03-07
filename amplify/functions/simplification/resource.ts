import { defineFunction } from '@aws-amplify/backend';

export const simplificationFunction = defineFunction({
  name: 'simplification',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

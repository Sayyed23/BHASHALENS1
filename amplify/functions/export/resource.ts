import { defineFunction } from '@aws-amplify/backend';

export const exportFunction = defineFunction({
  name: 'exportData',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

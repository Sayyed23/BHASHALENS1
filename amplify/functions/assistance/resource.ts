import { defineFunction } from '@aws-amplify/backend';

export const assistanceFunction = defineFunction({
  name: 'assistance',
  entry: './handler.ts',
  timeoutSeconds: 30,
  memoryMB: 512,
});

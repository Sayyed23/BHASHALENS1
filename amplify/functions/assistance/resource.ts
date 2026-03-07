import { defineFunction } from '@aws-amplify/backend';

export const assistanceFunction = defineFunction({
  name: 'assistance',
  entry: './handler.ts',
  environment: {
    BEDROCK_MODEL_ID: 'apac.anthropic.claude-sonnet-4-20250514-v1:0',
  },
  timeoutSeconds: 30,
  memoryMB: 512,
});

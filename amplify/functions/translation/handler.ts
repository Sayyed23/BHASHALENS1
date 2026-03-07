import type { Schema } from '../../data/resource.js';
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

const bedrockClient = new BedrockRuntimeClient();

export const handler: Schema["translate"]["functionHandler"] = async (event: any) => {
  console.log("Translation request received");
  
  const { source_text, source_lang, target_lang, user_id } = event.arguments;

  const BEDROCK_MODEL_ID = process.env.BEDROCK_MODEL_ID || 'anthropic.claude-3-sonnet-20240229-v1:0';

  const langMap: Record<string, string> = {
    hi: 'Hindi',
    mr: 'Marathi',
    en: 'English'
  };

  const sourceLanguage = langMap[source_lang] || source_lang;
  const targetLanguage = langMap[target_lang] || target_lang;

  const prompt = `Translate from ${sourceLanguage} to ${targetLanguage}. Output only the translation.\n\n${source_text}`;

  const requestBody = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: Math.min(2048, Math.max(256, source_text.length * 3)),
    temperature: 0.3,
    messages: [{ role: "user", content: prompt }]
  };

  try {
    const startTime = Date.now();
    const command = new InvokeModelCommand({
      modelId: BEDROCK_MODEL_ID,
      contentType: "application/json",
      accept: "application/json",
      body: JSON.stringify(requestBody),
    });

    const response = await bedrockClient.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    
    const content = responseBody.content || [];
    if (!content.length || !content[0].text) {
      throw new Error("Unexpected Bedrock response format");
    }

    const translatedText = content[0].text.trim();
    const stopReason = responseBody.stop_reason || 'end_turn';
    const confidence = stopReason === 'end_turn' ? 0.90 : 0.75;

    const processingTimeMs = Date.now() - startTime;

    // Output is sent back to AppSync
    return {
      translated_text: translatedText,
      confidence: confidence,
      model: BEDROCK_MODEL_ID,
      processing_time_ms: processingTimeMs,
      // Note: we can optionally hit DynamoDb here via @aws-sdk/client-dynamodb 
      // if we still want manual inserts, OR AppSync can handle inserts via mutations
    };
  } catch (error) {
    console.error("Translation request failed:", error);
    throw error;
  }
};

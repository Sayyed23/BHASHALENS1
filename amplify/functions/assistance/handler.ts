import type { Schema } from '../../data/resource.js';
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

const bedrockClient = new BedrockRuntimeClient();

export const handler: Schema["assist"]["functionHandler"] = async (event: any) => {
  console.log("Assistance request received");
  
  const { request_type, text, language, context, conversation_history, user_id } = event.arguments;

  const BEDROCK_MODEL_ID = process.env.BEDROCK_MODEL_ID || 'apac.anthropic.claude-sonnet-4-20250514-v1:0';

  const validTypes = ['grammar', 'qa', 'conversation'];
  if (!validTypes.includes(request_type)) {
     throw new Error(`Invalid request_type`);
  }

  const langMap: Record<string, string> = {
    hi: 'Hindi', mr: 'Marathi', en: 'English', ta: 'Tamil', te: 'Telugu', bn: 'Bengali'
  };
  const langName = langMap[language] || language;

  let prompt = '';
  let responseData: any = {};

  if (request_type === 'grammar') {
    prompt = `You are a ${langName} expert. Check for grammar errors. Format as JSON with "corrected_text" and "corrections" list of dicts (original, corrected, explanation):\n\n${text}`;
  } else if (request_type === 'qa') {
    prompt = `You are a helpful assistant helping Indian users. \nPlease answer the following question in ${langName}. \nIf context is provided, use it to give a more accurate and relevant answer.\nKeep the answer simple and direct.\n\nQuestion: ${text}`;
    if (context) prompt += `\nContext: ${context}`;
  } else if (request_type === 'conversation') {
    prompt = `System: You are a friendly ${langName} practice partner helping the user improve their language skills.\n`;
    const history = conversation_history as {role?: string, content?: string}[] || [];
    for (const msg of history.slice(-10)) {
        if (!msg.content) continue;
        const role = msg.role === "system" ? "System" : msg.role === "user" ? "User" : "Assistant";
        prompt += `${role}: ${msg.content}\n`;
    }
    prompt += `User: ${text}\nAssistant:`;
  }

  const requestBody = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 2048,
    temperature: 0.7,
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

    const rawResponse = content[0].text.trim();
    const processingTimeMs = Date.now() - startTime;
    
    if (request_type === 'grammar') {
        let parsed;
        try {
            let resToParse = rawResponse;
            if (resToParse.includes("```")) {
                resToParse = resToParse.split("```")[1];
                if (resToParse.startsWith("json\n")) resToParse = resToParse.substring(5);
            }
            parsed = JSON.parse(resToParse.trim());
        } catch(e) {
            parsed = { "corrected_text": rawResponse, "corrections": [] };
        }
        responseData = { response: parsed.corrected_text || text, metadata: { corrections: parsed.corrections || [] } };
    } else if (request_type === 'qa') {
        responseData = { response: rawResponse, metadata: { language: langName } };
    } else if (request_type === 'conversation') {
        const historyLength = (conversation_history as any[])?.length || 0;
        responseData = { response: rawResponse, metadata: { language: langName, conversation_length: historyLength + 1 }};
    }

    return {
      response: responseData.response,
      metadata: responseData.metadata,
      model: BEDROCK_MODEL_ID,
      processing_time_ms: processingTimeMs
    };
  } catch (error) {
    console.error("Assistance request failed:", error);
    throw error;
  }
};

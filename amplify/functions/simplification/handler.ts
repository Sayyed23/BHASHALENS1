import type { Schema } from '../../data/resource.js';
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

const bedrockClient = new BedrockRuntimeClient();

export const handler: Schema["simplify"]["functionHandler"] = async (event: any) => {
  console.log("Simplification request received");
  
  const { text, target_complexity, language, explain, user_id } = event.arguments;

  const BEDROCK_MODEL_ID = process.env.BEDROCK_MODEL_ID || 'apac.anthropic.claude-sonnet-4-20250514-v1:0';
  const validComplexity = ['simple', 'moderate', 'complex'];
  const complexity = target_complexity || 'simple';

  if (!validComplexity.includes(complexity)) {
     throw new Error(`Invalid target_complexity`);
  }

  const langMap: Record<string, string> = {
    hi: 'Hindi', mr: 'Marathi', en: 'English', ta: 'Tamil', te: 'Telugu', bn: 'Bengali'
  };
  const langName = langMap[language] || language;

  const instructions: Record<string, string> = {
    'simple': 'very simple, clear language with short sentences and easy words',
    'moderate': 'clear and accessible language while maintaining some detail',
    'complex': 'concise and accurate language, slightly simplified but preserving professional nuances'
  };
  
  const inst = instructions[complexity] || instructions['simple'];
  const prompt = `You are a helpful assistant helping Indian users understand complex text.\nSimplify the following ${langName} text using ${inst}. \nPreserve the core meaning but make it easily understandable for a layperson.\nOutput ONLY the simplified text:\n\n${text}`;

  const requestBody = {
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 2048,
    temperature: 0.5,
    messages: [{ role: "user", content: prompt }]
  };

  try {
    const startTime = Date.now();
    
    // 1. Generate simplification
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
      throw new Error("Unexpected Bedrock response format for simplification");
    }

    const simplifiedText = content[0].text.trim();
    
    // 2. Generate explanation if requested
    let explanation = null;
    if (explain) {
        const explainPrompt = `Provide a brief educational explanation in ${langName} comparing the original to the simplified version.\nExplain WHY specific complex terms were changed and what they mean.\nKeep it encouraging and helpful.\n\nOriginal: ${text}\nSimplified: ${simplifiedText}`;
        const explainCommand = new InvokeModelCommand({
            modelId: BEDROCK_MODEL_ID,
            contentType: "application/json",
            accept: "application/json",
            body: JSON.stringify({
                anthropic_version: "bedrock-2023-05-31",
                max_tokens: 2048,
                temperature: 0.5,
                messages: [{ role: "user", content: explainPrompt }]
            }),
        });
        const explainResponse = await bedrockClient.send(explainCommand);
        const explainResponseBody = JSON.parse(new TextDecoder().decode(explainResponse.body));
        if (explainResponseBody.content && explainResponseBody.content.length > 0) {
            explanation = explainResponseBody.content[0].text.trim();
        }
    }

    const processingTimeMs = Date.now() - startTime;
    
    // 3. Calculate complexity reduction ratio loosely
    const origWords = text.split(" ").length;
    const simpWords = simplifiedText.split(" ").length;
    const wordCountFactor = Math.min(1.0, (origWords - simpWords) / Math.max(origWords, 1));
    const complexityReduction = Math.max(0.0, Math.min(1.0, wordCountFactor * 0.4)); // Simplified metric for demo

    return {
      simplified_text: simplifiedText,
      explanation: explanation,
      complexity_reduction: Number(complexityReduction.toFixed(2)),
      model: BEDROCK_MODEL_ID,
      processing_time_ms: processingTimeMs
    };
  } catch (error) {
    console.error("Simplification request failed:", error);
    throw error;
  }
};

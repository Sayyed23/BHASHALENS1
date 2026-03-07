import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";

const bedrockClient = new BedrockRuntimeClient({ region: "us-east-1" });

const MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0";

export const handler = async (event: any) => {
  console.log("Assistance/Explain request received:", JSON.stringify(event));

  const { text, targetLanguage, sourceLanguage, mode } =
    event.arguments || event;

  if (!text) {
    throw new Error("Missing required field: text");
  }

  const lang = targetLanguage || "English";
  const prompt = `You are a language learning assistant. Explain the following text in ${lang}.

Provide a JSON response with these fields:
- "translation": the text translated to ${lang}
- "meaning": a clear explanation of what the text means
- "context": cultural or situational context if relevant
- "usage_examples": 2-3 example sentences showing how key phrases are used
- "difficulty_level": rate the text difficulty (beginner/intermediate/advanced)

Text: ${text}
${sourceLanguage ? `Source language: ${sourceLanguage}` : ""}

Return ONLY valid JSON.`;

  try {
    const response = await bedrockClient.send(
      new InvokeModelCommand({
        modelId: MODEL_ID,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify({
          anthropic_version: "bedrock-2023-05-31",
          max_tokens: 4096,
          messages: [
            {
              role: "user",
              content: prompt,
            },
          ],
        }),
      })
    );

    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const resultText =
      responseBody.content?.[0]?.text || "Explanation failed";

    try {
      const parsed = JSON.parse(resultText);
      return {
        ...parsed,
        model: MODEL_ID,
        backend: "bedrock-claude",
      };
    } catch {
      return {
        explanation: resultText.trim(),
        meaning: resultText.trim(),
        translation: "N/A",
        model: MODEL_ID,
        backend: "bedrock-claude",
      };
    }
  } catch (error) {
    console.error("Assistance/Explain failed:", error);
    throw error;
  }
};

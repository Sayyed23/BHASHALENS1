import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";

const bedrockClient = new BedrockRuntimeClient({ region: "us-east-1" });

const MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0";

export const handler = async (event: any) => {
  console.log("Simplification request received:", JSON.stringify(event));

  const { text, targetComplexity, language } = event.arguments || event;

  if (!text) {
    throw new Error("Missing required field: text");
  }

  const complexity = targetComplexity || "simple";
  const lang = language || "English";

  const prompt = `Simplify the following text to a "${complexity}" reading level. 
The response should be in ${lang}.
Make the text easier to understand while preserving the core meaning.
Return ONLY the simplified text, nothing else.

Text: ${text}`;

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
    const simplifiedText =
      responseBody.content?.[0]?.text || "Simplification failed";

    return {
      simplifiedText: simplifiedText.trim(),
      originalComplexity: "advanced",
      targetComplexity: complexity,
      language: lang,
      model: MODEL_ID,
      backend: "bedrock-claude",
    };
  } catch (error) {
    console.error("Simplification failed:", error);
    throw error;
  }
};

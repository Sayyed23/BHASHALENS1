import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from "@aws-sdk/client-bedrock-runtime";

const bedrockClient = new BedrockRuntimeClient({ region: "us-east-1" });

const MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0";

export const handler = async (event: any) => {
  console.log("Translation request received:", JSON.stringify(event));

  const { sourceText, sourceLang, targetLang } = event.arguments || event;

  if (!sourceText || !targetLang) {
    throw new Error("Missing required fields: sourceText, targetLang");
  }

  const prompt = `Translate the following text from ${sourceLang || "auto-detect"} to ${targetLang}. Return ONLY the translated text, nothing else.\n\nText: ${sourceText}`;

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
    const translatedText =
      responseBody.content?.[0]?.text || "Translation failed";

    return {
      translatedText: translatedText.trim(),
      sourceLang: sourceLang || "auto",
      targetLang,
      model: MODEL_ID,
      backend: "bedrock-claude",
    };
  } catch (error) {
    console.error("Translation failed:", error);
    throw error;
  }
};

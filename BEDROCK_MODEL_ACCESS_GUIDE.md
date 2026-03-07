# AWS Bedrock Model Access Guide (Claude 3.7)

Since the legacy "Model Access" workflow is being unified into the **Model Catalog**, follow these precise steps to ensure **BhashaLens** can correctly invoke Claude 3.7 via AWS Bedrock.

---

## 1. Navigate to Model Catalog
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/bedrock/).
2. Ensure you are in a **Supported Region** (e.g., `us-east-1` N. Virginia or `us-west-2` Oregon), as Claude 3.7 is first available there.
3. In the left navigation pane, under **Foundation models**, select **Model catalog**.

## 2. Locate and Request Claude 3.7
1. In the search bar, type **"Claude 3.7 Sonnet"**.
2. Click on the **Claude 3.7 Sonnet** card.
3. On the model detail page, click the **Request access** button (usually at the top right).
   - *Note: If you have already requested access to the Claude 3 family, 3.7 may already be active, but it's essential to verify.*
4. If prompted, provide your use case details (e.g., "AI-powered language assistance and translation app").
5. Wait for the status to change to **Access granted**.

## 3. Identify the Correct Model ID
For the `lambda_orchestrator.py` and the Flutter app to work, you must use the exact model identifier. 

| Model Variant | Model ID |
| :--- | :--- |
| **Claude 3.7 Sonnet** | `anthropic.claude-3-7-sonnet-20250219-v1:0` |

> [!IMPORTANT]
> Double-check the **Model ARN** in the "Model information" section of the catalog to ensure it matches the ID used in your Lambda code.

## 4. IAM Permissions for Lambda
The Lambda execution role must have permission to invoke this specific model. Update your IAM Role policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "bedrock:InvokeModel",
            "Resource": "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-7-sonnet-20250219-v1:0"
        }
    ]
}
```

## 5. Connecting the App
1. **Lambda Environment**: Ensure the `GEMINI_API_KEY` is set in the Lambda configuration if using the rewriting layer.
2. **API Gateway**: Deploy your API Gateway to a stage (e.g., `prod`) and copy the **Invoke URL**.
3. **Flutter App**: Update your `.env` or configuration file in the app with the new AWS API Gateway URL.

---
### Troubleshooting
- **Region Mismatch**: If you get a "Model not found" error, ensure your Lambda and your Bedrock model request are in the **SAME region**.
- **Model Access Status**: Visit the **Model access** page (under Bedrock -> Foundation models) to see a summary of all granted models at a glance.

# AWS Manual Configuration Guide (BhashaLens)

This guide provides deep-dive instructions for manually setting up the **BhashaLens Orchestration Layer** using the AWS Management Console.

---

## 1. Create the Lambda Function (Orchestrator)

1. **Navigate to Lambda**: In the AWS Console, search for and select **Lambda**.
2. **Create Function**:
   - **Name**: `BhashaLensOrchestrator`
   - **Runtime**: `Python 3.12` (or latest)
   - **Architecture**: `x86_64`
   - **Permissions**: Select **Create a new role with basic Lambda permissions**.
3. **Copy Code**: Paste the contents of `lambda_orchestrator.py` into the `lambda_function.py` editor in the console.
4. **Deploy**: Click the **Deploy** button.

## 2. Configure Environment Variables
1. Go to the **Configuration** tab.
2. Select **Environment variables** in the left sidebar.
3. Click **Edit** and add:
   - `GEMINI_API_KEY`: <your-gemini-api-key>
4. Click **Save**.

## 3. Update IAM Permissions (Bedrock Access)
1. Go to the **Configuration** tab -> **Permissions**.
2. Click the link under **Role name** to open IAM.
3. In the IAM console, click **Add permissions** -> **Create inline policy**.
4. Use the **JSON** tab and paste:
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
5. Click **Next**, name it `BedrockInvokePolicy`, and click **Create policy**.

## 4. Set Up API Gateway (REST API)

1. **Navigate to API Gateway**: Search for and select **API Gateway**.
2. **Create API**: Under **REST API**, click **Build**.
3. **API Details**:
   - **Protocol**: `REST`
   - **API Name**: `BhashaLensAPI`
   - **Endpoint Type**: `Regional`
4. **Create Resources & Methods**:
   - Select the root `/` resource.
   - Click **Actions** -> **Create Resource**. Name it `orchestrate`.
   - Select `/orchestrate`. Click **Actions** -> **Create Method**. Select `POST`.
   - **Integration type**: `Lambda Function`.
   - **Lambda Proxy integration**: Check this box (CRITICAL).
   - **Lambda Function**: Select `BhashaLensOrchestrator`.
5. **Enable CORS**:
   - Select the `/orchestrate` resource.
   - Click **Actions** -> **Enable CORS**.
   - Use default settings (Allow all origins `*`) and click **Enable CORS and replace existing...**.

## 5. Deploy the API
1. Click **Actions** -> **Deploy API**.
2. **Deployment stage**: Select `[New Stage]`. Name it `prod`.
3. Click **Deploy**.
4. **Invoke URL**: Copy the URL displayed at the top (e.g., `https://abcde1234.execute-api.us-east-1.amazonaws.com/prod`).

## 6. Update Flutter App
1. Open your `bhashalens_app/.env` file.
2. Update the `AWS_API_GATEWAY_URL` with your **Invoke URL**.
3. Note: The app will append `/orchestrate` to the base URL automatically.

---
### Final Verification Checklist
- [ ] Bedrock Model Access granted in Model Catalog?
- [ ] Lambda region matches Bedrock region?
- [ ] `GEMINI_API_KEY` set in Lambda?
- [ ] API Gateway POST method uses **Lambda Proxy Integration**?
- [ ] CORS enabled on the API resource?

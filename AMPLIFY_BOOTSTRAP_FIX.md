# Fix: Create and Assign Amplify Service Role

Your Amplify build is failing because **no service role** is assigned to your app. Amplify needs this role to create your backend resources (Functions, Databases, etc.).

## Step 1: Create the IAM Role

1.  Open the [IAM Roles Console](https://console.aws.amazon.com/iam/home#/roles).
2.  Click **Create role**.
3.  **Trusted entity type**: Select **AWS service**.
4.  **Service or use case**: Select **Amplify**.
5.  **Use case**: Select **Amplify - Backend Deployment**.
6.  Click **Next**.
7.  **Add permissions**:
    - Search for and check: `AdministratorAccess-Amplify`
8.  Click **Next**.
9.  **Role name**: Enter `AmplifyConsoleServiceRole`.
10. Click **Create role**.

## Step 2: Add the CDK Bootstrap Permission (Crucial)

1.  Find your new `AmplifyConsoleServiceRole` in the role list and click on it.
2.  In the **Permissions** tab, click **Add permissions** -> **Create inline policy**.
3.  Click the **JSON** tab and paste this:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:us-east-1:*:parameter/cdk-bootstrap/*"
        }
    ]
}
```

4.  Click **Next**, name it `CDKBootstrapAccess`, and click **Create policy**.

## Step 3: Assign the Role to your Amplify App

1.  Go back to your [Amplify App Settings](https://us-east-1.console.aws.amazon.com/amplify/apps/d2inz5w2ysguf6/iam-roles/edit-service-role).
2.  Refresh the page.
3.  In the **Service role** dropdown (the one in your screenshot), you should now see `AmplifyConsoleServiceRole`. **Select it**.
4.  Click **Save**.

## Step 4: Redeploy

1.  Go to your branch (main) and click **Redeploy this version**.

---

### Why this works:
Amplify Gen 2 is "Infrastructure as Code". It needs high-level permissions to coordinate the creation of your Lambda functions and databases. By creating this role, you're giving the Amplify build engine the "keys" to set everything up for you.

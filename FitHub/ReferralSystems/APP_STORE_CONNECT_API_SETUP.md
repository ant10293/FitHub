# App Store Connect API Setup Guide

## Step 1: Create API Key in App Store Connect

1. **Go to App Store Connect**
   - Visit: https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Navigate to Users and Access**
   - Click on your name/profile in the top right
   - Select **Users and Access** from the dropdown

3. **Go to Integrations Tab**
   - Click on the **Integrations** tab
   - You'll see a section for **App Store Connect API**

4. **Generate API Key**
   - Click the **Generate API Key** button (or the **+** button)
   - Enter a name for your key (e.g., "FitHub Subscription Validation")
   - Select **App Manager** or **Admin** as the access level
     - **App Manager**: Can access app-specific data (recommended if you have multiple apps)
     - **Admin**: Full access (use if you only have one app or need full access)
   - Click **Generate**

5. **Download the Key**
   - **IMPORTANT**: You can only download the `.p8` file ONCE
   - Click **Download API Key** immediately
   - Save the `.p8` file securely (you'll need it for Firebase Functions)
   - Note the **Key ID** (shown on the same screen)
   - Note the **Issuer ID** (shown at the top of the Keys section)

## Step 2: Record Your Credentials

You'll need these three pieces of information:

1. **Key ID**: A 10-character string (e.g., `ABC123DEF4`)
2. **Issuer ID**: A UUID (e.g., `12345678-1234-1234-1234-123456789012`)
3. **Private Key**: The `.p8` file you downloaded

## Step 3: Store Credentials Securely

**DO NOT commit these to git!** We'll store them as Firebase Functions environment variables.

### For Firebase Functions (Next Step):

You'll run these commands (we'll set this up when we create the Cloud Functions):

```bash
firebase functions:config:set appstore.key_id="YOUR_KEY_ID"
firebase functions:config:set appstore.issuer_id="YOUR_ISSUER_ID"
firebase functions:config:set appstore.private_key="$(cat path/to/AuthKey_ABC123DEF4.p8)"
```

## What You Need to Provide:

Once you've completed these steps, you'll need to share:
- ✅ Key ID
- ✅ Issuer ID
- ✅ The `.p8` file content (or we can set it up together)

## Security Notes:

- The `.p8` file is like a password - keep it secure
- Never commit it to version control
- Store it in a secure location (password manager, secure file storage)
- You can revoke and regenerate keys if needed in App Store Connect

## Troubleshooting:

- **Can't find Integrations tab?**: Make sure you have Admin or Account Holder access
- **Key already generated?**: You can have multiple keys, or revoke old ones
- **Lost the .p8 file?**: You'll need to revoke and create a new key (you can't re-download it)

## Next Steps:

After you have these credentials, we'll:
1. Initialize Firebase Functions
2. Set up the environment variables
3. Create the webhook handler function

Let me know when you have the Key ID, Issuer ID, and the `.p8` file downloaded!


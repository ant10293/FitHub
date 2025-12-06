# Sandbox Testing Guide for Subscription Webhooks

## The Problem: StoreKit Testing vs Real Sandbox

**StoreKit Testing (Xcode's local testing):**
- Environment shows as "XCODE"
- ❌ Does NOT trigger App Store webhooks
- ❌ Cannot test cancellations via App Store Connect
- ✅ Good for quick local testing of purchase flow
- ✅ No need for test accounts

**Real Sandbox Testing:**
- Environment shows as "Sandbox"
- ✅ Triggers App Store webhooks
- ✅ Can test cancellations via App Store Connect
- ✅ True simulation of production behavior
- ⚠️ Requires real sandbox test accounts

## How to Set Up Real Sandbox Testing

### Step 1: Create Sandbox Test Accounts

1. Go to **App Store Connect** → **Users and Access** → **Sandbox Testers**
2. Click **+** to create a new tester
3. Fill in:
   - Email: Use a real email (e.g., `test1@example.com`)
   - Password: Create a password
   - First Name / Last Name: Any name
   - Country: Select your country
4. Save the tester

**Important:** Use a real email address. You'll need to verify it.

### Step 2: Choose Your Testing Method

**Option A: Use TestFlight (Recommended for Webhook Testing)**
- Upload your app to TestFlight
- TestFlight builds use real sandbox environment
- Products load from App Store Connect automatically
- Webhooks work correctly
- See "TestFlight Testing" section below

**Option B: Disable StoreKit Testing (Alternative - Products May Not Load)**
- In Xcode: **Product** → **Scheme** → **Edit Scheme**
- Go to **Run** → **Options**
- Under **StoreKit Configuration**, select **None**
- **Note:** Products may not load if your app isn't fully configured in App Store Connect

### Step 3: Sign Out of Apple ID on Your Device/Simulator

**On Physical Device:**
1. Go to **Settings** → **[Your Name]** at the top (not App Store)
2. Scroll down and tap **Sign Out**
3. This signs out of iCloud and App Store
4. When you make a purchase, iOS will prompt for Apple ID - use your sandbox test account

**Alternative (if you can't/don't want to sign out):**
- When you tap "Purchase" in your app, iOS will prompt for authentication
- Look for "Use Different Apple ID" option or sign in with sandbox account when prompted

**On Simulator:**
1. The simulator doesn't have a real Apple ID by default
2. When you run the app, it will prompt for Apple ID during purchase
3. Use your sandbox test account credentials

### Step 4: Build and Run Your App

1. Build and run your app normally
2. Navigate to the subscription screen
3. When you tap "Purchase", iOS will prompt you to sign in
4. **Sign in with your sandbox test account email and password**
5. Complete the purchase (it will be free in sandbox)

### Step 5: Verify Sandbox Environment

After purchase, check your Firestore:
- `users/{userId}/subscriptionStatus/environment` should be `"Sandbox"` (not `"XCODE"`)
- The webhook should be triggered (check Firebase Functions logs)

### Step 6: Test Subscription Cancellation

1. Go to **App Store Connect** → **Sales and Trends** → **TestFlight and Sandbox**
2. You should now see your test purchases here
3. Find the subscription you want to cancel
4. Click on it and look for cancellation options
5. Or wait for the subscription to expire naturally (sandbox subscriptions expire faster)

**Alternative:** You can also test cancellations by:
- Using the App Store Server API to check subscription status
- Waiting for sandbox subscriptions to expire (they have shorter durations)
- Using App Store Connect's subscription management for sandbox testers

## Monitoring Webhooks

### View Real-Time Logs

```bash
cd Firebase
firebase functions:log --only handleAppStoreNotification
```

### What to Look For

When a purchase is made with sandbox:
```
Received App Store notification: SUBSCRIBED
Detected SANDBOX environment
Processing notification for transaction: [ID] (SANDBOX)
Found user [userId] for transaction [ID]
Updated subscription status for user [userId]: active=true
```

When a subscription is cancelled:
```
Received App Store notification: DID_CANCEL
...
Updated subscription status for user [userId]: active=false
```

## Troubleshooting

### Still Seeing "XCODE" Environment?

- Make sure StoreKit Configuration is set to **None** in Xcode scheme
- Make sure you signed out of your real Apple ID
- Make sure you're signing in with a sandbox test account during purchase

### Webhooks Not Being Received?

- Verify the webhook URL is configured in App Store Connect (both Production and Sandbox)
- Check that the sandbox test account was used (not StoreKit Testing)
- Wait a few minutes - webhooks can have a delay
- Check Firebase Functions logs for errors

### Can't Find Test Purchases in App Store Connect?

- Make sure you're using **real sandbox test accounts** (not StoreKit Testing)
- Go to **Sales and Trends** → **TestFlight and Sandbox** (not main Sales)
- Wait a few minutes for purchases to appear
- Only purchases made with sandbox accounts appear here

## TestFlight Testing (Recommended)

TestFlight is the best way to test webhooks because:
- ✅ Products load automatically from App Store Connect
- ✅ Uses real sandbox environment (not "XCODE")
- ✅ Webhooks work correctly
- ✅ Can test cancellations in App Store Connect
- ✅ No need to disable StoreKit config

**Steps:**
1. Archive your app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Wait for processing (10-30 minutes)
4. Add yourself as an internal tester in TestFlight
5. Install the app from TestFlight
6. Make purchases with sandbox test account
7. Webhooks will work automatically!

## Development vs Testing

**For Development:**
- Keep StoreKit Configuration file active
- Products load locally
- Purchases show as "XCODE" environment
- Quick iteration and testing

**For Webhook Testing:**
- Use TestFlight builds
- Uses "Sandbox" environment
- Webhooks work correctly
- Can test full subscription lifecycle

## Summary

- **StoreKit Testing** = Quick local testing, no webhooks (keep for development)
- **TestFlight** = Full testing with webhooks, cancellations, etc. (use for webhook testing)
- **Real Sandbox** = Full testing with webhooks, cancellations, etc. (requires TestFlight or removing StoreKit config)

For testing subscription validation and webhooks, you **must** use TestFlight or remove StoreKit config (if products still load).

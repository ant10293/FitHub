# TestFlight Setup Guide

## Step 1: Add Yourself as an Internal Tester

1. Go to **App Store Connect** → **My Apps** → Select your app
2. Click on **TestFlight** tab (at the top)
3. Go to **Internal Testing** section (left sidebar)
4. Click **+** next to "Internal Testers" or click "Add Internal Testers"
5. Select yourself (or add your Apple ID email)
6. Click **Add**

## Step 2: Wait for Build Processing

1. In the **TestFlight** tab, go to **iOS Builds** section
2. You should see your uploaded build with status "Processing" or "Ready to Test"
3. Wait for it to finish processing (usually 10-30 minutes)
4. Once it says "Ready to Test", proceed to Step 3

## Step 3: Add Build to Internal Testing

1. Still in **TestFlight** tab, go to **Internal Testing** section
2. If you haven't created a test group yet, click **+** to create one
3. Name it "Internal Team" or similar
4. Click **Add Build** and select your processed build
5. Add test information (What to Test) if prompted
6. Click **Save**

## Step 4: Install TestFlight App

1. On your iPhone, go to the App Store
2. Search for "TestFlight" and install it (it's Apple's official app)

## Step 5: Accept Invite (if needed)

1. Check your email for a TestFlight invite
2. Or open the **TestFlight app** on your phone
3. You should see your app listed there
4. Tap **Accept** if prompted
5. Tap **Install** to install your app

## Step 6: Test with Sandbox Account

1. Sign out of your Apple ID (Settings → [Your Name] → Sign Out)
2. Open your app from TestFlight
3. Make a purchase
4. When prompted, sign in with your **sandbox test account**
5. Verify environment is "Sandbox" in Firestore

## Troubleshooting

### "No builds available"
- Make sure the build finished processing (check App Store Connect)
- Make sure you added the build to an internal testing group
- Make sure you're added as an internal tester

### "Need an invite code"
- You don't need an invite code for internal testing
- Make sure you're added as an internal tester in App Store Connect
- Try refreshing the TestFlight app
- Check that the build is assigned to an internal testing group

### Build stuck on "Processing"
- This is normal, wait 10-30 minutes
- Check for any errors in App Store Connect
- Sometimes builds can take up to an hour

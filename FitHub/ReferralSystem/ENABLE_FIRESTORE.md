# How to Enable Firestore in Firebase Console

If you don't see "Firestore Database" in your Firebase Console, you need to enable it first. Here's how:

## Step 1: Navigate to Firebase Console

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Select your project (FitHub)

## Step 2: Enable Firestore Database

### Option A: If you see "Build" in the left sidebar
1. Click **"Build"** in the left sidebar
2. You should see several options including:
   - Authentication
   - Firestore Database
   - Storage
   - Functions
   - etc.
3. Click **"Firestore Database"**
4. Click **"Create database"** button

### Option B: If you see "Firestore Database" but it's grayed out
1. Click on **"Firestore Database"** in the left sidebar
2. You'll see a screen prompting you to create a database
3. Click **"Create database"**

### Option C: If you don't see Firestore at all
1. Look for **"Build"** or **"Database"** in the left sidebar
2. If you see "Realtime Database" but not "Firestore Database", that's different - you need Firestore
3. Try clicking on any existing service (like Authentication) and look for Firestore in the submenu

## Step 3: Choose Database Mode

When you click "Create database", you'll be asked to choose:

1. **Start in production mode** (Recommended for now)
   - You can change rules later
   - Click **"Next"**

2. **Choose a location**
   - **For global apps:** Pick your primary market or where you're based
   - **Common choices:** `us-central1` or `us-east1` are safe defaults for most apps
   - **Why it matters:** 
     - The region affects where your data is primarily stored (for compliance/data residency)
     - Write operations have slightly lower latency to the primary region
     - **Reads are optimized globally** - Firebase handles this well for worldwide users
   - **For referral codes:** This is mostly read-heavy, so region choice has minimal impact
   - ⚠️ **Important:** This cannot be changed later, so pick one and stick with it
   - Click **"Enable"**

## Step 4: Wait for Provisioning

Firebase will take about 30-60 seconds to create your Firestore database. You'll see a loading screen.

## Step 5: Access Firestore

Once enabled, you should see:
- **"Firestore Database"** in the left sidebar
- A button to **"Start collection"** or **"Add collection"**
- An empty database view

## Alternative: Direct URL

You can also try accessing Firestore directly:
- Go to: `https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore`

Replace `YOUR_PROJECT_ID` with your actual Firebase project ID (you can find it in your `GoogleService-Info.plist` file).

## Troubleshooting

### "Firestore not available in your region"
- Some regions may not support Firestore
- Try selecting a different region (us-central, us-east1, europe-west1, etc.)

### "You need to upgrade your plan"
- Firestore requires a Blaze (pay-as-you-go) plan
- However, Firestore has a generous free tier (1 GB storage, 50K reads/day, 20K writes/day)
- You can upgrade to Blaze and still stay within free tier limits
- Go to: Firebase Console → Project Settings → Usage and billing

### "Cannot find Build section"
- Make sure you're logged into the correct Google account
- Make sure you're viewing the correct Firebase project
- Try refreshing the page

## After Firestore is Enabled

Once you can see Firestore Database in the sidebar:

1. Click on **"Firestore Database"**
2. You'll see an empty database with a message "No collections yet"
3. Click **"Start collection"** or **"Add collection"**
4. Collection ID: `referralCodes`
5. Click **"Next"**
6. Add your first document (see QUICK_START.md for field details)

## Quick Check

After enabling, you should see:
- ✅ "Firestore Database" in the left sidebar
- ✅ A button to create collections
- ✅ An empty database view
- ✅ A "Rules" tab at the top
- ✅ A "Indexes" tab at the top

If you still can't find it, take a screenshot of your Firebase Console sidebar and I can help guide you further!


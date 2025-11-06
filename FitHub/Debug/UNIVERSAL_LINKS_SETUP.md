# Universal Links Setup Guide

This guide will help you set up Firebase Hosting so that your referral links work properly.

## Step 1: Install Firebase CLI

If you don't have Firebase CLI installed:

```bash
npm install -g firebase-tools
```

Or using Homebrew on macOS:
```bash
brew install firebase-cli
```

## Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to authenticate with your Google account.

## Step 3: Initialize Firebase Hosting

Navigate to your project directory and run:

```bash
cd /Users/anthonycantu/Desktop/iOS/FitHub/FitHub
firebase init hosting
```

When prompted:
1. **Select your Firebase project**: Choose `fithubv1-d3c91` (or your project)
2. **Public directory**: Enter `public` (this is already created)
3. **Single-page app**: Yes (we want all routes to redirect to index.html)
4. **Overwrite index.html**: No (we already created it)

## Step 4: Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

This will deploy your site to `https://fithub.web.app`

## Step 5: Verify Universal Links

### Test the apple-app-site-association file:
Visit: `https://fithub.web.app/.well-known/apple-app-site-association`

You should see JSON with your app configuration. The file must:
- Be served over HTTPS
- Have `Content-Type: application/json` header
- Be accessible without redirects

### Test a referral link:
Visit: `https://fithub.web.app/r/ANTHONY`

This should:
- Show your landing page
- If the app is installed, it should try to open the app
- The referral code will be stored in localStorage

## Step 6: Test in Your App

1. **On a device with your app installed:**
   - Open Safari
   - Navigate to `https://fithub.web.app/r/ANTHONY`
   - It should open your app directly
   - The referral code should be captured

2. **On a device without the app:**
   - Open Safari
   - Navigate to `https://fithub.web.app/r/ANTHONY`
   - You'll see the landing page
   - When the app is installed later, the code in localStorage can be used

## Troubleshooting

### Universal Links Not Working?

1. **Check apple-app-site-association file:**
   ```bash
   curl https://fithub.web.app/.well-known/apple-app-site-association
   ```
   Should return JSON, not HTML.

2. **Verify app ID format:**
   - Format: `{TEAM_ID}.{BUNDLE_ID}`
   - Team ID: `560218307632` (from GoogleService-Info.plist)
   - Bundle ID: `com.AnthonyC.FitHub`
   - Full: `560218307632.com.AnthonyC.FitHub`

3. **Check entitlements:**
   - Make sure `FitHub.entitlements` has:
   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
       <string>FitHub.web.app</string>
   </array>
   ```

4. **Universal Links require HTTPS:**
   - Firebase Hosting provides HTTPS automatically
   - Make sure you're using `https://` not `http://`

5. **Clear app's universal link cache:**
   - Delete and reinstall the app
   - Or wait ~24 hours for cache to expire

### App Store ID Not Set?

Once your app is on the App Store:
1. Get your App Store ID from App Store Connect
2. Update `public/index.html`:
   - Find `[YOUR_APP_STORE_ID]`
   - Replace with your actual ID
   - Redeploy: `firebase deploy --only hosting`

## File Structure

After setup, you should have:
```
FitHub/
├── firebase.json          # Firebase configuration
├── public/
│   ├── index.html        # Landing page
│   └── .well-known/
│       └── apple-app-site-association  # Universal link config
```

## Next Steps

1. ✅ Deploy hosting (done above)
2. ✅ Test universal links on device
3. ⏳ Submit app to App Store
4. ⏳ Update App Store ID in index.html
5. ⏳ Redeploy hosting with App Store ID

## Testing Without App Store

You can test the universal links even before your app is on the App Store:

1. Build and install the app on a device via Xcode
2. Make sure the device is connected to the internet
3. Open Safari and navigate to `https://fithub.web.app/r/ANTHONY`
4. The app should open automatically (if installed)
5. The referral code will be captured and stored

## Additional Resources

- [Apple Universal Links Documentation](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)


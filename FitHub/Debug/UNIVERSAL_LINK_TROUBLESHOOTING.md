# Universal Link Troubleshooting

If universal links were working but suddenly stopped, try these fixes in order:

## Quick Fixes (Try These First)

### 1. **Delete and Reinstall the App** ⭐ Most Common Fix
iOS caches the `apple-app-site-association` file validation. When you make changes:
1. Delete the app from your device completely
2. Rebuild and reinstall from Xcode
3. Try the link again

### 2. **Restart Your Device**
Sometimes iOS needs a fresh start to revalidate universal links.

### 3. **Verify Entitlements Are Still Included**
1. In Xcode, select your project
2. Select the "FitHub" target
3. Go to "Signing & Capabilities" tab
4. Make sure "Associated Domains" capability is still there
5. Verify it shows: `applinks:fithubv1-d3c91.web.app`

### 4. **Clean Build Folder**
1. In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
2. Rebuild the app
3. Reinstall on device

### 5. **Check Bundle Identifier Matches**
Verify the bundle ID in Xcode matches what's in the association file:
- Association file has: `L26773524X.com.AnthonyC.FitHub`
- Your bundle ID should be: `com.AnthonyC.FitHub`
- Your Team ID should be: `L26773524X`

## Advanced Troubleshooting

### Check if Association File is Accessible
```bash
curl https://fithubv1-d3c91.web.app/.well-known/apple-app-site-association
```

Should return JSON (not HTML). If it returns HTML, the file isn't being served correctly.

### Verify App ID Format
The association file should have:
```json
{
  "applinks": {
    "details": [{
      "appID": "L26773524X.com.AnthonyC.FitHub",
      "paths": ["/r/*", "/*?ref=*"]
    }]
  }
}
```

### Test in Safari First
1. Open Safari on your device
2. Type the URL directly: `https://fithubv1-d3c91.web.app/r/TESTCODE`
3. Long-press the link (if on a page) or tap it
4. You should see "Open in FitHub" option
5. If you don't see this, universal links aren't working

### Check Xcode Console
When you click a link, check Xcode console for:
- `✅ Successfully handled referral URL` - means URL handler worked
- If you see this but app didn't open, it's an iOS universal link issue

## If Still Not Working

### Force iOS to Revalidate
1. Wait 24 hours (iOS caches association files)
2. Or try a different device
3. Or use a different Apple ID for testing

### Verify Your Change Didn't Break Something
Common things that break universal links:
- Changing bundle identifier
- Changing Team ID
- Removing Associated Domains capability
- Changing signing certificate
- Changing the app's URL scheme handlers

## Testing Alternative: Use URL Scheme

If universal links are problematic, you can temporarily test with URL schemes:
- Format: `fithub://r/TESTCODE`
- Add URL scheme in Info.plist if needed

But universal links are preferred for production.

## Quick Verification Checklist

- [ ] App is installed on device
- [ ] Associated Domains capability is present
- [ ] Domain matches: `applinks:fithubv1-d3c91.web.app`
- [ ] Bundle ID matches: `com.AnthonyC.FitHub`
- [ ] Team ID matches: `L26773524X`
- [ ] Association file is accessible via HTTPS
- [ ] Association file returns JSON (not HTML)
- [ ] App was deleted and reinstalled after changes
- [ ] Device was restarted


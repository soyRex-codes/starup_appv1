# 🎯 UPDATE REQUIRED: App Store & Play Store Links

## Your App Store URLs Need to be Updated

After your apps are approved and live on the stores, update these links:

### In `web_landing_page/privacy.html` (Line ~180):
```html
<!-- CURRENT (placeholder) -->
<a href="https://apps.apple.com/app/foundervers/id6738901234" class="app-button" target="_blank">

<!-- UPDATE TO YOUR REAL APP STORE ID -->
<a href="https://apps.apple.com/app/foundervers/id[YOUR_REAL_APP_ID]" class="app-button" target="_blank">
```

### In `web_landing_page/terms.html` (Line ~180):
```html
<!-- CURRENT (placeholder) -->
<a href="https://apps.apple.com/app/foundervers/id6738901234" class="app-button" target="_blank">

<!-- UPDATE TO YOUR REAL APP STORE ID -->
<a href="https://apps.apple.com/app/foundervers/id[YOUR_REAL_APP_ID]" class="app-button" target="_blank">
```

## How to Find Your App IDs

### iPhone App Store
1. Go to https://appstoreconnect.apple.com
2. Login with your Apple Developer account
3. Select your app "FounderVers"
4. Look for "App ID" in the General tab
5. Format: `https://apps.apple.com/app/foundervers/id1234567890`

### Android Google Play
1. Go to https://play.google.com/console
2. Select "FounderVers" app
3. Copy the package name from dashboard
4. Format: `https://play.google.com/store/apps/details?id=com.foundervers.mobile`

## Quick Update Commands

Once you have your real IDs, use this to update both files:

```bash
# For iOS App Store ID
sed -i '' 's/id6738901234/id[YOUR_REAL_ID]/g' web_landing_page/privacy.html web_landing_page/terms.html
```

## File References

### Privacy Policy Page
- Location: `web_landing_page/privacy.html`
- Status: ✅ Ready (uses placeholder IDs)
- Download buttons: Lines 166-175

### Terms of Service Page
- Location: `web_landing_page/terms.html`
- Status: ✅ Ready (uses placeholder IDs)
- Download buttons: Lines 192-201

## Current Placeholder IDs

- **iPhone**: `https://apps.apple.com/app/foundervers/id6738901234`
- **Android**: `https://play.google.com/store/apps/details?id=com.foundervers.mobile`

⚠️ **IMPORTANT**: These are placeholder IDs. Update them once your apps are live!

## After Apps Go Live

1. ✅ App is approved on App Store
2. Get your real App ID
3. Update `privacy.html` line 171
4. Update `privacy.html` line 175
5. Update `terms.html` line 196
6. Update `terms.html` line 200
7. Deploy website
8. Test both links work

---

**Remember:** Your Android package ID `com.foundervers.mobile` should be the same across all documentation. This is correct! ✓

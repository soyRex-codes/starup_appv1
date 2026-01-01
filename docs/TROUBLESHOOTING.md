# Troubleshooting Guide

## Common Issues

### 1. Brute Force Protection / Rate Limits
**Issue:** "Too many requests" or "429" error on login.
**Cause:** Supabase rate limits (default 30 attempts / 5 mins).
**Fix:** 
- Wait for the cooldown (shown in error message).
- For app admins: Check "Authentication > Rate Limits" in Supabase to adjust if needed (not recommended to disable).

### 2. Profile Picture Not Updating
**Issue:** New avatar not showing after upload.
**Cause:** Caching or `null` overwrite bug (Fixed Dec 2025).
**Fix:**
- App uses `TimeFormatter` to bust cache on new uploads.
- Ensure `UserService.upsertUser` is not called with null `avatar_url`.

### 3. Deep Links Opening in Browser 404
**Issue:** Links like `foundervers.com/posts/...` go to 404 page instead of app.
**Fix:**
- Ensure `.well-known/apple-app-site-association` is valid json on main website.
- Ensure `flutter_deep_linking_enabled` is OFF in Info.plist if using `app_links` package.

### 4. Cold Start Slow
**Issue:** White screen for 5+ seconds on startup.
**Fix:**
- App now uses `Lazy` loading for Stripe and heavy services.
- `AuthGate` initializes critical paths first.

## Debugging Tools

- **Log Stream:** Run `flutter run -v` to see full verbose logs.
- **Deep Link Test:** 
  ```bash
  xcrun simctl openurl booted "https://foundervers.com/posts/123"
  ```

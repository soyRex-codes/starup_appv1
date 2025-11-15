# FounderVers - App Store Deployment Guide

## 🎯 Pre-Deployment Checklist

### ✅ Completed Items
- [x] **Bundle Identifier**: Updated from `com.example.starupAppv1` to `com.foundervers.mobile`
- [x] **iOS Permissions**: Added NSPhotoLibraryUsageDescription, NSCameraUsageDescription, NSMicrophoneUsageDescription
- [x] **Environment Variables**: Created .env.production and .env.example templates
- [x] **Security**: Added .env files to .gitignore to prevent secret leakage
- [x] **Version Numbers**: Currently at 1.0.0+1 (ready for initial release)

### 📋 Remaining Actions Required

#### 1. Update Stripe Keys for Production
**CRITICAL - Must do before App Store submission:**
```bash
# Edit .env.production and replace test key with LIVE key
STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_ACTUAL_LIVE_KEY
```
Get your live key from: https://dashboard.stripe.com/apikeys

#### 2. Code Signing & Provisioning Profile
**Required in Xcode:**
- Team ID is set to: `XF5WDB46P4`
- Bundle ID: `com.foundervers.mobile`
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner target → Signing & Capabilities
- Ensure "Automatically manage signing" is enabled
- Select your Apple Developer team
- Verify provisioning profile is valid

#### 3. App Store Connect Setup
1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: FounderVers
   - **Primary Language**: English
   - **Bundle ID**: com.foundervers.mobile
   - **SKU**: foundervers-mobile-001
   - **User Access**: Full Access

#### 4. App Metadata Required
Prepare the following information:

**App Information:**
- **Name**: FounderVers
- **Subtitle**: Connect. Build. Succeed.
- **Category**: Social Networking / Business
- **Age Rating**: 17+ (due to user-generated content)

**App Description:**
```
FounderVers is the premier social platform connecting founders, entrepreneurs, and startup enthusiasts worldwide. 

KEY FEATURES:
• Real-time messaging and networking
• Media sharing (photos, videos, documents)
• Premium content and exclusive features
• Advanced search and discovery
• Secure payments via Stripe
• AI-powered content moderation

Whether you're launching your first startup or you're a seasoned entrepreneur, FounderVers helps you:
- Connect with like-minded founders
- Share your journey and insights
- Discover opportunities and partnerships
- Build your entrepreneurial network

Join thousands of founders building the future together.
```

**Keywords (max 100 characters):**
```
startup,entrepreneur,founder,business,networking,social,venture,innovation
```

**Support URL**: https://foundervers.com/support
**Marketing URL**: https://foundervers.com
**Privacy Policy URL**: https://foundervers.com/privacy (REQUIRED)

#### 5. Privacy Policy (REQUIRED)
You MUST have a publicly accessible privacy policy that covers:
- Data collection (user profiles, posts, messages)
- Third-party services (Supabase, Stripe, OpenAI, Hive AI)
- Photo/Camera access usage
- Data retention and deletion
- User rights under GDPR/CCPA

#### 6. App Screenshots Required
**iPhone 6.7" Display (Required):**
- 1290 x 2796 pixels
- Minimum 2 screenshots, maximum 10

**iPhone 6.5" Display:**
- 1242 x 2688 pixels

**Recommended screenshots to include:**
1. Feed/Home screen showing posts
2. Profile page
3. Messaging interface
4. Post creation
5. Premium features

#### 7. App Icon Checklist
- [x] Icon configured in `pubspec.yaml` via flutter_launcher_icons
- [x] Source image: `lib/icons/foundervers.png`
- [ ] Verify icon appears correctly in iOS simulator
- [ ] Icon must be 1024x1024 PNG (no transparency) for App Store

#### 8. Build & Test
```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Generate launcher icons
flutter pub run flutter_launcher_icons

# 4. Build iOS release
flutter build ios --release

# 5. Test on physical device
# Open Xcode → Product → Destination → Your iPhone
# Product → Run (⌘R)
```

#### 9. Create Archive for Submission
**In Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select "Any iOS Device (arm64)" as destination
3. Product → Archive (⌘B + Shift)
4. Wait for archive to complete
5. Window → Organizer
6. Select your archive → "Distribute App"
7. Choose "App Store Connect"
8. Upload → Wait for processing (can take 15-30 minutes)

#### 10. Submit for Review
**In App Store Connect:**
1. Go to your app
2. Click on version "1.0"
3. Upload screenshots
4. Fill in "What's New" (for updates) or description (first release)
5. Add build from Xcode upload
6. Fill out Content Rights
7. Fill out Advertising Identifier usage (select NO if not using ads)
8. Fill out Export Compliance (usually NO for most apps)
9. Click "Add for Review"
10. Submit for Review

## 🔍 Pre-Submission Verification

### Test These Critical Flows:
- [ ] Sign up with email
- [ ] Email verification
- [ ] Login/Logout
- [ ] Create post with photo
- [ ] Create post with video
- [ ] Comment on post
- [ ] Like/Unlike posts
- [ ] Profile editing with photo upload
- [ ] Messaging (send/receive)
- [ ] Deep links work
- [ ] Stripe payment flow (use test mode first!)
- [ ] Search functionality
- [ ] Bookmarks
- [ ] Premium features

### App Review Guidelines Compliance
- [ ] No placeholder content
- [ ] No "test" or "demo" accounts required
- [ ] Privacy policy accessible
- [ ] All features functional
- [ ] No crashes or major bugs
- [ ] Follows Human Interface Guidelines
- [ ] Handles network errors gracefully
- [ ] Respects user privacy

## 📊 Expected Timeline

| Phase | Duration |
|-------|----------|
| Final testing & fixes | 1-2 days |
| Archive & upload | 1-2 hours |
| App Store processing | 15-60 minutes |
| App Review wait time | 1-3 days |
| Review process | 24-48 hours |
| **Total estimated time** | **3-7 days** |

## ⚠️ Common Rejection Reasons to Avoid

1. **Missing Privacy Policy** - You MUST have one
2. **Incomplete Account Setup** - App must be fully functional
3. **Stripe Test Mode** - Use LIVE keys for production
4. **Crashes** - Test thoroughly on real devices
5. **Incomplete Metadata** - Fill ALL required fields
6. **Placeholder Content** - Remove any "Lorem ipsum" or test data
7. **Missing Permissions Explanations** - Already added to Info.plist ✓

## 🆘 Troubleshooting

### Build Fails
```bash
# Clean and retry
flutter clean
cd ios && pod deintegrate && pod install
cd .. && flutter pub get
flutter build ios --release
```

### Code Signing Issues
- Verify Apple Developer account is active
- Check certificates in Xcode → Preferences → Accounts
- Ensure Bundle ID matches App Store Connect

### Upload Issues
- Check Xcode → Window → Organizer for error details
- Verify app version and build number are incremented
- Check Application Loader for detailed error logs

## 📞 Support Resources

- **Apple Developer Support**: https://developer.apple.com/support/
- **App Store Connect**: https://appstoreconnect.apple.com
- **Flutter iOS Deployment**: https://docs.flutter.dev/deployment/ios
- **App Review Status**: Check in App Store Connect

## 🎉 After Approval

1. App goes live automatically or manually (your choice in settings)
2. Monitor crash reports in App Store Connect
3. Respond to user reviews
4. Plan update schedule
5. Track analytics and metrics

---

**Current Status**: Ready for final testing and Stripe key update
**Next Step**: Update production Stripe keys and create App Store Connect app record
**Bundle ID**: com.foundervers.mobile
**Version**: 1.0.0 (Build 1)

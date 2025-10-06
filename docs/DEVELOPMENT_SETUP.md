# Development Setup Guide - FounderVers Mobile

## 🎯 Prerequisites & System Requirements

### Minimum Requirements
- **Flutter SDK**: 3.35.0+ (latest stable)  
- **Dart SDK**: 3.9+ (bundled with Flutter)
- **Operating System**: macOS 12.0+, Windows 10+, or Ubuntu 20.04+
- **RAM**: 8GB minimum, 16GB+ recommended for optimal performance
- **Storage**: 50GB+ free space (includes Xcode, Android Studio, emulators)
- **Internet**: Stable connection for Supabase, package downloads

### Required Software Stack

#### 1. Flutter SDK (3.35.0+)
```bash
# Install Flutter via official installer or Homebrew (macOS)
brew install --cask flutter

# Verify installation
flutter --version
# Expected: Flutter 3.35.0 • channel stable
# Dart 3.4.0 • DevTools 2.33.2

# Check system compatibility
flutter doctor -v
```

#### 2. Development Environment
**Recommended: Visual Studio Code with Flutter Extensions**
```bash
# Install VS Code
brew install --cask visual-studio-code

# Essential extensions
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
code --install-extension ms-vscode.vscode-json
```

**VS Code Settings for Flutter Development:**
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.openDevTools": "flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false
}
```

**Alternative: Android Studio**
```bash
# Download from https://developer.android.com/studio
# Required plugins: Flutter, Dart
```

#### 3. Platform-Specific Tools

**For iOS Development (macOS only)**:
```bash
# Install Xcode 15.0+ from App Store
xcode-select --install

# Install CocoaPods for dependency management
sudo gem install cocoapods

# Verify iOS setup
flutter doctor --ios
```

#### 4. Supabase CLI (for database operations)
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Verify installation
supabase --version
```

#### 5. Version Control
```bash
# Git is usually pre-installed on macOS/Linux
git --version

# Configure Git if not already done
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
```

## 🚀 Project Setup

### Repository Configuration
**Repository URL**: `https://github.com/soyRex-codes/mobile_app_foundervers.git`  
**Project Directory**: `mobile_app_foundervers`  
**Main Branch**: `main`

### 1. Clone the Repository
```bash
# Clone the project
git clone https://github.com/soyRex-codes/mobile_app_foundervers.git
cd mobile_app_foundervers

# Verify project structure
ls -la
# Should see: lib/, android/, ios/, pubspec.yaml, README.md
```

### 2. Install Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# Clean build if needed
flutter clean && flutter pub get

# Verify dependencies are installed
flutter pub deps
```

### 3. Supabase Backend Configuration

#### Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and create account
2. Create new project with these settings:
   - **Region**: Choose closest to your users
   - **Database Password**: Strong password (save securely)
   - **Tier**: Free tier for development

#### Configure Environment Variables
Create `.env` file in project root:
```bash
# .env (DO NOT commit to git)
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

Add to `.gitignore`:
```gitignore
.env
.env.local
.env.*.local
```

#### Apply Database Schema
```bash
# Make scripts executable
chmod +x scripts/apply_schema.sh
chmod +x scripts/migrate_db.sh

# Apply the complete 540-line database schema
./scripts/apply_schema.sh

# Verify tables were created
supabase db reset
```

### 4. Configure Authentication

#### Enable Email Auth in Supabase Dashboard:
1. Go to Authentication → Settings
2. Enable **Email** provider
3. Configure **Email Templates**:
   - Confirm signup template
   - Reset password template (for OTP system)
4. Set **Site URL**: `https://yourdomain.com` (for production)
5. **Redirect URLs**: Add your app's custom scheme

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/soyRex-codes/mobile_app_foundervers.git
cd mobile_app_foundervers

# Install dependencies
flutter pub get
```

### 2. Environment Configuration

#### Create Environment File
```bash
# Copy example environment file
cp .env.mobile.example .env.mobile
```

#### Configure .env.mobile
```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Admin Configuration
ADMIN_EMAILS=admin1@example.com,admin2@example.com

# Storage Buckets
STARTUPBUILDER_BUCKET=startupbuilder
APPLICATIONS_BUCKET=applications

# Debug Settings (Development only)
DEBUG_MODE=true
ENABLE_LOGGING=true
```

### 3. Firebase Setup

#### iOS Configuration
1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create new project or use existing
   - Add iOS app with bundle ID: `com.example.mobile_foundervers`

2. **Download Config File**:
   ```bash
   # Download GoogleService-Info.plist from Firebase Console
   # Place it at: ios/Runner/GoogleService-Info.plist
   ```

3. **Configure Xcode Project**:
   ```bash
   cd ios
   open Runner.xcworkspace
   # Add GoogleService-Info.plist to Runner target
   # Verify bundle identifier matches Firebase config
   ```

#### Android Configuration
1. **Add Android App to Firebase Project**:
   - Package name: `com.example.mobile_foundervers`
   - SHA-1 certificate fingerprint (for release builds)

2. **Download Config File**:
   ```bash
   # Download google-services.json from Firebase Console
   # Place it at: android/app/google-services.json
   ```

3. **Verify Gradle Configuration**:
   ```gradle
   // android/build.gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }

   // android/app/build.gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### 4. Supabase Setup

#### Create Supabase Project
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create new project
3. Note down project URL and anon key

#### Database Schema Setup
```bash
# Apply database schema
psql -h db.your-project-id.supabase.co -p 5432 -U postgres -d postgres -f main_mobile_app_database_schema.sql

# Or use Supabase Dashboard SQL Editor
# Copy contents of main_mobile_app_database_schema.sql
```

#### Configure Storage
1. **Create Storage Buckets**:
   ```sql
   -- Run in Supabase SQL Editor
   INSERT INTO storage.buckets (id, name, public) 
   VALUES ('startupbuilder', 'startupbuilder', true);
   
   INSERT INTO storage.buckets (id, name, public) 
   VALUES ('applications', 'applications', false);
   ```

2. **Set Storage Policies**:
   ```sql
   -- Allow authenticated users to upload files
   CREATE POLICY "Allow authenticated uploads" ON storage.objects
   FOR INSERT WITH CHECK (auth.role() = 'authenticated');
   
   -- Allow public read access to startupbuilder bucket
   CREATE POLICY "Public read access" ON storage.objects
   FOR SELECT USING (bucket_id = 'startupbuilder');
   ```

### 5. IDE Configuration

#### VS Code Settings
Create `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 100,
  "editor.rulers": [100],
  "editor.formatOnSave": true,
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false,
  "files.associations": {
    "*.dart": "dart"
  },
  "dart.openDevTools": "flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true
}
```

#### Launch Configuration
Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch (Development)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["--flavor", "development", "--dart-define", "ENVIRONMENT=development"]
    },
    {
      "name": "Launch (Profile Mode)",
      "request": "launch", 
      "type": "dart",
      "flutterMode": "profile",
      "program": "lib/main.dart"
    },
    {
      "name": "Launch (Release Mode)",
      "request": "launch",
      "type": "dart", 
      "flutterMode": "release",
      "program": "lib/main.dart"
    }
  ]
}
```

## 🔨 Development Workflow

### 1. Daily Development Setup

```bash
# Navigate to project directory
cd /path/to/mobile_app_foundervers

# Get latest changes
git pull origin main

# Update dependencies
flutter pub get

# Clean build (if needed)
flutter clean
flutter pub get

# Run the app
flutter run
```

### 2. Device/Emulator Setup

#### iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Run app on iOS
flutter run -d "iPhone 15 Pro"
```

#### Android Emulator
```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_7_Pro_API_33

# Run app on Android
flutter run -d emulator-5554
```

#### Physical Device (iOS)
1. **Enable Developer Mode**:
   - Connect iPhone via USB
   - Trust computer when prompted
   - Enable Developer Mode in Settings

2. **Run on Device**:
   ```bash
   # List connected devices
   flutter devices
   
   # Run on specific device
   flutter run -d "Rajkumar's iPhone"
   ```

#### Physical Device (Android)
1. **Enable Developer Options**:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Enable "USB Debugging" in Developer Options

2. **Run on Device**:
   ```bash
   # Verify device is connected
   adb devices
   
   # Run on device
   flutter run -d android_device_id
   ```

### 3. Hot Reload & Debugging

#### Hot Reload
- **Hot Reload**: Press `r` in terminal or Ctrl+S in VS Code
- **Hot Restart**: Press `R` in terminal or Ctrl+Shift+F5 in VS Code

#### Debugging Tools
```bash
# Enable Flutter Inspector
flutter run --debug

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Performance Profiling
flutter run --profile
```

## 🧪 Testing Setup

### 1. Unit Test Configuration

#### Test Dependencies
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

#### Generate Mocks
```bash
# Generate mock classes
flutter packages pub run build_runner build
```

#### Run Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/post_service_test.dart

# Run tests with coverage
flutter test --coverage
```

### 2. Integration Test Setup

#### Add Integration Test Dependencies
```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

#### Create Test Directory
```bash
mkdir integration_test
```

#### Run Integration Tests
```bash
# Run integration tests
flutter test integration_test/
```

### 3. Widget Test Setup

#### Example Widget Test
```dart
// test/widgets/post_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:founderVers/features/feed/widgets/post_card.dart';
import 'package:founderVers/models/post_model.dart';

void main() {
  testWidgets('PostCard displays post information', (tester) async {
    final post = PostModel(
      id: 1,
      title: 'Test Post',
      description: 'Test Description',
      userId: 'user123',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(post: post),
        ),
      ),
    );

    expect(find.text('Test Post'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });
}
```

## 🐛 Debugging Setup

### 1. Logging Configuration

#### Enable Debug Logging
```dart
// lib/core/utils/logger.dart
import 'dart:developer' as developer;

class Logger {
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'Debug');
    }
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'Error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
```

#### Use Logging in Code
```dart
import 'package:founderVers/core/utils/logger.dart';

class PostService {
  Future<List<PostModel>> getPosts() async {
    Logger.debug('Fetching posts from API');
    
    try {
      final response = await _supabase.from('posts').select();
      Logger.debug('Fetched ${response.length} posts');
      return response.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Failed to fetch posts', e);
      rethrow;
    }
  }
}
```

### 2. Breakpoint Debugging

#### VS Code Debugging
1. Set breakpoints by clicking on line numbers
2. Press F5 or use Debug → Start Debugging
3. Use debug console for variable inspection

#### Flutter Inspector
1. Open Flutter Inspector in VS Code
2. Inspect widget tree in real-time
3. Modify properties during debugging

### 3. Network Debugging

#### Enable Network Logging
```dart
// lib/core/interceptors/logging_interceptor.dart
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST: ${options.method} ${options.path}');
    print('HEADERS: ${options.headers}');
    print('DATA: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE: ${response.statusCode}');
    print('DATA: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    print('ERROR: ${err.message}');
    handler.next(err);
  }
}
```

## 📱 Platform-Specific Setup

### iOS Development

#### Xcode Configuration
```bash
# Open project in Xcode
cd ios
open Runner.xcworkspace
```

#### Common iOS Issues
1. **Pod Installation Issues**:
   ```bash
   cd ios
   rm Podfile.lock
   rm -rf Pods
   pod install --repo-update
   ```

2. **Signing Issues**:
   - Open Xcode → Select Runner → Signing & Capabilities
   - Select development team
   - Ensure bundle identifier is unique

3. **Build Issues**:
   ```bash
   # Clean iOS build
   flutter clean
   cd ios
   rm -rf build
   cd ..
   flutter pub get
   ```

#### iOS Simulator Management
```bash
# List all simulators
xcrun simctl list devices

# Create new simulator
xcrun simctl create "iPhone 15 Pro Test" com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro com.apple.CoreSimulator.SimRuntime.iOS-17-0

# Delete simulator
xcrun simctl delete "iPhone 15 Pro Test"
```

### Android Development

#### Android Studio Setup
1. **Install Android Studio**
2. **Configure SDK**:
   - Tools → SDK Manager
   - Install Android SDK 33+ 
   - Install Android SDK Build-Tools
   - Install Android Emulator

3. **Create AVD**:
   - Tools → AVD Manager
   - Create Virtual Device
   - Select Pixel 7 Pro API 33

#### Common Android Issues
1. **Gradle Issues**:
   ```bash
   cd android
   ./gradlew clean
   ./gradlew build
   ```

2. **SDK License Issues**:
   ```bash
   flutter doctor --android-licenses
   ```

3. **Emulator Issues**:
   ```bash
   # Kill all emulator processes
   adb kill-server
   adb start-server
   
   # Wipe emulator data
   emulator -avd Pixel_7_Pro_API_33 -wipe-data
   ```

## ⚡ Performance Setup

### 1. Build Optimization

#### Release Build Configuration
```bash
# Android release build
flutter build apk --release --shrink

# iOS release build  
flutter build ios --release
```

#### Profile Mode
```bash
# Run in profile mode for performance testing
flutter run --profile
```

### 2. Memory Profiling

#### Enable Memory Tracking
```dart
// lib/main.dart
void main() {
  if (kDebugMode) {
    // Enable memory tracking
    debugProfileBuildsEnabled = true;
  }
  runApp(MyApp());
}
```

#### Monitor Memory Usage
```bash
# Use DevTools for memory profiling
flutter pub global activate devtools
flutter pub global run devtools
```

### 3. Network Optimization

#### Configure HTTP Client
```dart
// lib/core/http/http_client.dart
class HttpClient {
  static final dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 30),
      sendTimeout: Duration(seconds: 30),
    ),
  );
  
  static void configure() {
    // Add caching interceptor
    dio.interceptors.add(DioCacheInterceptor(
      options: CacheOptions(
        store: MemCacheStore(),
        maxStale: Duration(minutes: 10),
      ),
    ));
  }
}
```

## 🔒 Security Setup

### 1. API Key Management

#### Environment Variables
```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  // Validate configuration
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Missing required environment variables');
    }
  }
}
```

#### Secure Storage
```dart
// Use flutter_secure_storage for sensitive data
final storage = FlutterSecureStorage();

// Store securely
await storage.write(key: 'refresh_token', value: refreshToken);

// Read securely  
final refreshToken = await storage.read(key: 'refresh_token');
```

### 2. Network Security

#### Certificate Pinning
```dart
// lib/core/http/certificate_pinning.dart
class CertificatePinning {
  static Dio configureDio() {
    final dio = Dio();
    
    // Add certificate pinning in production
    if (kReleaseMode) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) {
          // Implement certificate validation
          return validateCertificate(cert, host);
        };
        return client;
      };
    }
    
    return dio;
  }
}
```

## 🚀 Deployment Setup

### 1. Build Configurations

#### Environment-Specific Builds
```bash
# Development build
flutter run --dart-define=ENVIRONMENT=development

# Staging build
flutter build apk --dart-define=ENVIRONMENT=staging --release

# Production build
flutter build apk --dart-define=ENVIRONMENT=production --release
```

#### Build Scripts
```bash
#!/bin/bash
# scripts/build_android.sh

echo "Building Android app..."

# Clean previous build
flutter clean
flutter pub get

# Build APK
flutter build apk --release --dart-define=ENVIRONMENT=production

# Build App Bundle for Play Store
flutter build appbundle --release --dart-define=ENVIRONMENT=production

echo "Build completed successfully!"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Bundle: build/app/outputs/bundle/release/app-release.aab"
```

### 2. Code Signing

#### iOS Code Signing
1. **Create Certificates**:
   - Development certificate for testing
   - Distribution certificate for App Store

2. **Provisioning Profiles**:
   - Development profile for testing
   - App Store profile for distribution

3. **Xcode Configuration**:
   - Select correct team and certificates
   - Configure automatic signing (recommended)

#### Android Code Signing
```bash
# Generate keystore
keytool -genkey -v -keystore ~/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure in android/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/path/to/keystore.jks
```

### 3. CI/CD Configuration

#### GitHub Actions
```yaml
# .github/workflows/build-and-test.yml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.13.0'
    - run: flutter pub get
    - run: flutter test
    - run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - name: Build APK
      run: flutter build apk --release
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release-apk
        path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - name: Build iOS
      run: flutter build ios --release --no-codesign
    - name: Upload iOS build
      uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: build/ios/iphoneos/Runner.app
```

## 🆘 Troubleshooting Common Issues

### 1. Flutter Issues

#### Flutter Doctor Issues
```bash
# Run flutter doctor to check setup
flutter doctor -v

# Fix missing dependencies
flutter doctor --android-licenses
```

#### Dependency Issues
```bash
# Clear pub cache
flutter pub cache clean

# Get dependencies
flutter pub get

# Rebuild project
flutter clean
flutter pub get
```

### 2. Platform-Specific Issues

#### iOS Issues
```bash
# Pod installation issues
cd ios
rm Podfile.lock
pod install --repo-update

# Xcode build issues
rm -rf build
xcodebuild clean
```

#### Android Issues
```bash
# Gradle issues
cd android
./gradlew clean
./gradlew build

# SDK issues
flutter doctor --android-licenses
```

### 3. Development Issues

#### Hot Reload Not Working
1. Check if file is saved properly
2. Restart app with `R` instead of `r`
3. Check for syntax errors
4. Restart IDE if needed

#### Import Errors
1. Run `flutter pub get`
2. Check import paths
3. Restart Dart analysis server in VS Code

#### Build Errors
1. Check pubspec.yaml syntax
2. Update dependencies: `flutter pub upgrade`
3. Clear build: `flutter clean && flutter pub get`

### 4. Database Issues

#### Connection Issues
```dart
// Test Supabase connection
try {
  final response = await Supabase.instance.client
      .from('users')
      .select('count')
      .count(CountOption.exact);
  print('Database connection successful');
} catch (e) {
  print('Database connection failed: $e');
}
```

#### RLS Policy Issues
```sql
-- Temporarily disable RLS for testing
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- Check policy effectiveness
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM posts WHERE user_id = 'test-user';
```

## 📚 Additional Resources

### Documentation Links
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Supabase Documentation](https://supabase.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

### Useful Commands Reference
```bash
# Flutter commands
flutter --version
flutter doctor
flutter devices
flutter emulators
flutter clean
flutter pub get
flutter pub upgrade
flutter analyze
flutter test
flutter build apk
flutter build ios

# Git commands
git status
git add .
git commit -m "message"
git push origin branch-name
git pull origin main
git checkout -b new-branch

# Android debugging
adb devices
adb logcat
adb shell
adb install app.apk

# iOS debugging
xcrun simctl list devices
xcrun simctl boot device-id
xcrun simctl shutdown device-id
```

### Development Tools
- **VS Code Extensions**:
  - Flutter
  - Dart
  - GitLens
  - Error Lens
  - Better Comments

- **Debugging Tools**:
  - Flutter Inspector
  - Dart DevTools
  - Firebase Crashlytics
  - Flipper (for network debugging)

## 🎨 Design Guidelines

### Color System
The app uses a logo-inspired orange/yellow color scheme for brand consistency:

```dart
// Primary Colors (use for main actions)
AppColors.primary        // #FF6B35 - Vibrant orange
AppColors.accent         // #FFA726 - Golden yellow  
AppColors.accentDark     // #E65100 - Deep orange

// Background Colors
AppColors.bg             // #FFFAF7 - Warm white
AppColors.primarySoft    // #FFF4F0 - Light orange tint
AppColors.subtleFill     // #FFF7F3 - Subtle fill

// UI Colors
AppColors.border         // #FFDD4 - Orange-tinted border
AppColors.textSecondary  // #8B4513 - Warm brown text
```

### Color Usage Rules
- **Orange (`primary`)**: Investment buttons, main CTAs, highlights
- **Golden Yellow (`accent`)**: Collaboration features, secondary actions
- **Deep Orange (`accentDark`)**: Suggestions, emphasis, urgency
- **DO NOT use orange for**: Errors (red), success (green), warnings (amber)

### Component Guidelines
```dart
// Action Buttons
_ActionButton(
  color: AppColors.primary,    // Investment
  color: AppColors.accent,     // Collaboration  
  color: AppColors.accentDark, // Suggestions
)

// Navigation Highlights
activeColor: AppColors.primarySoft

// Borders and Accents
borderColor: AppColors.border
```

---

**Setup Complete!** 🎉 

You should now have a fully configured development environment for the FounderVers mobile app. If you encounter any issues not covered in this guide, please check the troubleshooting section or reach out to the development team.

**Last Updated**: September 1, 2025  
**Guide Version**: 1.1.0

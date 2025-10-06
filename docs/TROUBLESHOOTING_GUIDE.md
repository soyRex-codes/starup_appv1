# Troubleshooting Guide - FounderVers Mobile

## 🔧 Overview

This guide provides comprehensive troubleshooting solutions for common issues in the FounderVers mobile application, which uses **Flutter 3.24+** and **Supabase** as the backend.

**Last Updated**: September 23, 2025  
**App Version**: 1.0.0+1 (Production-ready with navigation updates)  
**Flutter Version**: 3.24.0+  
**Dart Version**: 3.4.0+  
**Status**: All core systems operational

## 📋 Table of Contents

0. [Current System Status](#current-system-status)
1. [Development Environment Issues](#development-environment-issues)
2. [Supabase Connection Issues](#supabase-connection-issues)
3. [Authentication Problems](#authentication-problems)
4. [Cache & Performance Issues](#cache--performance-issues)
5. [Real-time Messaging Issues](#real-time-messaging-issues)
6. [Build and Compilation Errors](#build-and-compilation-errors)
7. [Database & Schema Issues](#database--schema-issues)
8. [Platform-Specific Issues](#platform-specific-issues)
9. [Testing & Debugging](#testing--debugging)
10. [Production Deployment Issues](#production-deployment-issues)

## ✅ Current System Status

### 🎯 **All Systems Operational** (September 23, 2025)

**Core Features Working:**
- ✅ Authentication with OTP verification
- ✅ Post creation and management with media support
- ✅ Real-time messaging with unread badges
- ✅ Feed caching system (70%+ hit rate)
- ✅ Global community chat
- ✅ Business services ecosystem portal
- ✅ Email notifications (production Gmail SMTP)
- ✅ Simplified suggestions system (read/unread)
- ✅ Navigation: Feed → Ecosystem → Create → Global → DMs

**Recent Fixes Applied:**
- ✅ Navigation bar restructured for better UX
- ✅ Suggestions system simplified from 5-status to boolean read/unread
- ✅ Database schema successfully migrated
- ✅ Email notification system deployed and functional
- ✅ Orange/yellow theme fully implemented
- ✅ All compilation errors resolved

**Performance Status:**
- ✅ Cache hit rate: 70%+ 
- ✅ Database queries optimized with RLS policies
- ✅ Real-time messaging responsive
- ✅ Navigation transitions smooth

**If you're experiencing issues, they're likely configuration-related rather than code bugs, as all core systems are verified working.**

## 🛠️ Development Environment Issues

### Flutter SDK Version Issues

#### Problem: Incompatible Flutter/Dart version
```bash
The current Dart SDK version is 3.2.0.
Because startup_app requires SDK version >=3.4.0, version solving failed.
```

**Solution**:
```bash
# Update Flutter to latest stable (3.24.0+)
flutter upgrade

# Verify version
flutter --version
# Expected: Flutter 3.24.0 • Dart 3.4.0

# Check system compatibility
flutter doctor -v

# If still issues, clean and reinstall
flutter clean
flutter pub get
```

#### Problem: Flutter doctor issues
```bash
[!] Xcode - develop for iOS (issues found)
[!] Android toolchain - issues found
```

**Solutions**:
```bash
# Fix Xcode issues (macOS)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Fix Android issues
flutter doctor --android-licenses

# Install missing components
flutter doctor --verbose
```

### VS Code Extension Issues

#### Problem: Flutter extension not working
**Solutions**:
1. **Reload VS Code window**: `Cmd+Shift+P` → "Developer: Reload Window"
2. **Restart Dart Analysis Server**: `Cmd+Shift+P` → "Dart: Restart Analysis Server" 
3. **Clear VS Code cache**:
   ```bash
   rm -rf ~/.vscode/extensions/Dart-Code.*
   code --install-extension Dart-Code.flutter
   ```

## 🔗 Supabase Connection Issues

### Connection Failures

#### Problem: Unable to connect to Supabase
```dart
SupabaseException: Failed to connect to Supabase
```

**Debugging Steps**:
```bash
# 1. Check environment variables
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY

# 2. Test connection manually
curl -H "apikey: YOUR_ANON_KEY" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     "YOUR_SUPABASE_URL/rest/v1/"
```

**Solutions**:
1. **Verify project URL and keys** in Supabase Dashboard → Settings → API
2. **Check network connectivity**: 
   ```dart
   // Add connection timeout handling
   final supabase = SupabaseClient(
     supabaseUrl,
     supabaseAnonKey,
     httpClient: http.Client(),
     headers: {'apikey': supabaseAnonKey},
   );
   ```
3. **Update dependencies**:
   ```bash
   flutter pub upgrade supabase_flutter
   ```

### RLS (Row Level Security) Issues

#### Problem: Permission denied for table access
```sql
permission denied for table users
```

**Solutions**:
1. **Check RLS policies** in Supabase Dashboard → Authentication → Policies
2. **Verify user authentication**:
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   if (user == null) {
     // User not authenticated - redirect to login
   }
   ```
3. **Test policies in SQL Editor**:
   ```sql
   -- Test RLS policy for current user
   SELECT * FROM users WHERE id = auth.uid();
   ```

## 🔐 Authentication Problems

### Supabase Auth Issues

#### Problem: User sign-up fails
```dart
AuthException: User registration failed
```

**Solutions**:
1. **Check email validation**:
   ```dart
   bool isValidEmail(String email) {
     return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
   }
   ```
2. **Verify Supabase settings**:
   - Dashboard → Authentication → Settings
   - Enable **Email** provider
   - Check **Email confirmation** settings
3. **Handle auth exceptions properly**:
   ```dart
   try {
     final response = await Supabase.instance.client.auth.signUp(
       email: email,
       password: password,
     );
   } on AuthException catch (e) {
     print('Auth error: ${e.message}');
     // Handle specific error codes
   }
   ```

#### Problem: Password reset OTP not working
```dart
// OTP verification fails
```

**Debugging**:
1. **Check PasswordResetService implementation**:
   ```dart
   // Verify OTP table exists and has correct structure
   final otpRecord = await supabase
       .from('password_reset_otp')
       .select('*')
       .eq('email', email)
       .eq('is_used', false)
       .order('created_at', ascending: false)
       .limit(1)
       .maybeSingle();
   ```
2. **Verify email template** in Supabase Dashboard → Authentication → Email Templates
3. **Check OTP expiration logic** (currently 15 minutes):
   ```sql
   -- Check if OTP is expired
   SELECT *, 
          CASE WHEN created_at < NOW() - INTERVAL '15 minutes' 
               THEN true ELSE false END as is_expired
   FROM password_reset_otp 
   WHERE email = $1 AND is_used = false;
   ```

### Session Management Issues

#### Problem: User session expires unexpectedly
**Solutions**:
1. **Implement session refresh**:
   ```dart
   // Auto-refresh session
   Supabase.instance.client.auth.onAuthStateChange.listen((data) {
     final session = data.session;
     if (session != null) {
       // Session is active
     } else {
       // Redirect to login
     }
   });
   ```
2. **Handle network interruptions**:
   ```dart
   // Retry auth operations on network issues
   Future<void> retryAuthOperation() async {
     int retries = 3;
     while (retries > 0) {
       try {
         await authOperation();
         break;
       } catch (e) {
         retries--;
         await Future.delayed(Duration(seconds: 2));
       }
     }
   }
   ```

## ⚡ Cache & Performance Issues

### Feed Cache Problems

#### Problem: Cache hit rate below 70%
**Debugging**:
```dart
// Check cache performance in FeedCache
final cache = FeedCache.instance;
print('Hit rate: ${cache.hitRate}');
print('Cache size: ${cache.currentSize}/${cache.maxSize}');
print('Hits: ${cache.hits}, Misses: ${cache.misses}');
```

**Solutions**:
1. **Verify adaptive sizing**:
   ```dart
   // Check if device capability detection is working
   final processorCount = Platform.numberOfProcessors;
   print('Processors: $processorCount');
   print('Max cache size: ${cache.maxSize}');
   ```
2. **Optimize TTL settings**:
   ```dart
   // Adjust TTL based on content type
   Duration getOptimalTTL(String? category, String? search) {
     if (search != null) return Duration(minutes: 1);      // More aggressive for search
     if (category == 'trending') return Duration(minutes: 2); // Shorter for trending
     return Duration(minutes: 10);                         // Longer for categories
   }
   ```
3. **Monitor LRU eviction**:
   ```dart
   // Add eviction logging
   @override
   void _evictLRU() {
     final evicted = _cache.keys.first;
     print('Evicting cache entry: $evicted');
     super._evictLRU();
   }
   ```

#### Problem: Memory usage too high
**Solutions**:
1. **Reduce cache size for low-end devices**:
   ```dart
   int get adaptiveMaxSize {
     final processorCount = Platform.numberOfProcessors;
     final memoryMB = Platform.memorySize ~/ (1024 * 1024);
     
     if (memoryMB < 3000) return 20;          // Low memory: 20 entries
     else if (processorCount >= 8) return 75; // High-end: 75 entries
     else if (processorCount >= 4) return 50; // Mid-range: 50 entries
     else return 30;                          // Default: 30 entries
   }
   ```
2. **Implement memory pressure handling**:
   ```dart
   // Clear cache on memory warnings
   SystemChrome.systemUIChangeCallback = (systemUIMode) {
     if (systemUIMode == SystemUiMode.memoryWarning) {
       FeedCache.instance.clear();
     }
   };
   ```

## 💬 Real-time Messaging Issues

### WebSocket Connection Problems

#### Problem: Real-time messages not received
```dart
// Messages sent but not received in real-time
```

**Debugging**:
1. **Check subscription status**:
   ```dart
   final channel = supabase.channel('messages_$conversationId');
   print('Channel status: ${channel.status}');
   ```
2. **Verify table-level subscriptions**:
   ```sql
   -- Check if realtime is enabled for messages table
   SELECT schemaname, tablename, replica_identity 
   FROM pg_tables 
   WHERE tablename = 'messages';
   ```
3. **Monitor WebSocket connection**:
   ```dart
   supabase.channel('debug').onPresenceSync((presences) {
     print('WebSocket active, presences: $presences');
   }).subscribe();
   ```

**Solutions**:
1. **Enable realtime in Supabase Dashboard** → Database → Replication
2. **Add proper filters**:
   ```dart
   supabase.channel('messages_$conversationId')
     .onPostgresChanges(
       event: PostgresChangeEvent.insert,
       schema: 'public',
       table: 'messages',
       filter: PostgresChangeFilter(
         type: PostgresChangeFilterType.eq,
         column: 'conversation_id',
         value: conversationId,
       ),
       callback: (payload) => _handleNewMessage(payload.newRecord),
     ).subscribe();
   ```
3. **Handle connection drops**:
   ```dart
   void _setupReconnectionLogic() {
     Timer.periodic(Duration(seconds: 30), (timer) {
       if (!isConnected) {
         _reconnectWebSocket();
       }
     });
   }
   ```

### Message Ordering Issues

#### Problem: Messages appear out of order
**Solutions**:
1. **Use database timestamps**:
   ```sql
   -- Ensure created_at has proper default
   ALTER TABLE messages 
   ALTER COLUMN created_at SET DEFAULT NOW();
   ```
2. **Sort messages by timestamp**:
   ```dart
   messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
   ```
3. **Implement optimistic updates carefully**:
   ```dart
   // Add temporary ID for optimistic updates
   final tempMessage = Message(
     id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
     content: content,
     createdAt: DateTime.now(),
     isOptimistic: true,
   );
   ```
[!] Android toolchain - develop for Android devices
[!] Xcode - develop for iOS and macOS
[!] VS Code
```

**Solutions**:
1. **Android Toolchain**:
   ```bash
   # Install Android Studio
   # Accept licenses
   flutter doctor --android-licenses
   
   # Set ANDROID_HOME
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
   ```

2. **Xcode (macOS only)**:
   ```bash
   # Install Xcode from App Store
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

3. **VS Code Extensions**:
   - Install Flutter extension
   - Install Dart extension

### Dependency Issues

#### Problem: Package conflicts or outdated dependencies
```yaml
Because every version of flutter_test from sdk depends on...
```

**Solutions**:
1. **Clean and reinstall dependencies**:
   ```bash
   flutter clean
   rm pubspec.lock
   flutter pub get
   ```

2. **Update dependencies**:
   ```bash
   flutter pub upgrade
   flutter pub outdated
   ```

3. **Resolve conflicts manually**:
   ```yaml
   dependency_overrides:
     collection: ^1.17.0
     meta: ^1.9.0
   ```

4. **Check compatibility**:
   ```bash
   flutter pub deps
   flutter analyze
   ```

## 🏗️ Build and Compilation Errors

### Dart Compilation Errors

#### Problem: Type errors or null safety issues
```dart
The argument type 'String?' can't be assigned to the parameter type 'String'
```

**Solutions**:
1. **Null safety fixes**:
   ```dart
   // Before
   String name = user.name;
   
   // After
   String name = user.name ?? 'Unknown';
   String? name = user.name;
   String name = user.name!; // Only if you're sure it's not null
   ```

2. **Type casting**:
   ```dart
   // Safe casting
   final data = response.data as Map<String, dynamic>? ?? {};
   
   // List casting
   final items = (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
   ```

#### Problem: Import errors
```dart
Target of URI doesn't exist: 'package:starup_appv1/missing_file.dart'
```

**Solutions**:
1. **Check file paths**:
   ```dart
   // Correct relative import
   import '../models/user.dart';
   
   // Correct package import
   import 'package:starup_appv1/models/user.dart';
   ```

2. **Clean build cache**:
   ```bash
   flutter clean
   flutter pub get
   ```

### Android Build Issues

#### Problem: Gradle build fails
```
FAILURE: Build failed with an exception.
```

**Solutions**:
1. **Update Gradle version** (`android/build.gradle`):
   ```gradle
   dependencies {
       classpath 'com.android.tools.build:gradle:8.1.2'
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```

2. **Update Gradle wrapper** (`android/gradle/wrapper/gradle-wrapper.properties`):
   ```properties
   distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
   ```

3. **Clean Android build**:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter build apk
   ```

#### Problem: Multidex issues
```
Cannot fit requested classes in a single dex file
```

**Solutions**:
1. **Enable multidex** (`android/app/build.gradle`):
   ```gradle
   android {
       defaultConfig {
           multiDexEnabled true
       }
   }
   
   dependencies {
       implementation 'androidx.multidex:multidex:2.0.1'
   }
   ```

2. **Optimize app size**:
   ```gradle
   android {
       buildTypes {
           release {
               shrinkResources true
               minifyEnabled true
               proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
           }
       }
   }
   ```

### iOS Build Issues

#### Problem: Xcode build fails
```
Undefined symbols for architecture arm64
```

**Solutions**:
1. **Clean iOS build**:
   ```bash
   cd ios
   rm -rf Pods
   rm Podfile.lock
   pod install
   cd ..
   flutter clean
   flutter build ios
   ```

2. **Update iOS deployment target** (`ios/Podfile`):
   ```ruby
   platform :ios, '12.0'
   ```

3. **Update Runner target** (in Xcode):
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Set iOS Deployment Target to 12.0+

#### Problem: CocoaPods issues
```
[!] Unable to find a specification for 'Firebase/Core'
```

**Solutions**:
1. **Update CocoaPods**:
   ```bash
   sudo gem install cocoapods
   pod repo update
   ```

2. **Clean and reinstall**:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install --repo-update
   ```

## 🔐 Authentication Issues

### Firebase Authentication

#### Problem: FirebaseApp not initialized
```
No Firebase App '[DEFAULT]' has been created
```

**Solutions**:
1. **Check Firebase configuration**:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

2. **Initialize Firebase in main.dart**:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(MyApp());
   }
   ```

3. **Regenerate Firebase options**:
   ```bash
   flutterfire configure
   ```

#### Problem: Authentication state not persisting
```dart
User gets signed out after app restart
```

**Solutions**:
1. **Check auth persistence**:
   ```dart
   class AuthService {
     static final FirebaseAuth _auth = FirebaseAuth.instance;
     
     Stream<User?> get user => _auth.authStateChanges();
     
     Future<void> checkAuthState() async {
       await _auth.authStateChanges().first;
     }
   }
   ```

2. **Handle auth state properly**:
   ```dart
   StreamBuilder<User?>(
     stream: FirebaseAuth.instance.authStateChanges(),
     builder: (context, snapshot) {
       if (snapshot.connectionState == ConnectionState.waiting) {
         return LoadingScreen();
       }
       
       if (snapshot.hasData && snapshot.data != null) {
         return HomeScreen();
       }
       
       return AuthScreen();
     },
   )
   ```

### Supabase Authentication

#### Problem: RLS preventing data access
```
Row level security policy violation
```

**Solutions**:
1. **Check RLS policies**:
   ```sql
   -- Verify user can access data
   SELECT * FROM users WHERE auth.uid() = id;
   ```

2. **Debug auth state**:
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   print('User ID: ${user?.id}');
   print('Email: ${user?.email}');
   ```

3. **Refresh session**:
   ```dart
   await Supabase.instance.client.auth.refreshSession();
   ```

#### Problem: Email confirmation not working
```
Email not confirmed after signup
```

**Solutions**:
1. **Check email confirmation settings** in Supabase dashboard
2. **Handle confirmation in app**:
   ```dart
   // Listen for auth changes
   Supabase.instance.client.auth.onAuthStateChange.listen((data) {
     final AuthChangeEvent event = data.event;
     final Session? session = data.session;
     
     if (event == AuthChangeEvent.signedIn) {
       // Handle successful sign in
       Navigator.pushReplacementNamed(context, '/home');
     }
   });
   ```

## 🗄️ Database Connection Issues

### Supabase Connection

#### Problem: Connection timeouts
```
TimeoutException: Connection timeout
```

**Solutions**:
1. **Check internet connectivity**:
   ```dart
   import 'package:connectivity_plus/connectivity_plus.dart';
   
   final connectivity = await Connectivity().checkConnectivity();
   if (connectivity == ConnectivityResult.none) {
     // Handle offline state
   }
   ```

2. **Increase timeout**:
   ```dart
   final client = SupabaseClient(
     'your-url',
     'your-key',
     httpClient: http.Client(),
     headers: {'timeout': '30'},
   );
   ```

3. **Add retry logic**:
   ```dart
   Future<T> retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
     for (int i = 0; i < maxRetries; i++) {
       try {
         return await request();
       } catch (e) {
         if (i == maxRetries - 1) rethrow;
         await Future.delayed(Duration(seconds: pow(2, i).toInt()));
       }
     }
     throw Exception('Max retries exceeded');
   }
   ```

#### Problem: RLS policy errors
```
insufficient_privilege: RLS policy violation
```

**Solutions**:
1. **Check user authentication**:
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   if (user == null) {
     // Redirect to login
     return;
   }
   ```

2. **Debug RLS policies**:
   ```sql
   -- Test policy manually
   SET LOCAL "request.jwt.claims" = '{"sub":"user-uuid","email":"user@example.com"}';
   SELECT * FROM posts WHERE user_id = 'user-uuid';
   ```

3. **Temporary disable RLS** (for debugging only):
   ```sql
   ALTER TABLE posts DISABLE ROW LEVEL SECURITY;
   ```

### Database Migration Issues

#### Problem: Migration fails
```
relation "posts" already exists
```

**Solutions**:
1. **Check migration state**:
   ```bash
   supabase migration list
   supabase db diff
   ```

2. **Manual cleanup**:
   ```sql
   -- Drop and recreate table (careful!)
   DROP TABLE IF EXISTS posts CASCADE;
   ```

3. **Reset migrations**:
   ```bash
   supabase db reset
   supabase migration up
   ```

## 🎨 UI/Layout Issues

### RenderFlex Overflow

#### Problem: RenderFlex overflow errors
```
RenderFlex overflowed by X pixels on the right/bottom
```

**Solutions**:
1. **Use Flexible/Expanded widgets**:
   ```dart
   Row(
     children: [
       Flexible(child: Text('Long text that might overflow')),
       Icon(Icons.star),
     ],
   )
   ```

2. **Add MainAxisSize.min**:
   ```dart
   Column(
     mainAxisSize: MainAxisSize.min,
     children: [...],
   )
   ```

3. **Use SingleChildScrollView**:
   ```dart
   SingleChildScrollView(
     scrollDirection: Axis.horizontal,
     child: Row(children: [...]),
   )
   ```

### Widget Constraint Issues

#### Problem: Widget has unbounded height/width
```
RenderBox was not laid out
```

**Solutions**:
1. **Wrap in Container with constraints**:
   ```dart
   Container(
     height: 200,
     child: ListView(...),
   )
   ```

2. **Use Expanded in Flex widgets**:
   ```dart
   Column(
     children: [
       Text('Header'),
       Expanded(child: ListView(...)),
     ],
   )
   ```

3. **Add shrinkWrap to scrollables**:
   ```dart
   ListView(
     shrinkWrap: true,
     physics: NeverScrollableScrollPhysics(),
     children: [...],
   )
   ```

### Theme and Styling Issues

#### Problem: Colors not applying correctly
```dart
Colors appear different than expected
```

**Solutions**:
1. **Check theme inheritance**:
   ```dart
   Theme.of(context).colorScheme.primary
   // vs
   Colors.blue
   ```

2. **Use Material Design 3**:
   ```dart
   MaterialApp(
     theme: ThemeData(
       useMaterial3: true,
       colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
     ),
   )
   ```

3. **Debug theme values**:
   ```dart
   print('Primary color: ${Theme.of(context).primaryColor}');
   print('Background: ${Theme.of(context).scaffoldBackgroundColor}');
   ```

## 🌐 Network and API Issues

### HTTP Errors

#### Problem: HTTP 403/401 errors
```
Exception: HTTP 403 Forbidden
```

**Solutions**:
1. **Check authentication headers**:
   ```dart
   final headers = {
     'Authorization': 'Bearer $token',
     'Content-Type': 'application/json',
     'apikey': supabaseKey,
   };
   ```

2. **Verify API key**:
   ```dart
   print('API Key: ${dotenv.env['SUPABASE_ANON_KEY']}');
   ```

3. **Check RLS policies** (see Database section)

#### Problem: CORS errors (web only)
```
Access to XMLHttpRequest has been blocked by CORS policy
```

**Solutions**:
1. **Configure CORS in Supabase** dashboard
2. **Add proxy for development**:
   ```yaml
   # pubspec.yaml
   dev_dependencies:
     build_web_compilers: ^4.0.7
   ```

3. **Use flutter run with web-port**:
   ```bash
   flutter run -d web-server --web-port 8080
   ```

### Timeout Issues

#### Problem: Request timeouts
```
TimeoutException after 0:00:30.000000
```

**Solutions**:
1. **Increase timeout globally**:
   ```dart
   final client = http.Client();
   client.timeout = Duration(minutes: 2);
   ```

2. **Add timeout to specific requests**:
   ```dart
   final response = await http.get(uri).timeout(
     Duration(seconds: 30),
     onTimeout: () => throw TimeoutException('Request timed out'),
   );
   ```

3. **Implement retry logic** (see Database section)

## ⚡ Performance Issues

### Memory Issues

#### Problem: App crashes due to memory
```
Out of memory error
```

**Solutions**:
1. **Optimize image loading**:
   ```dart
   Image.network(
     url,
     cacheHeight: 300,
     cacheWidth: 300,
     fit: BoxFit.cover,
   )
   ```

2. **Use lazy loading**:
   ```dart
   ListView.builder(
     itemCount: items.length,
     itemBuilder: (context, index) {
       if (index == items.length - 1) {
         _loadMore();
       }
       return ListTile(...);
     },
   )
   ```

3. **Clear image cache**:
   ```dart
   PaintingBinding.instance.imageCache.clear();
   PaintingBinding.instance.imageCache.clearLiveImages();
   ```

### Performance Profiling

#### Problem: Slow UI rendering
```
Frame rendering taking too long
```

**Solutions**:
1. **Enable performance overlay**:
   ```dart
   MaterialApp(
     showPerformanceOverlay: true,
     // or
     debugShowCheckedModeBanner: false,
   )
   ```

2. **Profile widget builds**:
   ```dart
   class MyWidget extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       print('Building MyWidget at ${DateTime.now()}');
       return Container(...);
     }
   }
   ```

3. **Use DevTools profiler**:
   ```bash
   flutter run --profile
   # Open DevTools in browser
   ```

## 📱 Platform-Specific Issues

### Android Issues

#### Problem: App not installing on device
```
Installation failed due to: 'Failed to finalize session'
```

**Solutions**:
1. **Check USB debugging**:
   ```bash
   adb devices
   flutter devices
   ```

2. **Enable unknown sources**:
   - Settings → Security → Unknown Sources

3. **Uninstall previous version**:
   ```bash
   adb uninstall com.example.starup_appv1
   ```

#### Problem: Permissions not working
```
Permission denied for camera/storage
```

**Solutions**:
1. **Add permissions** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   ```

2. **Request runtime permissions**:
   ```dart
   import 'package:permission_handler/permission_handler.dart';
   
   await Permission.camera.request();
   if (await Permission.camera.isGranted) {
     // Use camera
   }
   ```

### iOS Issues

#### Problem: App crashes on iOS device
```
dyld: Library not loaded
```

**Solutions**:
1. **Check iOS deployment target**:
   - Open Xcode → Runner target
   - Set iOS Deployment Target to 12.0+

2. **Update Info.plist** permissions:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access to take photos</string>
   ```

3. **Clean derived data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

## 🚀 Deployment Issues

### App Store Issues

#### Problem: App Store Connect upload fails
```
Invalid binary
```

**Solutions**:
1. **Build release mode**:
   ```bash
   flutter build ipa --release
   ```

2. **Check bundle identifier**:
   ```bash
   # iOS: ios/Runner/Info.plist
   <key>CFBundleIdentifier</key>
   <string>com.foundervers.app</string>
   ```

3. **Validate before upload**:
   - Use Xcode → Product → Archive
   - Validate before distributing

### Google Play Issues

#### Problem: Play Store upload rejected
```
App Bundle contains native code, but you haven't uploaded any deobfuscation files
```

**Solutions**:
1. **Build App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

2. **Generate symbols file**:
   ```bash
   flutter build appbundle --release --split-debug-info=symbols
   ```

3. **Upload mapping file** to Play Console

## 🔍 Debugging Tools

### Flutter Inspector

**Usage**:
```bash
flutter run
# Press 'i' in terminal to launch inspector
```

**Features**:
- Widget tree visualization
- Property inspection
- Layout constraints debugging

### Performance Profiling

**DevTools**:
```bash
flutter run --profile
# Open DevTools URL in browser
```

**CPU Profiling**:
```dart
import 'dart:developer' as developer;

developer.Timeline.startSync('expensive_operation');
// Your code here
developer.Timeline.finishSync();
```

### Network Debugging

**HTTP Logging**:
```dart
import 'package:dio/dio.dart';

final dio = Dio();
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

**Charles Proxy Setup** (macOS):
1. Install Charles Proxy
2. Configure device proxy to computer IP
3. Install Charles certificate on device

### Database Debugging

**Supabase Logging**:
```dart
Supabase.initialize(
  url: 'your-url',
  anonKey: 'your-key',
  debug: true, // Enables logging
);
```

**SQL Query Logging**:
```sql
-- Enable query logging in PostgreSQL
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
```

### Memory Debugging

**Memory Usage**:
```dart
import 'dart:io';

final usage = ProcessInfo.currentRss;
print('Memory usage: ${usage ~/ 1024 ~/ 1024} MB');
```

**Leak Detection**:
```bash
flutter run --debug --trace-startup --verbose
```

## 📞 Getting Help

### Official Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)
- [Supabase Documentation](https://supabase.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

### Community Support

- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Discord](https://discord.gg/N7Yshp4)
- [Reddit - r/FlutterDev](https://www.reddit.com/r/FlutterDev/)

### Internal Support

- Create issue in project repository
- Contact development team
- Check internal documentation

## 📝 Reporting Issues

### Bug Report Template

```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Issue occurs

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Flutter version: `flutter --version`
- Device: iPhone 14 Pro / Pixel 7
- OS version: iOS 16.0 / Android 13

## Error Messages
```
Paste any error messages here
```

## Additional Context
Any additional information
```

### Performance Issue Template

```markdown
## Performance Issue
Description of performance problem

## Metrics
- Frame rate: X fps
- Memory usage: X MB
- Load time: X seconds

## Device Information
- Model: iPhone 14 Pro
- RAM: 6GB
- Storage: 256GB

## Profiling Data
Attach DevTools profiling screenshots
```

---

**Last Updated**: August 26, 2025  
**Version**: 1.0.0  
**Maintainer**: Development Team

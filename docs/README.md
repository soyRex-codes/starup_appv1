# FounderVers Mobile App - Developer Documentation

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

## Quick Start

```bash
# Clone the repository
git clone https://github.com/soyRex-codes/mobile_app_foundervers.git
cd starup_appv1

# Install dependencies
flutter pub get

# Configure environment
cp .env.mobile.example .env.mobile
# Edit .env.mobile with your Supabase credentials

# Run the app
flutter run
```

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Setup & Installation](#setup--installation)
4. [Development Guide](#development-guide)
5. [Database Schema](#database-schema)
6. [API Documentation](#api-documentation)
7. [UI/UX Guidelines](#uiux-guidelines)
8. [Testing](#testing)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)
11. [Contributing](#contributing)

## Project Overview

FounderVers Mobile is a Flutter-based mobile application that brings the core functionality of the FounderVers platform to iOS and Android devices. It enables entrepreneurs to create posts, discover funding opportunities, build teams, and communicate through an integrated messaging system.

### Key Features

- **Authentication**: Secure mobile-first authentication with OTP verification
- **Post Creation**: Create, edit, and manage startup posts with media support
- **Funding Goals**: Set and track funding objectives with goal-based filtering
- **Team Building**: Find co-founders and team members through ecosystem
- **Real-time Messaging**: Direct messaging with typing indicators and unread badges
- **Global Chat**: Community discussions for all founders
- **Ecosystem Applications**: Business services portal with professional connections
- **Simplified Suggestions**: Read/unread feedback system with email-like workflow
- **Email Notifications**: Production-ready email system for business applications
- **Modern UI**: Logo-inspired orange/yellow Material Design 3 theme
- **Performance**: Advanced caching system with 70%+ hit rate
- **Smart Filtering**: Filter posts by category, goals, and real-time search

### Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.0+ |
| **Language** | Dart 3.0+ |
| **Authentication** | Firebase Auth |
| **Database** | Supabase (PostgreSQL) |
| **Storage** | Supabase Storage |
| **Real-time** | Supabase Realtime |
| **State Management** | Provider + setState |
| **Navigation** | Flutter Navigator |
| **Testing** | Flutter Test Framework |

## Architecture

### Project Structure

```
lib/
├── app/                    # App-wide configuration
│   ├── widgets/           # Reusable UI components
│   │   ├── app_header.dart
│   │   └── filter_sheet.dart
│   └── app_icons.dart     # Icon management
├── core/                  # Core utilities
│   ├── constants.dart     # App constants
│   ├── errors/           # Error handling
│   └── utils/            # Utility functions
├── features/             # Feature modules (13 modules)
│   ├── auth/             # Authentication & onboarding
│   ├── feed/             # Post feed with caching
│   ├── ecosystem/        # Business services portal
│   ├── dm/               # Direct messaging system
│   ├── post_creation/    # Post creation/editing
│   ├── profile/          # User profiles
│   ├── Global_public_chat-for_founders/ # Community chat
│   ├── suggestions/      # Simplified feedback system
│   └── ...               # Additional feature modules
├── models/               # Data models
├── services/            # Business logic services
└── main.dart           # App entry point
```

### Architecture Patterns

- **Feature-First**: Code organized by features, not layers
- **Clean Architecture**: Separation of concerns with clear boundaries
- **Repository Pattern**: Data access abstraction
- **Service Layer**: Business logic centralization

### Data Flow

```
UI Components → Services → Supabase Client → PostgreSQL Database
     ↑              ↑           ↑                    ↑
   State         Models      Auth          Row Level Security
```

## Setup & Installation

### Prerequisites

- **Flutter SDK**: 3.0 or higher
- **Dart SDK**: 3.0 or higher
- **Xcode**: Latest (for iOS development)
- **Android Studio**: Latest (for Android development)
- **Firebase Project**: For authentication
- **Supabase Project**: For database and storage

### Environment Configuration

1. **Copy environment file**:
   ```bash
   cp .env.mobile.example .env.mobile
   ```

2. **Configure .env.mobile**:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ADMIN_EMAILS=admin1@example.com,admin2@example.com
   STARTUPBUILDER_BUCKET=startupbuilder
   APPLICATIONS_BUCKET=applications
   ```

3. **Firebase Configuration**:

   **iOS**: Place `ios/Runner/GoogleService-Info.plist`
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <!-- Your Firebase iOS config -->
   </plist>
   ```

   **Android**: Place `android/app/google-services.json`
   ```json
   {
     "project_info": {
       "project_number": "your_project_number",
       "project_id": "your_project_id"
     }
   }
   ```

### Database Setup

1. **Apply schema**:
   ```bash
   # Run the main database schema
   psql -h your_host -p 5432 -U postgres -d your_db -f main_mobile_app_database_schema.sql
   ```

2. **Verify tables**:
   ```sql
   -- Check if all tables exist
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public';
   ```

## Development Guide

### Code Style & Conventions

#### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Functions**: `camelCase`
- **Variables**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`

#### File Organization
```dart
// 1. External imports
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 2. Internal imports
import '../models/post_model.dart';
import '../services/post_service.dart';

// 3. Class definition
class ExampleWidget extends StatefulWidget {
  // Implementation
}
```

#### Error Handling
```dart
try {
  final result = await service.performOperation();
  return result;
} on PostgrestException catch (e) {
  debugPrint('Database error: ${e.message}');
  throw DatabaseException(e.message);
} catch (e) {
  debugPrint('Unexpected error: $e');
  rethrow;
}
```

### State Management

#### Service Pattern
```dart
class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<List<PostModel>> getPosts({
    int limit = 20,
    int offset = 0,
    String? category,
    String? goal,
  }) async {
    var query = _supabase
        .from('posts')
        .select('*, media(*), author:users!inner(*)')
        .eq('status', 'published')
        .eq('moderation_status', 'approved')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    if (category != null) {
      query = query.eq('category', category);
    }
    
    final response = await query;
    return response.map((json) => PostModel.fromJson(json)).toList();
  }
}
```

#### Widget State Management
```dart
class FeedPage extends StatefulWidget {
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }
  
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final posts = await _postService.getPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

### Creating New Features

1. **Create feature directory**:
   ```
   lib/features/new_feature/
   ├── models/
   ├── services/
   ├── widgets/
   └── pages/
   ```

2. **Define model**:
   ```dart
   class NewFeatureModel {
     final String id;
     final String title;
     final DateTime createdAt;
     
     NewFeatureModel({
       required this.id,
       required this.title,
       required this.createdAt,
     });
     
     factory NewFeatureModel.fromJson(Map<String, dynamic> json) {
       return NewFeatureModel(
         id: json['id'],
         title: json['title'],
         createdAt: DateTime.parse(json['created_at']),
       );
     }
   }
   ```

3. **Implement service**:
   ```dart
   class NewFeatureService {
     final SupabaseClient _supabase = Supabase.instance.client;
     
     Future<List<NewFeatureModel>> getItems() async {
       final response = await _supabase
           .from('new_feature_table')
           .select()
           .order('created_at', ascending: false);
       
       return response
           .map((json) => NewFeatureModel.fromJson(json))
           .toList();
     }
   }
   ```

4. **Create UI components**:
   ```dart
   class NewFeaturePage extends StatefulWidget {
     @override
     State<NewFeaturePage> createState() => _NewFeaturePageState();
   }
   ```

### Performance Best Practices

#### Database Queries
- Always use `select()` with specific columns
- Implement pagination with `range()`
- Use indexes for filtered columns
- Avoid N+1 queries with joins

#### UI Performance
- Use `ListView.builder()` for long lists
- Implement image caching for media
- Use `const` constructors where possible
- Minimize rebuilds with proper state management

#### Memory Management
- Dispose of controllers and streams
- Use weak references for callbacks
- Implement proper lifecycle management

## Database Schema

### Core Tables

#### Users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT UNIQUE,
  name TEXT,
  username TEXT,
  full_name TEXT,
  bio TEXT,
  company TEXT,
  location TEXT,
  avatar_url TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  last_login_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Posts
```sql
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT,
  category TEXT,
  title TEXT NOT NULL,
  description TEXT,
  funding_goal NUMERIC,
  post_goal TEXT DEFAULT 'funding',
  post_goal_description TEXT,
  email TEXT,
  moderation_status TEXT DEFAULT 'approved',
  status TEXT DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Media
```sql
CREATE TABLE media (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  type TEXT DEFAULT 'image',
  filename TEXT,
  original_name TEXT,
  file_path TEXT,
  file_size BIGINT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Conversations & Messages
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT DEFAULT 'direct',
  title TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  reply_to UUID REFERENCES messages(id),
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security (RLS)

All tables implement Row Level Security policies:

```sql
-- Users can read all profiles
CREATE POLICY "users select" ON users FOR SELECT USING (TRUE);

-- Users can only update their own profile
CREATE POLICY "users update self" ON users FOR UPDATE USING (auth.uid() = id);

-- Posts are readable by all if approved and published
CREATE POLICY "posts select" ON posts FOR SELECT USING (
  (moderation_status = 'approved' AND status = 'published') 
  OR user_id = auth.uid()
);

-- Users can only modify their own posts
CREATE POLICY "posts modify own" ON posts 
FOR ALL USING (user_id = auth.uid());
```

### Database Functions

#### Get or Create Conversation
```sql
CREATE OR REPLACE FUNCTION get_or_create_direct_conversation(
  user1_id UUID,
  user2_id UUID
) RETURNS UUID AS $$
DECLARE
  conv_id UUID;
BEGIN
  -- Check if conversation exists
  SELECT c.id INTO conv_id
  FROM conversations c
  JOIN conversation_participants p1 ON c.id = p1.conversation_id
  JOIN conversation_participants p2 ON c.id = p2.conversation_id
  WHERE c.type = 'direct'
    AND p1.user_id = user1_id
    AND p2.user_id = user2_id;
  
  -- Create if not exists
  IF conv_id IS NULL THEN
    INSERT INTO conversations (type) VALUES ('direct') RETURNING id INTO conv_id;
    INSERT INTO conversation_participants (conversation_id, user_id) VALUES (conv_id, user1_id);
    INSERT INTO conversation_participants (conversation_id, user_id) VALUES (conv_id, user2_id);
  END IF;
  
  RETURN conv_id;
END;
$$ LANGUAGE plpgsql;
```

## API Documentation

### Authentication Service

#### User Registration/Login
```dart
class AuthService {
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _upsertUserProfile(credential.user!);
    return credential.user;
  }
  
  Future<void> _upsertUserProfile(User user) async {
    await Supabase.instance.client.from('users').upsert({
      'id': user.uid,
      'email': user.email,
      'name': user.displayName,
      'avatar_url': user.photoURL,
      'email_verified': user.emailVerified,
      'last_login_at': DateTime.now().toIso8601String(),
    });
  }
}
```

### Post Service

#### Create Post
```dart
Future<PostModel> createPost({
  required String title,
  required String description,
  String? category,
  String? goal,
  double? fundingGoal,
  List<XFile>? mediaFiles,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw UnauthorizedException();
  
  // Insert post
  final postData = {
    'user_id': user.uid,
    'title': title,
    'description': description,
    'category': category,
    'post_goal': goal ?? 'other',
    'funding_goal': fundingGoal,
    'status': 'published',
    'moderation_status': 'approved',
  };
  
  final response = await _supabase
      .from('posts')
      .insert(postData)
      .select()
      .single();
  
  final post = PostModel.fromJson(response);
  
  // Upload media if provided
  if (mediaFiles != null && mediaFiles.isNotEmpty) {
    await _uploadPostMedia(post.id, mediaFiles);
  }
  
  return post;
}
```

### Messaging Service

#### Send Message
```dart
Future<MessageModel> sendMessage({
  required String conversationId,
  required String content,
  String? replyToId,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw UnauthorizedException();
  
  final messageData = {
    'conversation_id': conversationId,
    'sender_id': user.uid,
    'content': content,
    'message_type': 'text',
    'reply_to': replyToId,
  };
  
  final response = await _supabase
      .from('messages')
      .insert(messageData)
      .select('*, sender:users!inner(*)')
      .single();
  
  return MessageModel.fromJson(response);
}
```

#### Get Conversations
```dart
Future<List<ConversationModel>> getConversations() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw UnauthorizedException();
  
  final response = await _supabase
      .from('conversations')
      .select('''
        *,
        participants:conversation_participants!inner(
          user_id,
          last_read_at,
          user:users!inner(id, name, avatar_url)
        ),
        last_message:messages(
          id,
          content,
          created_at,
          sender:users!inner(name)
        )
      ''')
      .eq('participants.user_id', user.uid)
      .order('updated_at', ascending: false);
  
  return response
      .map((json) => ConversationModel.fromJson(json))
      .toList();
}
```

## UI/UX Guidelines

### Design System

#### Colors
```dart
class AppColors {
  // Logo-inspired orange/yellow color scheme
  static const Color primary = Color(0xFFFF6B35);      // Vibrant orange from logo
  static const Color primarySoft = Color(0xFFFFF4F0);  // Very light orange tint
  static const Color bg = Color(0xFFFFFAF7);           // Warm white background
  static const Color card = Color(0xFFFFFFFF);         // Pure white cards
  static const Color accent = Color(0xFFFFA726);       // Golden yellow from logo
  static const Color accentDark = Color(0xFFE65100);   // Deep orange for emphasis
  static const Color danger = Color(0xFFE53935);       // Error states
  static const Color textPrimary = Color(0xFF1E1E24);  // Dark text
  static const Color textSecondary = Color(0xFF8B4513); // Warm brown secondary text
  static const Color border = Color(0xFFFFDDD4);       // Soft orange-tinted border
  static const Color subtleFill = Color(0xFFFFF7F3);   // Subtle orange fill
}
```

**Color Usage:**
- **Primary Orange**: Main buttons, highlights, brand elements
- **Golden Yellow**: Secondary actions, collaboration features  
- **Deep Orange**: CTAs, investment actions, emphasis
- **Warm Backgrounds**: Cream-white tones complement orange theme
```

#### Typography
```dart
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.0,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );
}
```

#### Spacing
```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

### Component Guidelines

#### Buttons
```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: onPressed,
  child: Text('Primary Action'),
)

// Secondary button  
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: AppColors.primary),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: onPressed,
  child: Text('Secondary Action'),
)
```

#### Cards
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  padding: const EdgeInsets.all(AppSpacing.md),
  child: content,
)
```

#### Input Fields
```dart
TextFormField(
  decoration: InputDecoration(
    hintText: 'Enter text...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.all(AppSpacing.md),
  ),
)
```

### Accessibility

#### Guidelines
- Minimum tap target size: 48x48 pixels
- Color contrast ratio: 4.5:1 for normal text, 3:1 for large text
- Provide semantic labels for screen readers
- Support dynamic text scaling
- Ensure keyboard navigation works

#### Implementation
```dart
// Semantic labels
Semantics(
  label: 'Create new post',
  child: FloatingActionButton(
    onPressed: onPressed,
    child: const Icon(Icons.add),
  ),
)

// Accessible tap targets
InkWell(
  onTap: onTap,
  child: Container(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    alignment: Alignment.center,
    child: icon,
  ),
)
```


## 🔐 Security

### Authentication
- Built on **Supabase Auth** (email/password + OTP).
- **Proactive Security**:
    - **App-side Rate Limiting**: UI catches `429` errors and shows friendly cooldown timer (`SignInPage`).
    - **Password Protection**: Recommend enabling **Attack Protection (Captcha)** in Supabase Dashboard for production to prevent dictionary attacks.
    - **Row Level Security (RLS)**: Enforced on all tables.

### Data Privacy
- **Unified Profile System**: Automatically hides private data (email, phone) when viewing other users' profiles.

## 🔗 Deep Links

The app supports universal links for seamless navigation from web to app.

| Route | Target Page |
|-------|-------------|
| `https://foundervers.com/posts/:id` | `SinglePostFeedPage` (View specific post) |
| `https://foundervers.com/profile/:id` | `UnifiedProfilePage` (View user profile) |

**Configuration:**
- **iOS**: `Runner.entitlements` includes `applinks:foundervers.com`.
- **Android**: `AndroidManifest.xml` handles `android:autoVerify="true"`.
- **Web**: `.well-known/apple-app-site-association` hosted at root.

## 🧪 Testing

### Testing Strategy

#### Unit Tests
Test individual functions and classes in isolation:

```dart
// test/services/post_service_test.dart
void main() {
  group('PostService', () {
    late PostService postService;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      postService = PostService(supabase: mockSupabase);
    });

    test('should return posts when successful', () async {
      // Arrange
      when(mockSupabase.from('posts')).thenReturn(mockQuery);
      when(mockQuery.select(any)).thenReturn(mockQuery);
      when(mockQuery.order(any, ascending: anyNamed('ascending')))
          .thenReturn(mockQuery);
      when(mockQuery.range(any, any)).thenAnswer((_) async => mockPostsData);

      // Act
      final posts = await postService.getPosts();

      // Assert
      expect(posts, hasLength(2));
      expect(posts.first.title, equals('Test Post'));
    });
  });
}
```

#### Widget Tests
Test UI components and user interactions:

```dart
// test/widgets/post_card_test.dart
void main() {
  testWidgets('PostCard displays post information', (tester) async {
    // Arrange
    final post = PostModel(
      id: 1,
      title: 'Test Post',
      description: 'Test Description',
      userId: 'user123',
      createdAt: DateTime.now(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(post: post),
        ),
      ),
    );

    // Assert
    expect(find.text('Test Post'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });
}
```

#### Integration Tests
Test complete user flows:

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('User can create and view a post', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Navigate to create post
      await tester.tap(find.byKey(const Key('create_post_tab')));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(find.byKey(const Key('title_field')), 'Test Post');
      await tester.enterText(find.byKey(const Key('description_field')), 'Test Description');

      // Submit
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Verify post appears in feed
      await tester.tap(find.byKey(const Key('feed_tab')));
      await tester.pumpAndSettle();
      expect(find.text('Test Post'), findsOneWidget);
    });
  });
}
```

### Running Tests

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widgets/

# Run integration tests
flutter test integration_test/

# Run tests with coverage
flutter test --coverage
lcov --summary coverage/lcov.info
```

## 🚀 Deployment

### Build Configuration

#### iOS Build
```bash
# Clean build
flutter clean
flutter pub get

# Build iOS
flutter build ios --release --no-codesign

# Archive in Xcode
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

#### Android Build
```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### Environment Configurations

#### Development
- Firebase Project: `foundervers-dev`
- Supabase Project: Development instance
- Debug mode enabled
- Verbose logging

#### Staging
- Firebase Project: `foundervers-staging`
- Supabase Project: Staging instance
- Release mode with debug symbols
- Performance monitoring

#### Production
- Firebase Project: `foundervers-prod`
- Supabase Project: Production instance
- Full release optimization
- Crash reporting enabled

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build appbundle --release
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.example.mobile_foundervers
          releaseFiles: build/app/outputs/bundle/release/app-release.aab

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --release --no-codesign
      # Additional iOS deployment steps
```

## 🔍 Troubleshooting

### Common Issues

#### Build Errors

**Issue**: `CocoaPods could not find compatible versions`
**Solution**:
```bash
cd ios
rm Podfile.lock
rm -rf Pods/
pod install --repo-update
```

**Issue**: `Android Gradle Plugin version incompatible`
**Solution**:
```gradle
// android/build.gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.0'
}
```

#### Runtime Errors

**Issue**: `Supabase initialization failed`
**Solution**:
1. Check `.env.mobile` file exists and has correct values
2. Verify Supabase URL and anon key are valid
3. Check network connectivity

**Issue**: `Firebase Auth not working`
**Solution**:
1. Verify `google-services.json` and `GoogleService-Info.plist` are present
2. Check bundle ID matches Firebase configuration
3. Enable authentication methods in Firebase Console

#### Database Issues

**Issue**: `Row Level Security denies access`
**Solution**:
1. Check RLS policies are correctly configured
2. Verify user is authenticated with correct UID
3. Test policies in Supabase dashboard

**Issue**: `Query timeout or slow performance`
**Solution**:
1. Add database indexes for filtered columns
2. Use `select()` to limit returned columns
3. Implement pagination with `range()`

### Debug Tools

#### Flutter Inspector
```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

#### Supabase Logs
```sql
-- Enable logging in Supabase
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

-- View recent logs
SELECT * FROM pg_stat_statements 
ORDER BY calls DESC 
LIMIT 10;
```

#### Firebase Debugging
```dart
// Enable Firebase debugging
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: true,
  forceRecaptchaFlow: false,
);
```

### Performance Monitoring

#### App Performance
```dart
// Add performance monitoring
import 'package:firebase_performance/firebase_performance.dart';

final trace = FirebasePerformance.instance.newTrace('post_creation');
trace.start();
// ... perform operation
trace.stop();
```

#### Database Performance
```sql
-- Monitor slow queries
SELECT query, calls, mean_exec_time 
FROM pg_stat_statements 
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC;
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make changes and test thoroughly**
4. **Commit with conventional messages**: `feat: add amazing feature`
5. **Push to your fork**: `git push origin feature/amazing-feature`
6. **Create a Pull Request**

### Code Review Process

1. **Automated checks must pass** (tests, linting, formatting)
2. **At least one review required** from a core maintainer
3. **All conversations must be resolved**
4. **PR description must include**:
   - Summary of changes
   - Testing performed
   - Breaking changes (if any)
   - Screenshots (for UI changes)

### Commit Message Format

```
<type>(<scope>): <description>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix  
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build process or auxiliary tool changes

**Examples**:
```
feat(messaging): add real-time message notifications

- Implement Supabase realtime subscriptions
- Add notification badges to conversation list
- Update message read status in real-time

Closes #123
```

### Release Process

1. **Update version** in `pubspec.yaml`
2. **Update CHANGELOG.md** with release notes
3. **Create release branch**: `release/v1.2.0`
4. **Final testing and bug fixes**
5. **Merge to main and tag release**
6. **Deploy to app stores**

---

## 📄 License

This project is proprietary and confidential. All rights reserved.

## 📞 Support

- **Documentation**: [Internal Wiki](https://wiki.company.com/foundervers-mobile)
- **Bug Reports**: [GitHub Issues](https://github.com/soyRex-codes/mobile_app_foundervers/issues)
- **Feature Requests**: [Product Board](https://productboard.company.com)
- **Technical Support**: dev-support@company.com

---

**Last Updated**: August 26, 2025
**Version**: 1.0.0
**Maintainers**: Development Team

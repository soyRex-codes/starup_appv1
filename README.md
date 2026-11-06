# Terai web

Current deployment: **https://terai.us**. Editable Flutter source is in `lib/`, web configuration is in `web/`, and backend source is in `supabase/`.

See [current setup and deployment instructions](docs/DEPLOYMENT.md) and [repository contribution workflow](AGENTS.md). The sections below are retained historical documentation from FounderVers; use the current guide for builds and deployment.

---

# FounderVers Mobile App - Developer Documentation

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-blue.svg)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green.svg)](https://supabase.com)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

*A comprehensive mobile-first platform connecting founders, entrepreneurs, and startup enthusiasts with real-time messaging, media sharing, and advanced caching systems.*

## Installation & Setup

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Dart SDK 3.4.0 or higher
- Android Studio / VS Code with Flutter extensions
- Git
- Supabase account (for backend services)

### Quick Start
1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd starup_appv1
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase Backend:**
   - Create a new Supabase project at [supabase.com](https://supabase.com)
   - Navigate to Settings -> API to find your project URL and anon key
   - Update your environment configuration with Supabase credentials
   - Run the database schema: `scripts/apply_schema.sh`

4. **Set up database:**
   ```bash
   # Apply the complete 540-line schema
   chmod +x scripts/apply_schema.sh
   ./scripts/apply_schema.sh
   ```

5. **Configure authentication:**
   - Enable email authentication in Supabase Dashboard
   - Configure email templates for password reset
   - Set up RLS (Row Level Security) policies (included in schema)

6. **Run the application:**
   ```bash
   # Development mode
   flutter run --debug
   
   # Release mode for testing
   flutter run --release
   ```

### Additional Configuration

#### Performance Optimization
The app includes sophisticated caching and performance optimizations:
- Feed cache automatically adapts to device capability (30-75 entries)
- Smart TTL based on content type (2-8 minutes)
- LRU eviction with 70%+ hit rate

#### Real-time Features
Real-time messaging requires WebSocket connections:
- Automatically handled by Supabase Realtime
- No additional configuration needed
- Supports real-time message delivery and read receipts

#### Development Tools
```bash
# Run tests
flutter test

# Build for distribution
chmod +x scripts/build_and_distribute.sh
./scripts/build_and_distribute.sh

# Database migrations
chmod +x scripts/migrate_db.sh
./scripts/migrate_db.sh
```

**Current Version**: 1.0.0+1 | **Last Updated**: September 23, 2025

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

- **Post Creation & Management**: Full CRUD operations with media support (images/videos up to 50MB)
- **Categorized Feed**: Browse posts by categories with intelligent caching system (70%+ hit rate)
- **Goal-Based Filtering**: Filter by funding, partnership, hiring, and custom goals
- **Advanced Search**: Real-time search with caching optimization
- **User Profiles**: Complete profile management with avatar support
- **Real-time Messaging**: Direct messaging with typing indicators and read receipts
- **Global Chat**: Real-time founder community discussions
- **Ecosystem Applications**: Business services portal with professional service connections
- **Suggestion System**: Simplified read/unread inbox for user feedback
- **Email Notifications**: Production-ready email system for business applications
- **Secure Authentication**: Password reset with OTP verification system
- **Modern UI**: Material Design 3 with logo-inspired orange/yellow brand theme
- **Performance**: Advanced caching system, database optimization, smart TTL
- **Mobile-First**: Optimized navigation with Feed -> Ecosystem -> Create -> Global -> DMs layout
- **Security**: Row Level Security (RLS) policies and secure data handling

### Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
| **Framework** | Flutter | 3.24.0+ |
| **Language** | Dart | 3.4.0+ |
| **Backend** | Supabase | Complete BaaS |
| **Database** | PostgreSQL | 15+ (via Supabase) |
| **Authentication** | Supabase Auth | Email/Password + OTP |
| **Storage** | Supabase Storage | Media files up to 50MB |
| **Real-time** | Supabase Realtime | WebSocket subscriptions |
| **Caching** | Custom LRU Cache | Adaptive sizing |
| **State Management** | Provider + setState | Reactive patterns |
| **Navigation** | Flutter Navigator | Material transitions |
| **Testing** | Flutter Test | Unit + Integration |
| **Security** | Row Level Security | Database-level policies |

## Architecture

### Project Structure

```
lib/
├── app/                              # App-wide configuration
│   ├── auth_gate.dart               # Authentication routing
│   ├── home_page.dart               # Main navigation hub
│   └── theme.dart                   # Material Design 3 theme
├── core/                            # Core utilities & infrastructure
│   ├── cache/                       # Caching system
│   │   └── feed_cache.dart         # Smart LRU cache with TTL
│   └── supabase_client.dart        # Database client wrapper
├── features/                        # Feature modules (13 modules)
│   ├── auth/                        # Authentication & onboarding
│   ├── feed/                        # Post feed with caching
│   ├── ecosystem/                   # Business services portal
│   ├── dm/                          # Direct messaging system
│   ├── post_creation/               # Post CRUD operations
│   ├── profile/                     # User profile management
│   ├── Global_public_chat-for_founders/ # Community chat
│   ├── messaging/                   # Message composition UI
│   ├── notifications/               # Push notification handling
│   ├── settings/                    # App configuration
│   ├── suggestions/                 # Simplified feedback system
│   ├── about/                       # App information
│   └── help_support/               # User support
├── models/                          # Data models & DTOs
├── services/                        # Business logic services
│   ├── password_reset_service.dart  # Secure OTP system
│   ├── deep_link_service.dart      # App linking
│   ├── share_service.dart          # Social sharing
│   └── supa.dart                   # Supabase client helper
├── widgets/                         # Reusable UI components
└── main.dart                       # App entry point
```

### Navigation Structure

The app features a bottom navigation bar with optimized UX flow:

```
Feed -> Ecosystem -> Create -> Global -> DMs
 |        |         |        |      |
Posts   Business  Content  Chat   Messages
        Services  Creation
```

**Navigation Details:**
- **Feed** (Index 0): Main post feed with caching
- **Ecosystem** (Index 1): Business services portal - moved for better accessibility  
- **Create** (Center): Post creation - always accessible
- **Global** (Index 2): Community chat for all founders
- **DMs** (Index 3): Direct messaging with unread badges - positioned last for focused communication

### Architecture Patterns

- **Feature-First**: Code organized by business features, not technical layers
- **Clean Architecture**: Clear separation of concerns and dependency inversion
- **Service Layer**: Centralized business logic with dependency injection
- **Cache-Aside Pattern**: Intelligent caching with LRU eviction and smart TTL
- **Repository Pattern**: Data access abstraction with error handling
- **Observer Pattern**: Real-time updates via Supabase subscriptions

### Data Flow

```
UI Components -> Cache Layer -> Services -> Supabase Client -> PostgreSQL Database
     ^              ^            ^           ^                    ^
   State      LRU Cache    Models    Real-time       Row Level Security
                           ^                              ^
                    Feed Cache              Security Policies
                  (70%+ hit rate)          (User isolation)
```

### Performance Architecture

- **Multi-Layer Caching**: Memory cache -> Disk cache -> Database
- **Adaptive Cache Sizing**: Based on device capability (30-75 entries)
- **Smart TTL**: Content-aware expiration (search: 2min, trending: 3min, category: 8min)
- **Connection Pooling**: Optimized database connection management
- **Real-time Optimization**: Efficient subscription management

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

**Current Schema**: 540 lines | **Tables**: 8 core tables | **Indexes**: 12 optimized indexes | **Functions**: 8 helper functions

### Core Tables

#### Users (Authentication & Profiles)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT,                              -- No unique constraint for upsert flexibility
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

#### Posts (Content Management)
```sql
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT,                               -- Author display name
  category TEXT,                           -- Tech, Business, Healthcare, etc.
  title TEXT NOT NULL,
  description TEXT,
  funding_goal NUMERIC,
  post_goal TEXT DEFAULT 'funding',        -- funding, partnership, hiring, etc.
  post_goal_description TEXT,
  email TEXT,                              -- Contact email
  moderation_status TEXT DEFAULT 'approved',
  status TEXT DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Media (File Storage)
```sql
CREATE TABLE media (
  id BIGSERIAL PRIMARY KEY,
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  type TEXT DEFAULT 'image',               -- image, video, document
  filename TEXT,
  original_name TEXT,
  file_path TEXT,                          -- Supabase Storage path
  file_size BIGINT,                        -- Max 50MB
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Messaging System (Real-time Communication)
```sql
-- Conversations
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT DEFAULT 'direct',              -- direct, group, public
  title TEXT,
  created_by UUID REFERENCES users(id),
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Participants (Many-to-Many)
CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,                     -- NULL = active participant
  last_read_at TIMESTAMPTZ,
  UNIQUE(conversation_id, user_id)
);

-- Messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',        -- text, image, file
  reply_to UUID REFERENCES messages(id),
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message Status (Read Receipts)
CREATE TABLE message_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'sent',              -- sent, delivered, read
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);
```

#### Additional Tables
```sql
-- Global Public Chat
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Suggestions System (Simplified Read/Unread)
CREATE TABLE suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  suggester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  suggestion_type TEXT NOT NULL,           -- feature, improvement, concept, other
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,           -- Simplified boolean read status
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Password Reset System (Secure OTP)
CREATE TABLE password_reset_otps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  otp_hash TEXT NOT NULL,                  -- Hashed OTP (never store plain text)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ NULL,
  is_used BOOLEAN DEFAULT FALSE,
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3
);
```

### Database Optimizations

#### Strategic Indexes
```sql
-- High-traffic query optimization
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_category ON posts(category);
CREATE INDEX idx_posts_created_desc ON posts(created_at DESC);
CREATE INDEX idx_media_post ON media(post_id);
CREATE INDEX idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_desc ON messages(created_at DESC);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);
-- + 4 more specialized indexes
```

#### Helper Functions
```sql
-- Prevent RLS recursion
CREATE FUNCTION is_conversation_member_safe(UUID, UUID) RETURNS BOOLEAN SECURITY DEFINER;

-- User management
CREATE FUNCTION ensure_user_exists(UUID, TEXT, TEXT) RETURNS VOID SECURITY DEFINER;

-- Messaging helpers
CREATE FUNCTION get_or_create_direct_conversation(UUID, UUID) RETURNS UUID SECURITY DEFINER;

-- Cleanup functions
CREATE FUNCTION cleanup_expired_password_reset_otps() RETURNS VOID SECURITY DEFINER;
-- + 4 more utility functions
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

**Current Services**: 6 core services | **Cache Integration**: Feed caching | **Real-time**: WebSocket subscriptions

### Authentication (Supabase Auth Only)

#### Password Reset with OTP
```dart
class PasswordResetService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Step 1: Request OTP
  Future<void> requestPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: null, // Mobile app handles OTP directly
    );
  }
  
  // Step 2: Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: otp,
        email: email,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Step 3: Update Password
  Future<void> resetPassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
```

#### User Authentication
```dart
// Sign in with email/password
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Auto-upsert user profile
await Supabase.instance.client.rpc('ensure_user_exists', params: {
  'p_uid': response.user!.id,
  'p_email': response.user!.email,
  'p_name': response.user!.userMetadata?['name'],
});
```

### Post Service (with Feed Caching)

#### Create Post
```dart
class PostService {
  final SupabaseClient _s = Supa.client;
  
  Future<int> createPost({
    required String userId,
    required String authorName,
    required String title,
    String? description,
    String? category,
    num? fundingGoal,
    String? postGoal,
    String? email,
  }) async {
    // Ensure user exists (defensive programming)
    await _ensureUserExists(uid: userId, email: email, name: authorName);
    
    final insert = await _s.from('posts').insert({
      'user_id': userId,
      'name': authorName,
      'title': title,
      'description': description,
      'category': category,
      'funding_goal': fundingGoal,
      'post_goal': postGoal,
      'email': email,
    }).select('id,updated_at').limit(1);
    
    final postId = (insert.first['id'] as num).toInt();
    
    // Invalidate feed cache after successful creation
    FeedService().invalidateCache();
    
    return postId;
  }
  
  // Media upload with 50MB limit
  Future<String> uploadMediaBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await _s.storage.from(bucket).uploadBinary(
      path, bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return path;
  }
}
```

### Feed Service (with Smart Caching)

#### Fetch Posts with Cache
```dart
class FeedService {
  final FeedCache _cache = FeedCache.instance;
  
  Future<List<PostModel>> fetchPosts({
    String? category,
    String? goal,
    String? search,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless forcing refresh)
    if (!forceRefresh) {
      final cached = _cache.get(
        category: category, goal: goal, search: search, offset: offset,
      );
      if (cached != null) return cached;
    }
    
    // Database query with joins
    var q = _s.from('posts').select(
      'id,user_id,name,category,title,description,funding_goal,post_goal,created_at,media:media(*)',
    );
    
    // Apply filters
    if (category != null) q = q.eq('category', category);
    if (goal != null) q = q.eq('post_goal', goal);
    if (search != null) {
      q = q.or('title.ilike.%$search%,description.ilike.%$search%');
    }
    
    final response = await q
        .eq('status', 'published')
        .eq('moderation_status', 'approved')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    final posts = response.map((r) => PostModel.fromJson(r)).toList();
    
    // Cache the results
    _cache.put(
      category: category, goal: goal, search: search,
      offset: offset, posts: posts,
    );
    
    return posts;
  }
}
```

### Messaging Service (Real-time)

#### Direct Messaging with Real-time
```dart
class DMService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Get or create conversation
  Future<Conversation?> getOrCreateDirectConversation(String otherUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    
    final result = await _supabase.rpc('get_or_create_direct_conversation', params: {
      'user1_id': currentUserId,
      'user2_id': otherUserId,
    });
    
    final conversationId = result as String;
    return await _getConversationById(conversationId);
  }
  
  // Send message with optimistic updates
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    
    final response = await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'content': content,
      'message_type': type.toString().split('.').last,
    }).select('*, sender_profile:users(id, username, full_name, avatar_url)').single();
    
    return Message.fromJson(response);
  }
  
  // Real-time subscription
  void subscribeToMessages(String conversationId) {
    _supabase.channel('messages_$conversationId')
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
  }
}
```

### Cache System (Performance Optimization)

#### Smart Feed Cache
```dart
class FeedCache {
  static final FeedCache instance = FeedCache._();
  
  // Adaptive cache sizing based on device capability
  int get _adaptiveMaxSize {
    final processorCount = Platform.numberOfProcessors;
    if (processorCount >= 8) return 75;      // High-end: 75 entries
    else if (processorCount >= 4) return 50; // Mid-range: 50 entries
    else return 30;                          // Low-end: 30 entries
  }
  
  // Smart TTL based on content type
  Duration _getSmartTTL(String? category, String? search) {
    if (search != null) return Duration(minutes: 2);      // Search: 2min
    if (category == 'trending') return Duration(minutes: 3); // Trending: 3min
    return Duration(minutes: 8);                           // Category: 8min
  }
  
  // Get with LRU eviction
  List<PostModel>? get({String? category, String? goal, String? search, int offset = 0}) {
    final key = _generateKey(category: category, goal: goal, search: search, offset: offset);
    final cached = _cache.remove(key);
    
    if (cached == null) {
      _misses++;
      return null;
    }
    
    // Check expiration
    if (DateTime.now().difference(cached.timestamp) > _getSmartTTL(category, search)) {
      _misses++;
      return null;
    }
    
    _cache[key] = cached; // Re-add for LRU
    _hits++;
    return cached.posts;
  }
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

## Testing & Quality Assurance

### Comprehensive Test Suite
The app maintains high-quality standards through extensive testing:

#### Test Coverage Overview
```
test/
├── cache_integration_test.dart     # Cache performance & LRU eviction tests
├── dm_service_test.dart           # Direct messaging & real-time tests  
├── feed_cache_test.dart           # Feed cache unit tests (TTL, sizing)
├── feed_cache_unit_test.dart      # Additional cache behavior tests
├── feed_service_test.dart         # Feed service with Supabase integration
├── post_service_test.dart         # Post CRUD operations
├── test_database_schema.dart      # Database schema validation
└── widget_test.dart               # UI component tests
```

#### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage report
flutter test --coverage

# Run specific test suites
flutter test test/feed_cache_test.dart          # Cache system
flutter test test/dm_service_test.dart          # Messaging
flutter test test/cache_integration_test.dart   # Integration tests
```

#### Unit Testing Example
```dart
// test/feed_cache_test.dart
void main() {
  group('FeedCache LRU Eviction', () {
    late FeedCache cache;

    setUp(() {
      cache = FeedCache.instance;
      cache.clear();
    });

    test('should evict oldest entries when cache is full', () {
      // Fill cache to max capacity
      for (int i = 0; i < cache.maxSize; i++) {
        cache.put(category: 'test$i', offset: 0, posts: []);
      }

      // Add one more entry (should trigger eviction)
      cache.put(category: 'newest', offset: 0, posts: []);

      // Verify oldest entry was evicted
      expect(cache.get(category: 'test0', offset: 0), isNull);
      expect(cache.get(category: 'newest', offset: 0), isNotNull);
    });

    test('should achieve 70%+ hit rate under realistic load', () {
      // Simulate realistic usage pattern
      cache.simulateUsage(requests: 1000);
      
      expect(cache.hitRate, greaterThan(0.70));
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

## Deployment

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
# Product -> Archive -> Distribute App
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

## Troubleshooting

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

## Contributing

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

## License

This project is proprietary and confidential. All rights reserved.

## Support

- **Documentation**: [Internal Wiki](https://wiki.company.com/foundervers-mobile)
- **Bug Reports**: [GitHub Issues](https://github.com/soyRex-codes/mobile_app_foundervers/issues)
- **Feature Requests**: [Product Board](https://productboard.company.com)
- **Technical Support**: dev-support@company.com

---

**Last Updated**: August 26, 2025
**Version**: 1.0.0
**Maintainers**: Development Team

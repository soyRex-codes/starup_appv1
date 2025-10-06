# API Documentation - FounderVers Mobile

*Last Updated: September 23, 2025*

## 📋 Overview

This document provides comprehensive API documentation for the FounderVers mobile application. The app uses **Supabase** as the complete Backend-as-a-Service solution, handling authentication, database operations, real-time subscriptions, and file storage.

## 🚀 Current Status

### ✅ **Production-Ready APIs**
- **Authentication**: Fully operational with OTP verification
- **Post Management**: Complete CRUD operations with media support
- **Messaging System**: Real-time DMs with typing indicators
- **Email Notifications**: Production Gmail SMTP integration
- **Suggestions API**: Simplified read/unread operations
- **Feed Caching**: Advanced LRU cache with 70%+ hit rate
- **Global Chat**: Real-time community messaging

### 📱 **Navigation API**
Current navigation structure: **Feed → Ecosystem → Create → Global → DMs**
- All tab transitions properly handled
- State management across navigation maintained
- Unread message badges working correctly

## 🏗️ Architecture Overview

- **Frontend**: Flutter 3.24+ with Material Design 3
- **Backend**: Supabase (PostgreSQL 15+ database)
- **Authentication**: Supabase Auth with email/password and OTP
- **Real-time**: Supabase Realtime WebSocket subscriptions
- **Caching**: Custom LRU cache with adaptive sizing (70%+ hit rate)
- **Database**: 540-line schema with 8 core tables and optimized indexes

## 🔐 Authentication API

### AuthService (Supabase-based)

The `AuthService` handles all authentication operations using Supabase Auth.

#### Core Methods

##### `signInWithEmailAndPassword(String email, String password)`

**Description**: Authenticates user with email and password via Supabase Auth.

**Parameters**:
- `email` (String): User's email address
- `password` (String): User's password

**Returns**: `Future<AuthResponse>` - Supabase auth response with user data

**Example**:
```dart
final response = await authService.signInWithEmailAndPassword(
  'user@example.com', 
  'password123'
);

if (response.user != null) {
  // Success - user is authenticated
  final userId = response.user!.id;
}
```

**Throws**:
- `AuthException`: Authentication failed (invalid credentials, etc.)
- `NetworkException`: Network connectivity issues

##### `signUpWithEmailAndPassword(String email, String password)`

**Description**: Creates new user account with Supabase Auth.

**Parameters**:
- `email` (String): User's email address  
- `password` (String): User's password (min 8 characters)

**Returns**: `Future<AuthResponse>` - Supabase auth response

**Example**:
```dart
final response = await authService.signUpWithEmailAndPassword(
  'newuser@example.com', 
  'securePassword123'
);

// Check if email confirmation is required
if (response.user != null && response.user!.emailConfirmedAt != null) {
  // User created successfully and email confirmed
}

##### `signOut()`

**Description**: Signs out the current user from Supabase.

**Returns**: `Future<void>`

**Example**:
```dart
await authService.signOut();
// User is now logged out
```

##### `getCurrentUser()`

**Description**: Gets the currently authenticated user from Supabase.

**Returns**: `User?` - Current Supabase User or null

**Example**:
```dart
final currentUser = authService.getCurrentUser();
if (currentUser != null) {
  print('User ID: ${currentUser.id}');
  print('Email: ${currentUser.email}');
}
```

### Password Reset System (OTP-based)

#### `resetPassword(String email)`

**Description**: Initiates password reset with OTP via PasswordResetService.

**Parameters**:
- `email` (String): User's email address

**Returns**: `Future<bool>` - Success status

**Example**:
```dart
final success = await authService.resetPassword('user@example.com');
if (success) {
  // OTP sent to email - redirect to OTP verification screen
}
```

#### `verifyOtpAndResetPassword(String email, String otp, String newPassword)`

**Description**: Verifies OTP and sets new password.

**Parameters**:
- `email` (String): User's email address
- `otp` (String): 6-digit OTP from email
- `newPassword` (String): New password (min 8 characters)

**Returns**: `Future<bool>` - Success status

**Example**:
```dart
final success = await authService.verifyOtpAndResetPassword(
  'user@example.com',
  '123456',
  'newSecurePassword123'
);
```

### User Profile Management

#### `createUserProfile(String userId, Map<String, dynamic> profileData)`

**Description**: Creates user profile record in Supabase database.

**Parameters**:
- `userId` (String): Supabase user ID
- `profileData` (Map): Profile information (username, full_name, etc.)

**Returns**: `Future<void>`

**Example**:
```dart
await authService.createUserProfile(userId, {
  'username': 'john_founder',
  'full_name': 'John Smith',
  'bio': 'Tech entrepreneur',
  'avatar_url': 'https://example.com/avatar.jpg'
});
```

## 📱 Feed Service API (with Smart Caching)

### FeedService

The `FeedService` handles post fetching with sophisticated caching and filtering capabilities.

#### Core Methods

##### `fetchPosts({String? category, String? goal, String? search, int limit = 20, int offset = 0, bool forceRefresh = false})`

**Description**: Fetches posts with intelligent caching and filtering.

**Parameters**:
- `category` (String?): Post category filter ('startup', 'investment', etc.)
- `goal` (String?): Post goal filter ('funding', 'networking', etc.)
- `search` (String?): Search query for title/description
- `limit` (int): Number of posts to fetch (default: 20)
- `offset` (int): Pagination offset (default: 0)
- `forceRefresh` (bool): Bypass cache and fetch fresh data

**Returns**: `Future<List<PostModel>>` - List of posts

**Caching Behavior**:
- **Cache Hit**: Returns cached data if available and not expired
- **TTL**: 2min (search), 3min (trending), 8min (category)
- **LRU Eviction**: Automatically manages cache size (30-75 entries)

**Example**:
```dart
// Fetch trending posts (uses cache)
final trendingPosts = await feedService.fetchPosts(
  category: 'trending',
  limit: 10
);

// Search posts (bypasses cache for fresh results)
final searchResults = await feedService.fetchPosts(
  search: 'AI startup',
  forceRefresh: true
);

// Paginated fetch
final morePosts = await feedService.fetchPosts(
  category: 'startup',
  offset: 20,
  limit: 20
);
```

##### `refreshFeed()`

**Description**: Clears cache and fetches fresh feed data.

**Returns**: `Future<List<PostModel>>`

**Example**:
```dart
final freshPosts = await feedService.refreshFeed();
```

### Cache Performance Metrics

The feed cache achieves high performance:
- **Hit Rate**: 70%+ under normal usage
- **Adaptive Sizing**: 30-75 entries based on device capability
- **Smart TTL**: Content-aware expiration times
- **LRU Eviction**: Removes least recently used entries

## 📝 Post Service API

### PostService

Handles CRUD operations for posts with media support.

#### Core Methods

##### `createPost(CreatePostModel postData)`
##### `createPost(PostCreateRequest postData)`

**Description**: Creates a new post with optional media attachments.

**Parameters**:
- `postData` (CreatePostModel): Post creation data

**Returns**: `Future<PostModel>` - Created post

**Example**:
##### `updatePost(String postId, UpdatePostModel updates)`

**Description**: Updates an existing post.

**Parameters**:
- `postId` (String): Post ID to update
- `updates` (UpdatePostModel): Fields to update

**Returns**: `Future<PostModel>` - Updated post

##### `deletePost(String postId)`

**Description**: Deletes a post (soft delete with status change).

**Parameters**:
- `postId` (String): Post ID to delete

**Returns**: `Future<void>`

## 💬 Messaging Service API (Real-time)

### DMService (Direct Messaging)

Handles one-on-one messaging with real-time capabilities.

#### Core Methods

##### `getOrCreateDirectConversation(String otherUserId)`

**Description**: Gets existing conversation or creates new one between users.

**Parameters**:
- `otherUserId` (String): ID of the other user

**Returns**: `Future<Conversation?>` - Conversation object

**Example**:
```dart
##### `getOrCreateDirectConversation(String otherUserId)`

**Description**: Gets existing conversation or creates new one between users.

**Parameters**:
- `otherUserId` (String): ID of the other user

**Returns**: `Future<ConversationModel>` - Conversation object

**Example**:
**Example**:
```dart
final message = await dmService.sendMessage(
  conversationId: 'conv_123',
  content: 'Hey! Interested in your startup idea.',
  type: MessageType.text,
);
```

##### `subscribeToMessages(String conversationId)`

**Description**: Subscribes to real-time message updates for a conversation.

**Parameters**:
- `conversationId` (String): Conversation to monitor

**Returns**: `void` - Sets up real-time subscription

**Example**:
```dart
// Set up real-time message listening
dmService.subscribeToMessages('conv_123');

// Handle incoming messages via stream
dmService.messageStream.listen((Message newMessage) {
  // Update UI with new message
  setState(() {
##### `subscribeToMessages(String conversationId, Function(MessageModel) onMessage)`

**Description**: Subscribes to real-time message updates for a conversation.

**Parameters**:
- `conversationId` (String): Conversation to monitor

**Returns**: `RealtimeSubscription` - Subscription handle for cleanup

**Example**:
    ).subscribe();
}
```

## 🗄️ Database Schema API

### Core Tables

The database uses a comprehensive 540-line PostgreSQL schema with optimized indexes and Row Level Security (RLS) policies. The schema includes eight core tables that handle all application functionality:

**Core Tables:**
- **`users`** - User profiles and authentication data
- **`posts`** - Startup posts with funding goals and categorization  
- **`media`** - File attachments for posts (images, videos, documents)
- **`conversations`** - Message conversation containers
- **`messages`** - Individual messages within conversations
- **`conversation_participants`** - User participation in conversations
- **`suggestions`** - User feedback with simplified read/unread status
- **`password_reset_otps`** - Secure OTP tokens for password reset

Each table includes proper indexing, foreign key constraints, and RLS policies for data security and optimal query performance.

## 📝 Posts API

### PostService

The `PostService` handles all post-related operations including creation, reading, updating, and deletion.

#### Data Models

##### PostModel
```dart
class PostModel {
  final int id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final String? postGoal;
  final String? postGoalDescription;
  final double? fundingGoal;
  final String moderationStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PostMedia> media;
  final UserProfile? author;
}
```

##### PostMedia
```dart
class PostMedia {
  final int id;
  final int postId;
  final String type;
  final String? filename;
  final String? originalName;
  final String? filePath;
  final int? fileSize;
  final DateTime uploadedAt;
}
```

#### Methods

##### `getPosts({int limit, int offset, String? category, String? goal})`

**Description**: Retrieves paginated list of posts with optional filtering.

**Parameters**:
- `limit` (int): Maximum number of posts to return (default: 20)
- `offset` (int): Number of posts to skip (default: 0)
- `category` (String?): Filter by category
- `goal` (String?): Filter by post goal

**Returns**: `Future<List<PostModel>>`

**Example**:
```dart
final posts = await postService.getPosts(
  limit: 10,
  offset: 0,
  category: 'technology',
  goal: 'funding'
);
```

**Database Query**:
```sql
SELECT 
  p.*,
  json_agg(m.*) as media,
  json_build_object('id', u.id, 'name', u.name, 'avatar_url', u.avatar_url) as author
FROM posts p
LEFT JOIN media m ON p.id = m.post_id
INNER JOIN users u ON p.user_id = u.id
WHERE p.status = 'published' 
  AND p.moderation_status = 'approved'
  AND ($3::text IS NULL OR p.category = $3)
  AND ($4::text IS NULL OR p.post_goal = $4)
GROUP BY p.id, u.id, u.name, u.avatar_url
ORDER BY p.created_at DESC
LIMIT $1 OFFSET $2;
```

##### `getPostById(int id)`

**Description**: Retrieves a single post by ID.

**Parameters**:
- `id` (int): Post ID

**Returns**: `Future<PostModel?>`

**Example**:
```dart
final post = await postService.getPostById(123);
```

##### `createPost(PostCreateRequest request)`

**Description**: Creates a new post with optional media uploads.

**Parameters**:
- `request` (PostCreateRequest): Post creation data

**PostCreateRequest Model**:
```dart
class PostCreateRequest {
  final String title;
  final String? description;
  final String? category;
  final String? postGoal;
  final String? postGoalDescription;
  final double? fundingGoal;
  final List<XFile>? mediaFiles;
}
```

**Returns**: `Future<PostModel>`

**Example**:
```dart
final post = await postService.createPost(PostCreateRequest(
  title: 'My Startup Idea',
  description: 'A revolutionary app that...',
  category: 'technology',
  postGoal: 'funding',
  fundingGoal: 100000.0,
  mediaFiles: [imageFile1, imageFile2],
));
```

**Database Operations**:
1. Insert post record
2. Upload media files to Supabase Storage
3. Insert media records
4. Return complete post with media

##### `updatePost(int id, PostUpdateRequest request)`

**Description**: Updates an existing post.

**Parameters**:
- `id` (int): Post ID
- `request` (PostUpdateRequest): Update data

**Returns**: `Future<PostModel>`

**Example**:
```dart
final updatedPost = await postService.updatePost(123, PostUpdateRequest(
  title: 'Updated Title',
  description: 'Updated description',
));
```

##### `deletePost(int id)`

**Description**: Deletes a post and associated media.

**Parameters**:
- `id` (int): Post ID

**Returns**: `Future<void>`

**Example**:
```dart
await postService.deletePost(123);
```

**Operations**:
1. Delete media files from storage
2. Delete media records (CASCADE)
3. Delete post record

##### `searchPosts(String query, {int limit, int offset})`

**Description**: Searches posts by title and description.

**Parameters**:
- `query` (String): Search query
- `limit` (int): Maximum results (default: 20)
- `offset` (int): Offset for pagination (default: 0)

**Returns**: `Future<List<PostModel>>`

**Example**:
```dart
final results = await postService.searchPosts('AI startup');
```

## 💬 Messaging API

### DMService

The `DMService` handles direct messaging functionality including conversations and messages.

#### Data Models

##### ConversationModel
```dart
class ConversationModel {
  final String id;
  final String type;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
}
```

##### MessageModel
```dart
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final String? replyTo;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final UserProfile? sender;
}
```

##### ConversationParticipant
```dart
class ConversationParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final DateTime lastReadAt;
  final UserProfile user;
}
```

#### Methods

##### `getConversations()`

**Description**: Retrieves all conversations for the current user.

**Returns**: `Future<List<ConversationModel>>`

**Example**:
```dart
final conversations = await dmService.getConversations();
```

**Database Query**:
```sql
SELECT 
  c.*,
  json_agg(DISTINCT p.*) as participants,
  (SELECT row_to_json(m.*) FROM (
    SELECT m.*, row_to_json(u.*) as sender
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) m) as last_message
FROM conversations c
JOIN conversation_participants cp ON c.id = cp.conversation_id
JOIN conversation_participants p ON c.id = p.conversation_id
JOIN users u ON p.user_id = u.id
WHERE cp.user_id = $1
GROUP BY c.id
ORDER BY c.updated_at DESC;
```

##### `getOrCreateDirectConversation(String otherUserId)`

**Description**: Gets existing conversation or creates new direct conversation.

**Parameters**:
- `otherUserId` (String): ID of the other user

**Returns**: `Future<ConversationModel>`

**Example**:
```dart
final conversation = await dmService.getOrCreateDirectConversation('user123');
```

**Database Function Call**:
```sql
SELECT get_or_create_direct_conversation($1, $2);
```

##### `getMessages(String conversationId, {int limit, int offset})`

**Description**: Retrieves messages for a conversation.

**Parameters**:
- `conversationId` (String): Conversation ID
- `limit` (int): Maximum messages (default: 50)
- `offset` (int): Offset for pagination (default: 0)

**Returns**: `Future<List<MessageModel>>`

**Example**:
```dart
final messages = await dmService.getMessages('conv-123', limit: 20);
```

##### `sendMessage(String conversationId, String content, {String? replyToId})`

**Description**: Sends a message in a conversation.

**Parameters**:
- `conversationId` (String): Conversation ID
- `content` (String): Message content
- `replyToId` (String?): ID of message being replied to

**Returns**: `Future<MessageModel>`

**Example**:
```dart
final message = await dmService.sendMessage(
  'conv-123', 
  'Hello there!',
  replyToId: 'msg-456'
);
```

##### `markConversationAsRead(String conversationId)`

**Description**: Marks all messages in conversation as read.

**Parameters**:
- `conversationId` (String): Conversation ID

**Returns**: `Future<void>`

**Example**:
```dart
await dmService.markConversationAsRead('conv-123');
```

##### `subscribeToMessages(String conversationId, Function(MessageModel) onMessage)`

**Description**: Subscribes to real-time messages in a conversation.

**Parameters**:
- `conversationId` (String): Conversation ID
- `onMessage` (Function): Callback for new messages

**Returns**: `RealtimeSubscription`

**Example**:
```dart
final subscription = dmService.subscribeToMessages('conv-123', (message) {
  print('New message: ${message.content}');
});

// Don't forget to cancel
subscription.unsubscribe();
```

## 👤 Profile API

### UserService

The `UserService` handles user profile operations and user discovery.

#### Data Models

##### UserProfile
```dart
class UserProfile {
  final String id;
  final String? email;
  final String? name;
  final String? username;
  final String? fullName;
  final String? bio;
  final String? company;
  final String? location;
  final String? avatarUrl;
  final bool emailVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Methods

##### `getUserProfile(String userId)`

**Description**: Retrieves user profile by ID.

**Parameters**:
- `userId` (String): User ID

**Returns**: `Future<UserProfile?>`

**Example**:
```dart
final profile = await userService.getUserProfile('user123');
```

##### `updateProfile(UserProfile profile)`

**Description**: Updates current user's profile.

**Parameters**:
- `profile` (UserProfile): Updated profile data

**Returns**: `Future<UserProfile>`

**Example**:
```dart
final updatedProfile = await userService.updateProfile(
  profile.copyWith(name: 'New Name', bio: 'Updated bio')
);
```

##### `searchUsers(String query, {int limit})`

**Description**: Searches for users by name or email.

**Parameters**:
- `query` (String): Search query
- `limit` (int): Maximum results (default: 20)

**Returns**: `Future<List<UserProfile>>`

**Example**:
```dart
final users = await userService.searchUsers('john doe');
```

##### `getUserStats(String userId)`

**Description**: Gets user statistics (posts count, etc.).

**Parameters**:
- `userId` (String): User ID

**Returns**: `Future<UserStats>`

**UserStats Model**:
```dart
class UserStats {
  final int totalPosts;
  final int totalConversations;
  final Map<String, int> goalBreakdown;
  final DateTime memberSince;
}
```

**Example**:
```dart
final stats = await userService.getUserStats('user123');
```

## 🔍 Search API

### SearchService

The `SearchService` provides unified search across posts and users.

#### Methods

##### `searchAll(String query, {SearchFilters? filters})`

**Description**: Searches across all content types.

**Parameters**:
- `query` (String): Search query
- `filters` (SearchFilters?): Optional search filters

**SearchFilters Model**:
```dart
class SearchFilters {
  final List<String>? categories;
  final List<String>? goals;
  final String? contentType; // 'posts', 'users', 'all'
  final DateRange? dateRange;
}
```

**Returns**: `Future<SearchResults>`

**SearchResults Model**:
```dart
class SearchResults {
  final List<PostModel> posts;
  final List<UserProfile> users;
  final int totalResults;
  final bool hasMore;
}
```

**Example**:
```dart
final results = await searchService.searchAll(
  'AI startup',
  filters: SearchFilters(
    categories: ['technology'],
    goals: ['funding'],
    contentType: 'posts',
  )
);
```

## 📊 Analytics API

### AnalyticsService

The `AnalyticsService` tracks user interactions and app usage.

#### Methods

##### `trackEvent(String eventName, Map<String, dynamic> parameters)`

**Description**: Tracks custom events.

**Parameters**:
- `eventName` (String): Event name
- `parameters` (Map): Event parameters

**Example**:
```dart
await analyticsService.trackEvent('post_created', {
  'category': 'technology',
  'goal': 'funding',
  'has_media': true,
});
```

##### `trackScreenView(String screenName)`

**Description**: Tracks screen views.

**Parameters**:
- `screenName` (String): Screen name

**Example**:
```dart
await analyticsService.trackScreenView('feed_page');
```

## 🔔 Notifications API

### NotificationService

The `NotificationService` handles push notifications and in-app notifications.

#### Methods

##### `registerDeviceToken(String token)`

**Description**: Registers device token for push notifications.

**Parameters**:
- `token` (String): FCM device token

**Returns**: `Future<void>`

**Example**:
```dart
final token = await FirebaseMessaging.instance.getToken();
await notificationService.registerDeviceToken(token);
```

##### `subscribeToTopic(String topic)`

**Description**: Subscribes to notification topic.

**Parameters**:
- `topic` (String): Topic name

**Returns**: `Future<void>`

**Example**:
```dart
await notificationService.subscribeToTopic('new_messages');
```

## 📤 File Upload API

### FileService

The `FileService` handles file uploads to Supabase Storage.

#### Methods

##### `uploadFile(XFile file, String bucket, String path)`

**Description**: Uploads file to storage bucket.

**Parameters**:
- `file` (XFile): File to upload
- `bucket` (String): Storage bucket name
- `path` (String): File path in bucket

**Returns**: `Future<String>` - File URL

**Example**:
```dart
final url = await fileService.uploadFile(
  imageFile,
  'startupbuilder',
  'posts/user123_image.jpg'
);
```

##### `deleteFile(String bucket, String path)`

**Description**: Deletes file from storage.

**Parameters**:
- `bucket` (String): Storage bucket name
- `path` (String): File path in bucket

**Returns**: `Future<void>`

**Example**:
```dart
await fileService.deleteFile('startupbuilder', 'posts/old_image.jpg');
```

##### `getSignedUrl(String bucket, String path, {Duration? expiresIn})`

**Description**: Gets signed URL for private files.

**Parameters**:
- `bucket` (String): Storage bucket name
- `path` (String): File path
- `expiresIn` (Duration?): URL expiration time

**Returns**: `Future<String>`

**Example**:
```dart
final signedUrl = await fileService.getSignedUrl(
  'startupbuilder',
  'private/document.pdf',
  expiresIn: Duration(hours: 1)
);
```

## 🚨 Error Handling

### Exception Types

#### `AuthenticationException`
Thrown when authentication operations fail.

#### `DatabaseException`
Thrown when database operations fail.

#### `NetworkException`
Thrown when network operations fail.

#### `ValidationException`
Thrown when input validation fails.

#### `StorageException`
Thrown when file operations fail.

### Error Response Format

```dart
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  
  ApiError({
    required this.code,
    required this.message,
    this.details,
  });
}
```

### Error Handling Example

```dart
try {
  final posts = await postService.getPosts();
  return posts;
} on DatabaseException catch (e) {
  debugPrint('Database error: ${e.message}');
  // Handle database-specific error
  throw ApiError(
    code: 'DATABASE_ERROR',
    message: 'Failed to load posts',
    details: {'original': e.message},
  );
} on NetworkException catch (e) {
  debugPrint('Network error: ${e.message}');
  // Handle network-specific error
  throw ApiError(
    code: 'NETWORK_ERROR', 
    message: 'Please check your connection',
  );
} catch (e) {
  debugPrint('Unexpected error: $e');
  // Handle unexpected errors
  throw ApiError(
    code: 'UNKNOWN_ERROR',
    message: 'An unexpected error occurred',
  );
}
```

## 📈 Rate Limiting

### Limits by Service

| Service | Method | Limit | Window |
|---------|---------|--------|---------|
| PostService | createPost | 10 requests | 1 hour |
| DMService | sendMessage | 60 requests | 1 minute |
| AuthService | signIn | 5 attempts | 15 minutes |
| SearchService | searchAll | 100 requests | 1 minute |

### Rate Limit Headers

Responses include rate limiting information:

```dart
class RateLimitInfo {
  final int limit;
  final int remaining;
  final DateTime resetTime;
}
```

### Handling Rate Limits

```dart
try {
  await postService.createPost(request);
} on RateLimitException catch (e) {
  final waitTime = e.resetTime.difference(DateTime.now());
  throw ApiError(
    code: 'RATE_LIMITED',
    message: 'Please wait ${waitTime.inMinutes} minutes before trying again',
  );
}
```

## 🔄 Real-time Subscriptions

### Available Channels

#### Messages Channel
```dart
final subscription = Supabase.instance.client
    .channel('messages')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        final message = MessageModel.fromJson(payload.newRecord);
        onNewMessage(message);
      },
    )
    .subscribe();
```

#### Posts Channel
```dart
final subscription = Supabase.instance.client
    .channel('posts')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public', 
      table: 'posts',
      callback: (payload) {
        final post = PostModel.fromJson(payload.newRecord);
        onNewPost(post);
      },
    )
    .subscribe();
```

### Subscription Management

```dart
class SubscriptionManager {
  final List<RealtimeSubscription> _subscriptions = [];
  
  void addSubscription(RealtimeSubscription subscription) {
    _subscriptions.add(subscription);
  }
  
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    _subscriptions.clear();
  }
}
```

## 📝 Request/Response Examples

### Create Post Request

**Request**:
```json
{
  "title": "Revolutionary AI Startup",
  "description": "We're building the next generation of AI tools...",
  "category": "technology",
  "post_goal": "funding",
  "funding_goal": 500000.0,
  "media_files": ["image1.jpg", "image2.jpg"]
}
```

**Response**:
```json
{
  "id": 123,
  "user_id": "user123",
  "title": "Revolutionary AI Startup",
  "description": "We're building the next generation of AI tools...",
  "category": "technology",
  "post_goal": "funding",
  "funding_goal": 500000.0,
  "moderation_status": "approved",
  "status": "published",
  "created_at": "2025-08-26T10:30:00Z",
  "updated_at": "2025-08-26T10:30:00Z",
  "media": [
    {
      "id": 456,
      "post_id": 123,
      "type": "image",
      "filename": "user123_1693048200_0.jpg",
      "original_name": "image1.jpg",
      "file_path": "posts/user123_1693048200_0.jpg",
      "file_size": 1024000,
      "uploaded_at": "2025-08-26T10:30:00Z"
    }
  ],
  "author": {
    "id": "user123",
    "name": "John Doe",
    "avatar_url": "https://example.com/avatar.jpg"
  }
}
```

### Send Message Request

**Request**:
```json
{
  "conversation_id": "conv-123",
  "content": "Hello! I'm interested in your startup.",
  "message_type": "text",
  "reply_to": null
}
```

**Response**:
```json
{
  "id": "msg-789",
  "conversation_id": "conv-123",
  "sender_id": "user456",
  "content": "Hello! I'm interested in your startup.",
  "message_type": "text",
  "reply_to": null,
  "edited_at": null,
  "deleted_at": null,
  "created_at": "2025-08-26T10:35:00Z",
  "sender": {
    "id": "user456",
    "name": "Jane Smith",
    "avatar_url": "https://example.com/jane_avatar.jpg"
  }
}
```

```

## 📝 Recent API Changes

### September 1, 2025 - v1.1.0

#### UI/UX Enhancements
- **Color System**: Implemented logo-inspired orange/yellow color scheme
- **Media Support**: Enhanced video upload and playback capabilities  
- **Action Buttons**: Improved post interaction with themed colors:
  - Investment actions: Orange theme
  - Collaboration features: Golden yellow theme
  - Suggestions: Deep orange theme
- **Navigation**: Enhanced user experience with personalized thread titles
- **Responsive Design**: Optimized action buttons for mobile devices

#### API Improvements
- **Thread Titles**: DM conversations now display participant names instead of "Thread"
- **Media Handling**: Full support for video file uploads alongside images
- **Profile Loading**: Enhanced participant profile resolution in messaging
- **Error Handling**: Improved setState() lifecycle management

#### Database Schema
- No schema changes in this release
- Existing media table supports video files
- All messaging functionality remains backward compatible

### August 26, 2025 - v1.0.0
- Initial API documentation
- Core authentication, posts, and messaging functionality
- Basic media upload support

---

**Last Updated**: September 1, 2025  
**API Version**: 1.1.0  
**Maintainer**: Development Team

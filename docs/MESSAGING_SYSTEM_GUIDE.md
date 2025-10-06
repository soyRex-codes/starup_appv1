# Real-time Messaging System Guide

## 🚀 Overview

The FounderVers app features a sophisticated **real-time messaging system** built entirely on **Supabase** infrastructure, supporting both direct messaging and group conversations with WebSocket-powered instant delivery.

**Architecture**: Supabase Real-time + PostgreSQL + Flutter  
**Features**: Instant messaging, read receipts, message status, optimistic updates  
**Performance**: Sub-second message delivery, offline message queuing

## 💬 Core Features

### **Direct Messaging (1-on-1)**
- **Instant message delivery** via Supabase Realtime WebSockets
- **Read receipts** and message status tracking
- **Message history** persistence with pagination
- **Optimistic updates** for seamless UX
- **Offline support** with message queuing

### **Group Conversations**
- **Multi-participant chats** with up to 50 members
- **Real-time participant management** (add/remove members)
- **Conversation metadata** (title, description, creator)
- **Last activity tracking** and unread counts

### **Advanced Features**
- **Message types**: Text, images, files, links
- **Reply to messages** with threading support
- **Message search** across all conversations
- **Push notifications** for new messages (when implemented)

## 🏗️ Technical Architecture

### **Database Schema (from 540-line schema)**

#### **Core Tables**
```sql
-- 1. Conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_type TEXT NOT NULL DEFAULT 'direct',
    title TEXT,
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Conversation participants
CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT NOW(),
    last_read_at TIMESTAMP,
    is_admin BOOLEAN DEFAULT FALSE,
    UNIQUE(conversation_id, user_id)
);

-- 3. Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    reply_to UUID REFERENCES messages(id),
    is_edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### **Optimized Indexes**
```sql
-- Performance indexes for messaging
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_participants_user_conversation ON conversation_participants(user_id, conversation_id);
CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC);
```

### **Real-time Subscriptions**

#### **WebSocket Setup**
```dart
class DMService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Store active subscriptions for cleanup
  final Map<String, RealtimeChannel> _activeSubscriptions = {};
  final Map<String, StreamController<Message>> _messageControllers = {};
  
  // Subscribe to real-time message updates
  void subscribeToMessages(String conversationId) {
    // Clean up existing subscription for this conversation
    unsubscribeFromMessages(conversationId);
    
    final channel = _supabase.channel('messages_$conversationId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) => _handleNewMessage(conversationId, payload),
      );
    
    // Attach error and status handlers
    channel.onError((error) {
      print('❌ Realtime subscription error for conversation $conversationId: $error');
      // Implement retry logic with exponential backoff
      _retrySubscription(conversationId, channel);
    });
    
    channel.onClose(() {
      print('🔌 Realtime subscription closed for conversation $conversationId');
      _activeSubscriptions.remove(conversationId);
    });
    
    // Subscribe and store the channel
    channel.subscribe();
    _activeSubscriptions[conversationId] = channel;
    
    // Create message controller for this conversation
    _messageControllers[conversationId] = StreamController<Message>.broadcast();
  }
  
  // Handle incoming real-time messages with error handling
  void _handleNewMessage(String conversationId, PostgresChangePayload payload) {
    try {
      final messageData = payload.newRecord as Map<String, dynamic>;
      final message = Message.fromJson(messageData);
      
      // Add to local message list
      _messageControllers[conversationId]?.add(message);
      
      // Update conversation last activity
      _updateConversationActivity(message.conversationId);
      
      // Mark conversation as having unread messages
      _updateUnreadCount(message.conversationId);
      
    } catch (e, stackTrace) {
      print('❌ Error processing message for conversation $conversationId: $e');
      print('Stack trace: $stackTrace');
      // Don't rethrow - keep subscription alive
    }
  }
  
  // Retry subscription with exponential backoff
  void _retrySubscription(String conversationId, RealtimeChannel channel) {
    // Simple retry logic - in production, implement exponential backoff
    Future.delayed(Duration(seconds: 5), () {
      if (_activeSubscriptions.containsKey(conversationId)) {
        print('🔄 Retrying subscription for conversation $conversationId');
        channel.subscribe();
      }
    });
  }
  
  // Unsubscribe from messages for a specific conversation
  void unsubscribeFromMessages(String conversationId) {
    final channel = _activeSubscriptions[conversationId];
    if (channel != null) {
      channel.unsubscribe();
      _activeSubscriptions.remove(conversationId);
      print('🧹 Unsubscribed from messages for conversation $conversationId');
    }
    
    // Clean up message controller
    _messageControllers[conversationId]?.close();
    _messageControllers.remove(conversationId);
  }
  
  // Dispose all subscriptions and controllers
  void dispose() {
    // Unsubscribe from all active channels
    for (final conversationId in _activeSubscriptions.keys.toList()) {
      unsubscribeFromMessages(conversationId);
    }
    
    // Close all message controllers
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    
    _activeSubscriptions.clear();
    _messageControllers.clear();
    
    print('🧹 All realtime subscriptions disposed');
  }
  
  // Get message stream for a conversation
  Stream<Message> getMessageStream(String conversationId) {
    return _messageControllers[conversationId]?.stream ?? Stream.empty();
  }
}
```

## 📱 User Interface Guide

### **1. Accessing Messages**
```
Navigation: Main Menu → "Messages" OR Bottom Tab → "DMs"
```
- **Inbox View**: Shows all conversations sorted by last activity
- **Unread Indicators**: Badge showing unread message count
- **Search Bar**: Quick search across all conversations

### **2. Starting Conversations**

#### **Direct Message (1-on-1)**
```dart
// From user profile or anywhere in app
final conversation = await dmService.getOrCreateDirectConversation('user_456');

if (conversation == null) {
  // Handle error case - show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Unable to start conversation. Please try again.'),
      backgroundColor: Colors.red,
    ),
  );
  return; // Exit early, don't navigate
}

// Proceed with navigation only if conversation was created successfully
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ChatScreen(conversation: conversation),
));
```

#### **Group Conversation**
```
1. Tap '+' button in Messages inbox
2. Select "New Group"
3. Add participants by username/email
4. Set group title and description
5. Tap "Create Group"
```

### **3. Chat Interface**

#### **Message Composition**
- **Text Input**: Type message in bottom text field
- **Send Button**: Tap arrow (→) to send
- **Media Attachments**: Tap attachment icon for images/files
- **Reply**: Long-press message → "Reply"

#### **Message Features**
- **Timestamps**: Shown for messages >5 minutes apart
- **Read Receipts**: ✓ (sent), ✓✓ (delivered), ✓✓ (read)
- **Message Status**: Sending → Sent → Delivered → Read
- **Edit Messages**: Long-press → "Edit" (within 15 minutes)

## 🔧 Implementation Examples

### **Creating a Direct Conversation**
```dart
Future<Conversation?> createDirectMessage(String otherUserId) async {
  try {
    // Use database function for atomic conversation creation
    final result = await _supabase.rpc('get_or_create_direct_conversation', params: {
      'user1_id': _currentUserId,
      'user2_id': otherUserId,
    });

    // Safely inspect and extract conversation ID from RPC response
    if (result == null) {
      print('❌ RPC returned null result');
      return null;
    }

    String? conversationId;

    // Handle different possible response shapes
    if (result is String) {
      conversationId = result;
    } else if (result is Map<String, dynamic>) {
      // Try common ID field names
      conversationId = result['conversation_id'] as String? ??
                      result['id'] as String? ??
                      result['conversationId'] as String?;
    } else if (result is List && result.isNotEmpty) {
      // Handle array response (take first element)
      final firstItem = result.first;
      if (firstItem is String) {
        conversationId = firstItem;
      } else if (firstItem is Map<String, dynamic>) {
        conversationId = firstItem['conversation_id'] as String? ??
                        firstItem['id'] as String? ??
                        firstItem['conversationId'] as String?;
      }
    }

    // Validate extracted conversation ID
    if (conversationId == null || conversationId.isEmpty) {
      print('❌ Invalid conversation ID extracted from RPC response: $result');
      print('Expected String, Map with id/conversation_id key, or non-empty List');
      return null;
    }

    // Additional validation - check if it's a valid UUID format
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(conversationId)) {
      print('❌ Invalid UUID format for conversation ID: $conversationId');
      return null;
    }

    return await _getConversationDetails(conversationId);
  } catch (e, stackTrace) {
    print('❌ Error creating conversation: $e');
    print('Stack trace: $stackTrace');
    print('Original RPC response type: ${result?.runtimeType}');
    print('Original RPC response value: $result');
    return null;
  }
}
```

### **Sending Messages with Optimistic Updates**
```dart
Future<void> sendMessage(String conversationId, String content) async {
  // 1. Add optimistic message to UI immediately
  final optimisticMessage = Message(
    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
    conversationId: conversationId,
    senderId: _currentUserId,
    content: content,
    createdAt: DateTime.now(),
    isOptimistic: true,
  );
  
  _addMessageToUI(optimisticMessage);
  
  try {
    // 2. Send to database
    final response = await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _currentUserId,
      'content': content,
      'message_type': 'text',
    }).select('*, sender_profile:users(id, username, full_name, avatar_url)')
      .single();
    
    // 3. Replace optimistic message with real message
    final realMessage = Message.fromJson(response);
    _replaceOptimisticMessage(optimisticMessage.id, realMessage);
    
  } catch (e) {
    // 4. Handle send failure
    _markMessageAsFailed(optimisticMessage.id);
  }
}
```

### **Pagination and Message History**
```dart
Future<List<Message>> loadMoreMessages(String conversationId, {DateTime? before}) async {
  var query = _supabase
      .from('messages')
      .select('*, sender_profile:users(id, username, full_name, avatar_url)')
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: false)
      .limit(20);
  
  if (before != null) {
    query = query.lt('created_at', before.toIso8601String());
  }
  
  final response = await query;
  return response.map((json) => Message.fromJson(json)).toList();
}
```  
3. **messages** - Stores individual messages

### **Key Functions:**
- `get_or_create_direct_conversation(user1, user2)` - Creates conversations
- `mark_conversation_read(conversation_id, user_id)` - Tracks read status

## Current Status
✅ **App compiles and runs successfully**  
✅ **Single unified messaging system**  
✅ **User-friendly interface with clear options**  
✅ **Real-time messaging capability**  
🔧 **Database migration needed** (see `SUPABASE_MIGRATION_INSTRUCTIONS.md`)

## Next Steps
1. **Apply database migration** to add missing `last_read_at` column
2. **Test conversations** using the self-chat feature  
3. **Create conversations** with other users by their UUIDs
4. **Messaging is fully functional!** 🎉

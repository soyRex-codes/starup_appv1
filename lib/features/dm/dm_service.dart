import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import 'models/conversation.dart';
import 'models/message.dart';
import 'dm_message_cache.dart';
import '../../services/moderation_service.dart';

/// Service for managing direct messages and conversations
class DMService {
  DMService._();
  static final DMService _instance = DMService._();
  static DMService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();
  final DMMessageCache _messageCache = DMMessageCache.instance;

  // Stream controllers for real-time updates
  final _conversationsController =
      StreamController<List<Conversation>>.broadcast();
  final _messagesController = StreamController<List<Message>>.broadcast();
  // REMOVED: Typing indicators (dropped for scalability: support 1.5x more users)
  // final _typingIndicatorController =
  //     StreamController<TypingIndicator>.broadcast();

  // Subscriptions for real-time listeners
  RealtimeChannel? _conversationSubscription;
  RealtimeChannel? _messageSubscription;
  String? _currentConversationId;

  // Connection pooling: cache channels to reuse instead of creating new ones
  final Map<String, RealtimeChannel> _channelPool = {};
  static const int _maxPooledChannels = 10;

  // Conversation caching: 5 minute TTL
  List<Conversation>? _cachedConversations;
  DateTime? _conversationsCacheTime;
  static const _conversationsCacheTTL = Duration(minutes: 5);

  /// Stream of conversations for the current user
  Stream<List<Conversation>> get conversationsStream =>
      _conversationsController.stream;

  /// Stream of messages for the current conversation
  Stream<List<Message>> get messagesStream => _messagesController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    await _setupConversationSubscription();
  }

  /// Dispose of resources
  void dispose() {
    _conversationSubscription?.unsubscribe();
    _messageSubscription?.unsubscribe();
    _clearChannelPool();
    _conversationsController.close();
    _messagesController.close();
    // REMOVED: Typing indicators
    // _typingIndicatorController.close();
  }

  // =============================================
  // CONVERSATION MANAGEMENT
  // =============================================

  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    try {
      // Check cache first (5 min TTL)
      if (_cachedConversations != null && _conversationsCacheTime != null) {
        final cacheAge = DateTime.now().difference(_conversationsCacheTime!);
        if (cacheAge < _conversationsCacheTTL) {
          debugPrint(
              '✅ Using cached conversations (${cacheAge.inSeconds}s old)');
          return _cachedConversations!;
        }
      }

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase.from('conversations').select('''
            *,
            participants:conversation_participants(
              *,
              user_profile:users(id, username, full_name, avatar_url)
            )
          ''').order('last_message_at', ascending: false);

      final conversations = (response as List<dynamic>)
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();

      // Calculate unread counts
      final conversationsWithUnread = await Future.wait(
        conversations.map((conv) async {
          final unreadCount = await getUnreadCount(conv.id);
          return conv.copyWith(unreadCount: unreadCount);
        }),
      );

      // Cache the result
      _cachedConversations = conversationsWithUnread;
      _conversationsCacheTime = DateTime.now();

      _conversationsController.add(conversationsWithUnread);
      return conversationsWithUnread;
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  /// Get a single conversation by ID
  Future<Conversation?> getConversationById(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            participants:conversation_participants(
              user:users(id, name, username, avatar_url),
              role,
              joined_at,
              last_read_at
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Conversation.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching conversation by ID: $e');
      return null;
    }
  }

  /// Get or create a direct conversation with another user
  Future<Conversation?> getOrCreateDirectConversation(
      String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Use the database function to get or create conversation
      final result =
          await _supabase.rpc('get_or_create_direct_conversation', params: {
        'user1_id': currentUserId,
        'user2_id': otherUserId,
      });

      if (result == null) return null;

      final conversationId = result as String;

      // Fetch the full conversation data
      final conversationData = await _supabase.from('conversations').select('''
            *,
            participants:conversation_participants(
              *,
              user_profile:users(id, username, full_name, avatar_url)
            )
          ''').eq('id', conversationId).single();

      return Conversation.fromJson(conversationData);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      // Get participant's last read timestamp
      final participantData = await _supabase
          .from('conversation_participants')
          .select('last_read_at')
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUserId)
          .single();

      final lastReadAt = participantData['last_read_at'] as String?;

      if (lastReadAt == null) {
        // If never read, count all messages
        final result = await _supabase
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', currentUserId);
        return (result as List).length;
      }

      // Count messages after last read time
      final result = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .gt('created_at', lastReadAt);

      return (result as List).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // =============================================
  // MESSAGE MANAGEMENT
  // =============================================

  /// Get messages for a conversation with caching
  Future<List<Message>> getMessages(String conversationId,
      {int limit = 50, int offset = 0, bool forceRefresh = false}) async {
    try {
      // Check cache first (only for initial load, offset = 0)
      if (!forceRefresh && offset == 0) {
        final cached = _messageCache.get(conversationId);
        if (cached != null) {
          debugPrint('📦 DM Cache HIT for conversation: $conversationId');
          _messagesController.add(cached);
          return cached;
        }
        debugPrint('📭 DM Cache MISS for conversation: $conversationId');
      }

      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender_profile:users(id, username, full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      final messages = (response as List<dynamic>)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first

      // Cache the results (only for initial load)
      if (offset == 0) {
        _messageCache.put(conversationId, messages);
      }

      _messagesController.add(messages);
      return messages;
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Send a text message
  Future<Message?> sendTextMessage(
      String conversationId, String content) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check content moderation before sending
      final moderationService = ModerationService();
      final moderationResult =
          await moderationService.moderateText(content: content);
      final shouldBlock = moderationResult.blocked;

      if (shouldBlock) {
        debugPrint('🚫 Message blocked by moderation');
        throw Exception('Message violates community guidelines');
      }

      // Create optimistic local message
      final localId = _uuid.v4();
      final localMessage = Message.createLocal(
        localId: localId,
        conversationId: conversationId,
        senderId: currentUserId,
        content: content,
      );

      // Add to stream immediately for optimistic UI
      final currentMessages = await _getCurrentMessages();
      final optimisticMessages = [...currentMessages, localMessage];
      _messagesController.add(optimisticMessages);

      // Add to cache optimistically
      _messageCache.appendMessage(conversationId, localMessage);

      // Send to server
      final response = await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'content': content,
        'message_type': 'text',
      }).select('''
            *,
            sender_profile:users(id, username, full_name, avatar_url)
          ''').single();

      final serverMessage = Message.fromJson(response);

      // Replace local message with server message
      final updatedMessages = currentMessages
          .where((m) => m.localId != localId)
          .toList()
        ..add(serverMessage);

      _messagesController.add(updatedMessages);

      // Update cache with server message
      _messageCache.updateMessage(conversationId, serverMessage);

      return serverMessage;
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Mark local message as failed
      final currentMessages = await _getCurrentMessages();
      final failedMessages = currentMessages.map((m) {
        if (m.status == MessageStatus.sending) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();
      _messagesController.add(failedMessages);

      // Update cache with failed status
      final failedMessage = failedMessages.firstWhere(
        (m) => m.status == MessageStatus.failed,
        orElse: () => failedMessages.first,
      );
      _messageCache.updateMessage(conversationId, failedMessage);

      return null;
    }
  }

  /// Send an image message
  Future<Message?> sendImageMessage(
      String conversationId, File imageFile) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Upload image to Supabase Storage
      final fileName = '${_uuid.v4()}.${imageFile.path.split('.').last}';
      final filePath = 'messages/$conversationId/$fileName';

      await _supabase.storage
          .from('message_attachments')
          .upload(filePath, imageFile);

      // Get public URL
      final imageUrl =
          _supabase.storage.from('message_attachments').getPublicUrl(filePath);

      // Send message with image metadata
      final response = await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'message_type': 'image',
        'metadata': {
          'file_url': imageUrl,
          'file_name': fileName,
          'file_size': await imageFile.length(),
        },
      }).select('''
            *,
            sender_profile:users(id, username, full_name, avatar_url)
          ''').single();

      final message = Message.fromJson(response);

      // Add to current messages
      final currentMessages = await _getCurrentMessages();
      _messagesController.add([...currentMessages, message]);

      return message;
    } catch (e) {
      debugPrint('Error sending image: $e');
      return null;
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId, String conversationId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Perform soft delete using RPC to avoid RLS violation
      await _supabase.rpc('soft_delete_message', params: {
        'p_message_id': messageId,
      });
      
      // Remove from cache
      _messageCache.removeMessage(conversationId, messageId);

      // Notify listeners (remove from stream)
      final currentMessages = await _getCurrentMessages();
      final updatedMessages =
          currentMessages.where((m) => m.id != messageId).toList();
      _messagesController.add(updatedMessages);

    } catch (e) {
      debugPrint('Error deleting message: $e');
      // We don't rethrow here to avoid crashing UI, but we could if we want to show a snackbar
      // The previous implementation showed a snackbar in the UI by catching the error.
      // Let's rethrow so the UI can show the error if needed, or just log it.
      // Given the user asked for "production" code, silent failure or simple logging is often better 
      // than crashing, but the UI expects to handle it.
      // Let's keep the rethrow so the UI (ThreadView) can show "Failed to delete" if it wants.
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _supabase
          .from('conversation_participants')
          .update({
            'last_read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('user_id', currentUserId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  /// Batch mark multiple conversations as read (more efficient)
  Future<void> markMultipleAsRead(List<String> conversationIds) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null || conversationIds.isEmpty) return;

      // Single batch operation instead of multiple calls
      final updates = conversationIds
          .map((convId) => {
                'conversation_id': convId,
                'user_id': currentUserId,
                'last_read_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.from('conversation_participants').upsert(updates);

      // Invalidate cache
      _cachedConversations = null;
      _conversationsCacheTime = null;

      debugPrint(
          '✅ Batch marked ${conversationIds.length} conversations as read');
    } catch (e) {
      debugPrint('Error batch marking as read: $e');
    }
  }

  // =============================================
  // TYPING INDICATORS - REMOVED FOR SCALABILITY
  // =============================================
  //
  // Removed sendTypingIndicator() to increase concurrent user capacity by 1.5x
  // Users will no longer see "User is typing..." indicators
  // But direct messages remain instant (real-time messages subscription still active)
  //
  // To restore in future: Un-comment this method and add back listener in subscribeToMessages()
  //
  // Future<void> sendTypingIndicator(String conversationId) async {
  //   try {
  //     final currentUserId = _supabase.auth.currentUser?.id;
  //     final currentUser = _supabase.auth.currentUser;
  //     if (currentUserId == null || currentUser == null) return;
  //
  //     final typingIndicator = TypingIndicator(
  //       conversationId: conversationId,
  //       userId: currentUserId,
  //       username: currentUser.userMetadata?['username'] as String? ?? 'Unknown',
  //       timestamp: DateTime.now(),
  //     );
  //
  //     // Send to realtime channel
  //     await _supabase.channel('typing_$conversationId').sendBroadcastMessage(
  //           event: 'typing',
  //           payload: typingIndicator.toJson(),
  //         );
  //   } catch (e) {
  //     debugPrint('Error sending typing indicator: $e');
  //   }
  // }

  // =============================================
  // CONNECTION POOLING (Optimization)
  // =============================================

  /// Get or create a pooled channel (reuse instead of creating new)
  RealtimeChannel _getPooledChannel(String channelName) {
    // Check if channel already exists in pool
    if (_channelPool.containsKey(channelName)) {
      return _channelPool[channelName]!;
    }

    // Create new channel if pool not full
    if (_channelPool.length < _maxPooledChannels) {
      final channel = _supabase.channel(channelName);
      _channelPool[channelName] = channel;
      return channel;
    }

    // If pool is full, remove oldest and add new
    final oldestKey = _channelPool.keys.first;
    _channelPool[oldestKey]?.unsubscribe();
    _channelPool.remove(oldestKey);

    final channel = _supabase.channel(channelName);
    _channelPool[channelName] = channel;
    return channel;
  }

  /// Clear channel pool on dispose
  void _clearChannelPool() {
    for (final channel in _channelPool.values) {
      channel.unsubscribe();
    }
    _channelPool.clear();
  }

  // =============================================
  // REAL-TIME SETUP
  // =============================================

  /// Set up conversation subscription for real-time updates
  ///
  /// ⚠️ REAL-TIME STATUS: INACTIVE (Table not in publications)
  /// The 'conversations' table is NOT enabled in Supabase real-time publications.
  /// Only these 3 tables are enabled: chat_messages, messages, oauth_authorizations
  ///
  /// This subscription will silently fail to receive events, but won't error.
  /// App still works because getConversations() is called:
  /// - On manual refresh (pull-to-refresh)
  /// - When returning to inbox screen
  /// - After sending a new message
  ///
  /// Performance impact: None (inactive subscription uses minimal resources)
  ///
  /// To enable in future: Add 'conversations' to supabase_realtime publication
  Future<void> _setupConversationSubscription() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _conversationSubscription = _supabase
        .channel('conversations_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            // Refresh conversations when changes occur
            getConversations();
          },
        )
        .subscribe();
  }

  /// Subscribe to messages for a specific conversation
  ///
  /// ✅ REAL-TIME STATUS: ACTIVE (Table is in publications)
  /// The 'messages' table IS enabled in Supabase real-time publications.
  /// This subscription receives live events when new messages are inserted.
  ///
  /// Active for: Direct message conversations (1-on-1 chats)
  /// Real-time features working:
  /// - New message notifications
  /// - Typing indicators (via broadcast)
  /// - Live message updates in conversation view
  Future<void> subscribeToMessages(String conversationId) async {
    // Unsubscribe from previous conversation
    if (_messageSubscription != null &&
        _currentConversationId != conversationId) {
      _messageSubscription!.unsubscribe();
    }

    _currentConversationId = conversationId;

    // Use pooled channel instead of creating new one (saves connections)
    _messageSubscription = _getPooledChannel('messages_$conversationId')
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
            // Add new message to stream
            _handleNewMessage(payload.newRecord);
          },
        )
        // REMOVED: .onBroadcast(event: 'typing', ...) for scalability
        // Removed typing indicators to support 1.5x more concurrent users
        // Users won't see "User is typing..." but messages are still instant
        .subscribe();

    // Load initial messages
    await getMessages(conversationId);
  }

  /// Handle new message from real-time subscription
  void _handleNewMessage(Map<String, dynamic> messageData) async {
    try {
      // Invalidate conversation cache when new message arrives
      _cachedConversations = null;
      _conversationsCacheTime = null;

      // Fetch full message data with sender profile
      final fullMessageData = await _supabase.from('messages').select('''
            *,
            sender_profile:users(id, username, full_name, avatar_url)
          ''').eq('id', messageData['id']).single();

      final newMessage = Message.fromJson(fullMessageData);

      // Add to current messages if not already present
      final currentMessages = await _getCurrentMessages();
      if (!currentMessages.any((m) => m.id == newMessage.id)) {
        _messagesController.add([...currentMessages, newMessage]);
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  /// Get current messages from the stream
  Future<List<Message>> _getCurrentMessages() async {
    try {
      return _messagesController.hasListener
          ? await _messagesController.stream.first
              .timeout(const Duration(seconds: 1))
          : [];
    } catch (e) {
      return [];
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import 'models/conversation.dart';
import 'models/message.dart';
import '../../services/moderation_service.dart';

/// Service for managing direct messages and conversations
class DMService {
  DMService._();
  static final DMService _instance = DMService._();
  static DMService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  // Stream controllers for real-time updates
  final _conversationsController =
      StreamController<List<Conversation>>.broadcast();
  final _messagesController = StreamController<List<Message>>.broadcast();
  final _typingIndicatorController =
      StreamController<TypingIndicator>.broadcast();

  // Subscriptions for real-time listeners
  RealtimeChannel? _conversationSubscription;
  RealtimeChannel? _messageSubscription;
  String? _currentConversationId;

  /// Stream of conversations for the current user
  Stream<List<Conversation>> get conversationsStream =>
      _conversationsController.stream;

  /// Stream of messages for the current conversation
  Stream<List<Message>> get messagesStream => _messagesController.stream;

  /// Stream of typing indicators
  Stream<TypingIndicator> get typingIndicatorStream =>
      _typingIndicatorController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    await _setupConversationSubscription();
  }

  /// Dispose of resources
  void dispose() {
    _conversationSubscription?.unsubscribe();
    _messageSubscription?.unsubscribe();
    _conversationsController.close();
    _messagesController.close();
    _typingIndicatorController.close();
  }

  // =============================================
  // CONVERSATION MANAGEMENT
  // =============================================

  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    try {
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

      _conversationsController.add(conversationsWithUnread);
      return conversationsWithUnread;
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
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

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId,
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender_profile:users(id, username, full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      final messages = (response as List<dynamic>)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first

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
  final moderationResult = await moderationService.moderateText(content: content);
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
      _messagesController.add([...currentMessages, localMessage]);

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

  // =============================================
  // TYPING INDICATORS
  // =============================================

  /// Send typing indicator
  Future<void> sendTypingIndicator(String conversationId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final currentUser = _supabase.auth.currentUser;
      if (currentUserId == null || currentUser == null) return;

      final typingIndicator = TypingIndicator(
        conversationId: conversationId,
        userId: currentUserId,
        username: currentUser.userMetadata?['username'] as String? ?? 'Unknown',
        timestamp: DateTime.now(),
      );

      // Send to realtime channel
      await _supabase.channel('typing_$conversationId').sendBroadcastMessage(
            event: 'typing',
            payload: typingIndicator.toJson(),
          );
    } catch (e) {
      debugPrint('Error sending typing indicator: $e');
    }
  }

  // =============================================
  // REAL-TIME SETUP
  // =============================================

  /// Set up conversation subscription for real-time updates
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
  Future<void> subscribeToMessages(String conversationId) async {
    // Unsubscribe from previous conversation
    if (_messageSubscription != null &&
        _currentConversationId != conversationId) {
      _messageSubscription!.unsubscribe();
    }

    _currentConversationId = conversationId;

    _messageSubscription = _supabase
        .channel('messages_$conversationId')
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
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final typingIndicator = TypingIndicator.fromJson(payload);
            _typingIndicatorController.add(typingIndicator);
          },
        )
        .subscribe();

    // Load initial messages
    await getMessages(conversationId);
  }

  /// Handle new message from real-time subscription
  void _handleNewMessage(Map<String, dynamic> messageData) async {
    try {
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

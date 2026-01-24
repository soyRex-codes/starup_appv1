import 'package:flutter/foundation.dart';
import 'package:foundervers/services/supa.dart';

/// New messaging repositories targeting the conversations schema:
/// Tables: conversations, participants, messages
/// RPC: get_or_create_direct_conversation(uuid, uuid), mark_conversation_read(uuid, uuid)
///
/// Key design: All user IDs are UUIDs. Modern messaging system.

final _s = Supa.client;

@immutable
class ThreadSummary {
  final String conversationId;
  final String viewerId;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final int unread;
  final List<String> participantIds; // includes viewer
  final String? lastMessageSenderId;
  final String? lastMessagePreview;

  const ThreadSummary({
    required this.conversationId,
    required this.viewerId,
    required this.lastMessageId,
    required this.lastMessageAt,
    required this.unread,
    required this.participantIds,
    required this.lastMessageSenderId,
    required this.lastMessagePreview,
  });

  // Getter for backward compatibility
  String get threadId => conversationId;

  factory ThreadSummary.fromData({
    required String conversationId,
    required String viewerId,
    String? lastMessageId,
    DateTime? lastMessageAt,
    required int unread,
    required List<String> participantIds,
    String? lastMessageSenderId,
    String? lastMessagePreview,
  }) {
    return ThreadSummary(
      conversationId: conversationId,
      viewerId: viewerId,
      lastMessageId: lastMessageId,
      lastMessageAt: lastMessageAt,
      unread: unread,
      participantIds: participantIds,
      lastMessageSenderId: lastMessageSenderId,
      lastMessagePreview: lastMessagePreview,
    );
  }
}

@immutable
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String messageType;
  final Map<String, dynamic> metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.messageType = 'text',
    this.metadata = const {},
  });

  // Getter for backward compatibility
  String get threadId => conversationId;
  String get body => content;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      messageType: json['message_type']?.toString() ?? 'text',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }
}

class ThreadRepository {
  /// Ensure a 1:1 conversation exists and return its id.
  Future<String> ensure1to1(String a, String b) async {
    final result = await _s.rpc('get_or_create_direct_conversation',
        params: {'user1_id': a, 'user2_id': b});
    return result.toString();
  }

  /// Fetch conversation summaries for a user (inbox) ordered by last message desc.
  Future<List<ThreadSummary>> listThreads(
      {required String viewerId, int limit = 30, DateTime? before}) async {
    try {
      // Get conversations where user is a participant
      // Try with last_read_at first, fallback without it if column doesn't exist
      dynamic participants;
      try {
        final participantsQuery = _s
            .from('conversation_participants')
            .select('conversation_id, last_read_at')
            .eq('user_id', viewerId)
            .isFilter('left_at', null);
        participants = await participantsQuery;
      } catch (e) {
        if (e.toString().contains('last_read_at does not exist')) {
          // Fallback: query without last_read_at column
          final participantsQuery = _s
              .from('conversation_participants')
              .select('conversation_id')
              .eq('user_id', viewerId)
              .isFilter('left_at', null);
          participants = await participantsQuery;
        } else {
          rethrow;
        }
      }

      List<ThreadSummary> summaries = [];

      for (final participant in participants) {
        final conversationId = participant['conversation_id'] as String;
        final lastReadAt = participant.containsKey('last_read_at')
            ? participant['last_read_at'] as String?
            : null;

        // Get conversation details
        // Get last message
        final lastMessageQuery = _s
            .from('messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1);

        final lastMessages = await lastMessageQuery;
        final lastMessage = lastMessages.isNotEmpty ? lastMessages.first : null;

        // Count unread messages
        int unread = 0;
        if (lastReadAt != null && lastMessage != null) {
          final unreadQuery = _s
              .from('messages')
              .select('*')
              .eq('conversation_id', conversationId)
              .neq('sender_id', viewerId)
              .gt('created_at', lastReadAt);

          final unreadResult = await unreadQuery;
          unread = unreadResult.length;
        } else if (lastMessage != null &&
            lastMessage['sender_id'] != viewerId) {
          unread = 1;
        }

        // Get all participant IDs using SECURITY DEFINER function
        // (RLS policy only allows seeing own participant record, so we need this function)
        try {
          final participantsResult = await _s.rpc(
            'get_conversation_participants',
            params: {'conv_id': conversationId},
          );
          
          // The RPC returns a list of objects with 'user_id' field
          // Extract the actual UUID strings from the result
          final participantIds = (participantsResult as List)
              .map((p) => (p as Map<String, dynamic>)['user_id'] as String)
              .toList();
          
          debugPrint('Conversation $conversationId: participantIds = $participantIds');
          debugPrint('ViewerID = $viewerId');
        
          final summary = ThreadSummary.fromData(
            conversationId: conversationId,
            viewerId: viewerId,
            lastMessageId: lastMessage?['id'] as String?,
            lastMessageAt: lastMessage != null
                ? DateTime.parse(lastMessage['created_at'] as String)
                : null,
            unread: unread,
            participantIds: participantIds,
            lastMessageSenderId: lastMessage?['sender_id'] as String?,
            lastMessagePreview: lastMessage?['content'] as String?,
          );

          summaries.add(summary);
        } catch (e) {
          debugPrint('Error fetching participants for conversation $conversationId: $e');
          // Skip this conversation if we can't fetch participants
          continue;
        }
      }

      // Sort by last message time
      summaries.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      // Apply before filter if needed
      if (before != null) {
        summaries = summaries
            .where((s) =>
                s.lastMessageAt == null || s.lastMessageAt!.isBefore(before))
            .toList();
      }

      return summaries.take(limit).toList();
    } catch (e) {
      debugPrint('Error in listThreads: $e');
      return [];
    }
  }

  Future<void> markRead(String conversationId, String userId) async {
    await _s.rpc('mark_conversation_read',
        params: {'conversation_id': conversationId, 'user_id': userId});
  }
}

class MessageRepository {
  Future<List<ChatMessage>> pageMessages(
      {required String threadId, DateTime? before, int limit = 50}) async {
    var query = _s
        .from('messages')
        .select('*')
        .eq('conversation_id', threadId)
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = await query;
    var messages = (rows as List)
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Apply before filter in memory if needed
    if (before != null) {
      messages =
          messages.where((msg) => msg.createdAt.isBefore(before)).toList();
    }

    return messages;
  }

  Future<ChatMessage> send(
      {required String threadId,
      required String senderId,
      required String body,
      String messageType = 'text',
      Map<String, dynamic> metadata = const {},
      int? replyTo}) async {
    final result = await _s
        .from('messages')
        .insert({
          'conversation_id': threadId,
          'sender_id': senderId,
          'content': body,
          'message_type': messageType,
          'metadata': metadata,
        })
        .select()
        .single();

    return ChatMessage.fromJson(Map<String, dynamic>.from(result as Map));
  }
}

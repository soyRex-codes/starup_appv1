import 'package:meta/meta.dart';

@immutable
class ChatMessageModel {
  final int id;
  final String userId;
  final String userName;
  final String? content;
  final DateTime? createdAt;
  final String? moderationStatus;
  final bool edited;
  final DateTime? deletedAt;

  const ChatMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.content,
    this.createdAt,
    this.moderationStatus,
    this.edited = false,
    this.deletedAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: _asInt(json['id']) ?? 0,
        userId: (json['user_id'] ?? '').toString(),
        userName: (json['user_name'] ?? '').toString(),
        content: json['content'] as String?,
        createdAt: _asDate(json['created_at']),
        moderationStatus: json['moderation_status'] as String?,
        edited: (json['edited'] as bool?) ?? false,
        deletedAt: _asDate(json['deleted_at']),
      );
}

@immutable
class PersonalMessageModel {
  final int id;
  final String senderId;
  final String recipientId;
  final String senderName;
  final String senderEmail;
  final String recipientEmail;
  final String subject;
  final String content;
  final String type;
  final int? relatedPostId;
  final String? relatedPostTitle;
  final int? originalMessageId; // reply threading
  final bool read;
  final DateTime? createdAt;

  const PersonalMessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.senderName,
    required this.senderEmail,
    required this.recipientEmail,
    required this.subject,
    required this.content,
    required this.type,
    this.relatedPostId,
    this.relatedPostTitle,
    this.originalMessageId,
    required this.read,
    this.createdAt,
  });

  factory PersonalMessageModel.fromJson(Map<String, dynamic> json) =>
      PersonalMessageModel(
        id: _asInt(json['id']) ?? 0,
        senderId: (json['sender_id'] ?? '').toString(),
        recipientId: (json['recipient_id'] ?? '').toString(),
        senderName: (json['sender_name'] ?? '').toString(),
        senderEmail: (json['sender_email'] ?? '').toString(),
        recipientEmail: (json['recipient_email'] ?? '').toString(),
        subject: (json['subject'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        relatedPostId: _asInt(json['related_post_id']),
        relatedPostTitle: json['related_post_title'] as String?,
        originalMessageId: _asInt(json['original_message_id']),
        read: (json['read'] as bool?) ?? false,
        createdAt: _asDate(json['created_at']),
      );
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

import 'package:meta/meta.dart';

/// Notification types supported by the app
enum NotificationType {
  comment('comment', 'Comment', '💬'),
  reply('reply', 'Reply', '↩️'),
  dm('dm', 'Message', '📨'),
  bookmark('bookmark', 'Bookmark', '💾'),
  collabRequest('collab_request', 'Collaboration', '🤝'),
  system('system', 'System', '🔔'),
  broadcast('broadcast', 'Broadcast', '📢');

  final String value;
  final String displayName;
  final String icon;

  const NotificationType(this.value, this.displayName, this.icon);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Model representing an in-app notification
@immutable
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;

  // Related entities
  final int? relatedPostId;
  final String? relatedCommentId;
  final String? relatedUserId;
  final String? relatedConversationId;

  // Metadata
  final bool read;
  final DateTime createdAt;
  final String? actionUrl;

  // Author info (for display)
  final String? authorName;
  final String? authorAvatarUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedPostId,
    this.relatedCommentId,
    this.relatedUserId,
    this.relatedConversationId,
    this.read = false,
    required this.createdAt,
    this.actionUrl,
    this.authorName,
    this.authorAvatarUrl,
  });

  /// Create from Supabase JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      relatedPostId: json['related_post_id'] as int?,
      relatedCommentId: json['related_comment_id'] as String?,
      relatedUserId: json['related_user_id'] as String?,
      relatedConversationId: json['related_conversation_id'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      actionUrl: json['action_url'] as String?,
      // Author info from joined user data (if available)
      authorName: json['author']?['name'] as String? ??
          json['author']?['full_name'] as String? ??
          json['author']?['username'] as String?,
      authorAvatarUrl: json['author']?['avatar_url'] as String?,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'related_post_id': relatedPostId,
      'related_comment_id': relatedCommentId,
      'related_user_id': relatedUserId,
      'related_conversation_id': relatedConversationId,
      'read': read,
      'created_at': createdAt.toIso8601String(),
      'action_url': actionUrl,
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    int? relatedPostId,
    String? relatedCommentId,
    String? relatedUserId,
    String? relatedConversationId,
    bool? read,
    DateTime? createdAt,
    String? actionUrl,
    String? authorName,
    String? authorAvatarUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedPostId: relatedPostId ?? this.relatedPostId,
      relatedCommentId: relatedCommentId ?? this.relatedCommentId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedConversationId:
          relatedConversationId ?? this.relatedConversationId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      actionUrl: actionUrl ?? this.actionUrl,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }

  /// Get display icon based on type
  String get icon => type.icon;

  /// Get human-readable time ago
  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel{id: $id, type: ${type.value}, title: $title, read: $read}';
  }
}

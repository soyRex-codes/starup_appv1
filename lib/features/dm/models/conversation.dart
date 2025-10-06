import 'package:meta/meta.dart';

/// Represents a conversation between users
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.conversationType = ConversationType.direct,
    this.groupName,
    this.groupAvatarUrl,
    this.createdBy,
    this.participants = const [],
    this.unreadCount = 0,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final ConversationType conversationType;
  final String? groupName;
  final String? groupAvatarUrl;
  final String? createdBy;
  final List<ConversationParticipant> participants;
  final int unreadCount;

  /// Creates a copy with updated values
  Conversation copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    ConversationType? conversationType,
    String? groupName,
    String? groupAvatarUrl,
    String? createdBy,
    List<ConversationParticipant>? participants,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      conversationType: conversationType ?? this.conversationType,
      groupName: groupName ?? this.groupName,
      groupAvatarUrl: groupAvatarUrl ?? this.groupAvatarUrl,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Creates a Conversation from JSON data
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      lastMessagePreview: json['last_message_preview'] as String?,
      conversationType: ConversationType.fromString(
        json['conversation_type'] as String? ?? 'direct',
      ),
      groupName: json['group_name'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      createdBy: json['created_by'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) =>
                  ConversationParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'last_message_preview': lastMessagePreview,
      'conversation_type': conversationType.value,
      'group_name': groupName,
      'group_avatar_url': groupAvatarUrl,
      'created_by': createdBy,
      'participants': participants.map((p) => p.toJson()).toList(),
      'unread_count': unreadCount,
    };
  }

  /// Gets the other participant in a direct conversation
  ConversationParticipant? getOtherParticipant(String currentUserId) {
    if (conversationType != ConversationType.direct ||
        participants.length != 2) {
      return null;
    }
    return participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => participants.first,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Conversation{id: $id, conversationType: $conversationType, lastMessagePreview: $lastMessagePreview}';
  }
}

/// Type of conversation
enum ConversationType {
  direct('direct'),
  group('group');

  const ConversationType(this.value);
  final String value;

  static ConversationType fromString(String value) {
    return ConversationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ConversationType.direct,
    );
  }
}

/// Represents a participant in a conversation
@immutable
class ConversationParticipant {
  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    this.leftAt,
    this.isAdmin = false,
    this.lastReadAt,
    this.notificationSettings = const NotificationSettings(),
    this.userProfile,
  });

  final String id;
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isAdmin;
  final DateTime? lastReadAt;
  final NotificationSettings notificationSettings;
  final UserProfile? userProfile;

  /// Creates a copy with updated values
  ConversationParticipant copyWith({
    String? id,
    String? conversationId,
    String? userId,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isAdmin,
    DateTime? lastReadAt,
    NotificationSettings? notificationSettings,
    UserProfile? userProfile,
  }) {
    return ConversationParticipant(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isAdmin: isAdmin ?? this.isAdmin,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  /// Creates from JSON
  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null
          ? DateTime.parse(json['left_at'] as String)
          : null,
      isAdmin: json['is_admin'] as bool? ?? false,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      notificationSettings: NotificationSettings.fromJson(
        json['notification_settings'] as Map<String, dynamic>? ?? {},
      ),
      userProfile: json['user_profile'] != null
          ? UserProfile.fromJson(json['user_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_admin': isAdmin,
      'last_read_at': lastReadAt?.toIso8601String(),
      'notification_settings': notificationSettings.toJson(),
      'user_profile': userProfile?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConversationParticipant{id: $id, userId: $userId, isAdmin: $isAdmin}';
  }
}

/// Notification settings for a participant
@immutable
class NotificationSettings {
  const NotificationSettings({
    this.muted = false,
    this.pushEnabled = true,
  });

  final bool muted;
  final bool pushEnabled;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      muted: json['muted'] as bool? ?? false,
      pushEnabled: json['push_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'muted': muted,
      'push_enabled': pushEnabled,
    };
  }

  NotificationSettings copyWith({
    bool? muted,
    bool? pushEnabled,
  }) {
    return NotificationSettings(
      muted: muted ?? this.muted,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }
}

/// Basic user profile for messaging
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeenAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserProfile{id: $id, username: $username, fullName: $fullName}';
  }
}

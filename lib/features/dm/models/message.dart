import 'package:meta/meta.dart';

/// Represents a message in a conversation
@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.messageType = MessageType.text,
    this.metadata = const {},
    this.replyToId,
    this.editedAt,
    required this.createdAt,
    this.deletedAt,
    this.senderProfile,
    this.status = MessageStatus.sent,
    this.localId, // For optimistic updates
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final MessageType messageType;
  final Map<String, dynamic> metadata;
  final String? replyToId;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final MessageSenderProfile? senderProfile;
  final MessageStatus status;
  final String?
      localId; // Used for optimistic updates before server confirmation

  /// Whether this message is deleted
  bool get isDeleted => deletedAt != null;

  /// Whether this message has been edited
  bool get isEdited => editedAt != null;

  /// Whether this is a system message
  bool get isSystemMessage => messageType == MessageType.system;

  /// Get display content based on message type
  String get displayContent {
    if (isDeleted) return 'This message was deleted';

    switch (messageType) {
      case MessageType.text:
        return content ?? '';
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        final fileName = metadata['file_name'] as String?;
        return '📎 ${fileName ?? 'File'}';
      case MessageType.system:
        return content ?? 'System message';
    }
  }

  /// Get file URL from metadata
  String? get fileUrl => metadata['file_url'] as String?;

  /// Get file name from metadata
  String? get fileName => metadata['file_name'] as String?;

  /// Get file size from metadata
  int? get fileSize => metadata['file_size'] as int?;

  /// Get image dimensions from metadata
  Map<String, int>? get imageDimensions {
    final width = metadata['width'] as int?;
    final height = metadata['height'] as int?;
    if (width != null && height != null) {
      return {'width': width, 'height': height};
    }
    return null;
  }

  /// Creates a copy with updated values
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? messageType,
    Map<String, dynamic>? metadata,
    String? replyToId,
    DateTime? editedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
    MessageSenderProfile? senderProfile,
    MessageStatus? status,
    String? localId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      senderProfile: senderProfile ?? this.senderProfile,
      status: status ?? this.status,
      localId: localId ?? this.localId,
    );
  }

  /// Creates a Message from JSON data
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: MessageType.fromString(
        json['message_type'] as String? ?? 'text',
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      replyToId: json['reply_to_id'] as String?,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      senderProfile: json['sender_profile'] != null
          ? MessageSenderProfile.fromJson(
              json['sender_profile'] as Map<String, dynamic>)
          : null,
      status: MessageStatus.fromString(json['status'] as String? ?? 'sent'),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.value,
      'metadata': metadata,
      'reply_to_id': replyToId,
      'edited_at': editedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'sender_profile': senderProfile?.toJson(),
      'status': status.value,
    };
  }

  /// Creates a local message for optimistic updates
  factory Message.createLocal({
    required String localId,
    required String conversationId,
    required String senderId,
    required String content,
    MessageType messageType = MessageType.text,
    Map<String, dynamic> metadata = const {},
    MessageSenderProfile? senderProfile,
  }) {
    return Message(
      id: 'temp_$localId', // Temporary ID
      localId: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      metadata: metadata,
      createdAt: DateTime.now(),
      senderProfile: senderProfile,
      status: MessageStatus.sending,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message{id: $id, senderId: $senderId, messageType: $messageType, content: $content}';
  }
}

/// Type of message
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  system('system');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Status of a message
enum MessageStatus {
  sending('sending'), // Local state: being sent
  sent('sent'), // Server confirmed receipt
  delivered('delivered'), // Delivered to recipient's device
  read('read'), // Read by recipient
  failed('failed'); // Failed to send

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

/// Basic sender profile for messages
@immutable
class MessageSenderProfile {
  const MessageSenderProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  /// Display name for the sender
  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  factory MessageSenderProfile.fromJson(Map<String, dynamic> json) {
    return MessageSenderProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }

  MessageSenderProfile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) {
    return MessageSenderProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageSenderProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageSenderProfile{id: $id, username: $username, displayName: $displayName}';
  }
}

/// Represents typing indicator
@immutable
class TypingIndicator {
  const TypingIndicator({
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.timestamp,
  });

  final String conversationId;
  final String userId;
  final String username;
  final DateTime timestamp;

  /// Whether this typing indicator is still valid (within 3 seconds)
  bool get isValid {
    final now = DateTime.now();
    final difference = now.difference(timestamp).inSeconds;
    return difference <= 3;
  }

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'username': username,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingIndicator &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(conversationId, userId);

  @override
  String toString() {
    return 'TypingIndicator{conversationId: $conversationId, userId: $userId, username: $username}';
  }
}

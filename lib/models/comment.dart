import 'package:meta/meta.dart';

/// Category types for structured comments
enum CommentCategory {
  question('❓ Question', 'question'),
  idea('💡 Idea/Suggestion', 'idea'),
  critique('💪 Constructive Critique', 'critique'),
  resource('🔗 Resource', 'resource'),
  general('💬 General', 'general');

  final String displayLabel;
  final String value;
  const CommentCategory(this.displayLabel, this.value);

  static CommentCategory fromString(String value) {
    return CommentCategory.values.firstWhere(
      (cat) => cat.value == value.toLowerCase(),
      orElse: () => CommentCategory.general,
    );
  }
}

/// Simplified author info for comments
@immutable
class CommentAuthor {
  final String userId;
  final String? name;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  const CommentAuthor({
    required this.userId,
    this.name,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  /// Get display name prioritizing full name over name over username
  String get displayName {
    if (fullName?.isNotEmpty == true) return fullName!;
    if (name?.isNotEmpty == true && name != username) return name!;
    if (username?.isNotEmpty == true) {
      final cleanUsername = username!;
      if (cleanUsername.contains(RegExp(r'^[a-z0-9]+$'))) {
        return cleanUsername[0].toUpperCase() + cleanUsername.substring(1);
      }
      return cleanUsername;
    }
    return 'Unknown User';
  }

  factory CommentAuthor.fromJson(Map<String, dynamic> json) => CommentAuthor(
        userId: json['id']?.toString() ?? '',
        name: json['name'] as String?,
        username: json['username'] as String?,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}

/// Main comment model with support for threaded replies
@immutable
class CommentModel {
  final String id;
  final int postId;
  final String authorId;
  final String content;
  final CommentCategory category;
  final String? parentCommentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool edited;
  final CommentAuthor? author;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.category,
    this.parentCommentId,
    required this.createdAt,
    this.updatedAt,
    this.edited = false,
    this.author,
    this.replies = const [],
  });

  /// Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;

  /// Check if this comment has been edited
  bool get wasEdited => edited && updatedAt != null;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      postId: _asInt(json['post_id']) ?? 0,
      authorId: json['author_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: CommentCategory.fromString(json['category']?.toString() ?? 'general'),
      parentCommentId: json['parent_comment_id']?.toString(),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _asDate(json['updated_at']),
      edited: json['edited'] == true,
      author: json['author'] != null
          ? CommentAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      replies: const [], // Replies are populated separately
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'author_id': authorId,
        'content': content,
        'category': category.value,
        'parent_comment_id': parentCommentId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'edited': edited,
      };

  CommentModel copyWith({
    String? id,
    int? postId,
    String? authorId,
    String? content,
    CommentCategory? category,
    String? parentCommentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? edited,
    CommentAuthor? author,
    List<CommentModel>? replies,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      category: category ?? this.category,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      edited: edited ?? this.edited,
      author: author ?? this.author,
      replies: replies ?? this.replies,
    );
  }
}

/// Helper function to safely convert dynamic to int
int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

/// Helper function to safely convert dynamic to DateTime
DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

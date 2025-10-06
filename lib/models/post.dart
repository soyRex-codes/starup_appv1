import 'package:meta/meta.dart';

@immutable
class PostMedia {
  final int? id;
  final int? postId;
  final String? type;
  final String? filename;
  final String? originalName;
  final String? filePath;
  final int? fileSize;
  final DateTime? uploadedAt;

  const PostMedia({
    this.id,
    this.postId,
    this.type,
    this.filename,
    this.originalName,
    this.filePath,
    this.fileSize,
    this.uploadedAt,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
        id: _asInt(json['id']),
        postId: _asInt(json['post_id']),
        type: json['type'] as String?,
        filename: json['filename'] as String?,
        originalName: json['original_name'] as String?,
        filePath: json['file_path'] as String?,
        fileSize: _asInt(json['file_size']),
        uploadedAt: _asDate(json['uploaded_at']),
      );
}

@immutable
class AuthorSummary {
  final String userId;
  final String? name;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  const AuthorSummary({
    required this.userId,
    this.name,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  /// Get display name prioritizing full name over name over username
  String get displayName {
    // If we have a full name, use it
    if (fullName?.isNotEmpty == true) {
      return fullName!;
    }

    // If no full name but we have a name that's different from username, use it
    if (name?.isNotEmpty == true && name != username) {
      return name!;
    }

    // If name and username are the same, or only username exists,
    // create a cleaner display name from username
    if (username?.isNotEmpty == true) {
      // If username looks like an email prefix, make it title case
      final cleanUsername = username!;
      if (cleanUsername.contains(RegExp(r'^[a-z0-9]+$'))) {
        // Simple alphanumeric username - make it title case
        return cleanUsername[0].toUpperCase() + cleanUsername.substring(1);
      }
      return cleanUsername;
    }

    return 'Unknown User';
  }

  /// Get secondary text (username or fallback)
  String get secondaryText {
    // Only show @username if we have a full name as primary
    // This avoids showing the same text twice
    if (fullName?.isNotEmpty == true && username?.isNotEmpty == true) {
      return username!;
    }
    return ''; // Don't show secondary text if primary is already username-based
  }
}

@immutable
class PostModel {
  final int id;
  final String userId; // Supabase UUID
  final String? name; // author name snapshot
  final String title;
  final String? description;
  final String? category;
  final num? fundingGoal;
  final String? postGoal;
  final String? postGoalDescription;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? moderationStatus;
  final String? status; // published/draft etc.
  final List<PostMedia> media;
  final AuthorSummary? author; // hydrated separately

  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    this.name,
    this.description,
    this.category,
    this.fundingGoal,
    this.postGoal,
    this.postGoalDescription,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.moderationStatus,
    this.status,
    this.media = const [],
    this.author,
  });

  PostModel copyWith({AuthorSummary? author}) => PostModel(
        id: id,
        userId: userId,
        title: title,
        name: name,
        description: description,
        category: category,
        fundingGoal: fundingGoal,
        postGoal: postGoal,
        postGoalDescription: postGoalDescription,
        email: email,
        createdAt: createdAt,
        updatedAt: updatedAt,
        moderationStatus: moderationStatus,
        status: status,
        media: media,
        author: author ?? this.author,
      );

  static PostModel fromJson(Map<String, dynamic> json) => PostModel(
        id: _asInt(json['id']) ?? 0,
        userId: (json['user_id'] ?? '').toString(),
        name: json['name'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        category: json['category'] as String?,
        fundingGoal: json['funding_goal'] as num?,
        postGoal: json['post_goal'] as String?,
        postGoalDescription: json['post_goal_description'] as String?,
        email: json['email'] as String?,
        createdAt: _asDate(json['created_at']),
        updatedAt: _asDate(json['updated_at']),
        moderationStatus: json['moderation_status'] as String?,
        status: json['status'] as String?,
        media: (json['media'] as List<dynamic>?)
                ?.map((m) => PostMedia.fromJson(m as Map<String, dynamic>))
                .where((media) {
              // CRITICAL: Validate media belongs to this post to prevent wrong images
              final postId = _asInt(json['id']);
              final mediaPostId = media.postId;
              if (postId != null &&
                  mediaPostId != null &&
                  postId != mediaPostId) {
                print(
                    'WARNING: Media ${media.id} has post_id $mediaPostId but was loaded for post $postId');
                return false; // Filter out incorrect media
              }
              return true;
            }).toList() ??
            [],
      );
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

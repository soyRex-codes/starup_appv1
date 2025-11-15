import 'package:flutter/material.dart';
import 'package:foundervers/models/comment.dart';
import 'package:foundervers/app/theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/features/profile/unified_profile_page.dart';

/// Widget to display a single comment with author info and actions
class CommentCard extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final bool isReply;

  const CommentCard({
    required this.comment,
    required this.onReply,
    this.onDelete,
    this.isReply = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnComment = currentUser?.id == comment.authorId;

    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 36.0 : 12.0,
        right: 12.0,
        top: 8.0,
        bottom: 8.0,
      ),
      decoration: BoxDecoration(
        border: isReply
            ? const Border(
                left: BorderSide(color: AppColors.border, width: 2),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (clickable to view profile with visual feedback)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToProfile(context),
              borderRadius: BorderRadius.circular(16),
              child: _buildAvatar(),
            ),
          ),
          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name and timestamp
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToProfile(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            comment.author?.displayName ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Category badge (only for root comments)
                if (!comment.isReply) ...[
                  const SizedBox(height: 3),
                  _buildCategoryBadge(),
                ],

                const SizedBox(height: 4),

                // Comment content (selectable for better UX)
                SelectableText(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),

                if (comment.wasEdited) ...[
                  const SizedBox(height: 3),
                  const Text(
                    '(edited)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Actions row
                Row(
                  children: [
                    // Reply button
                    InkWell(
                      onTap: onReply,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Delete button (only for own comments)
                    if (isOwnComment && onDelete != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _confirmDelete(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline,
                                size: 15,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = comment.author?.avatarUrl;
    final displayName = comment.author?.displayName ?? 'U';
    final publicUrl = StorageUtils.resolvePublicUrl(avatarUrl);

    if (publicUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: publicUrl,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 26,
            height: 26,
            color: AppColors.primarySoft,
            child: Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              _buildDefaultAvatar(displayName),
        ),
      );
    }

    return _buildDefaultAvatar(displayName);
  }

  Widget _buildDefaultAvatar(String displayName) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: Center(
        child: Text(
          displayName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getCategoryColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        comment.category.displayLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getCategoryColor(),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (comment.category) {
      case CommentCategory.question:
        return const Color(0xFF2196F3); // Blue
      case CommentCategory.idea:
        return const Color(0xFFFFB300); // Amber
      case CommentCategory.critique:
        return const Color(0xFF8E24AA); // Purple
      case CommentCategory.resource:
        return const Color(0xFF43A047); // Green
      case CommentCategory.general:
        return AppColors.textSecondary;
    }
  }

  void _navigateToProfile(BuildContext context) {
    final authorId = comment.author?.userId;
    final authorName = comment.author?.displayName;

    // Don't navigate if no author ID
    if (authorId == null || authorId.isEmpty) return;

    // Navigate to public profile page (including own profile)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnifiedProfilePage(
          userId: authorId,
          userName: authorName,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) {
      onDelete!();
    }
  }
}

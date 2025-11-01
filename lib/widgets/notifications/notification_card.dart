import 'package:flutter/material.dart';
import 'package:foundervers/models/notification.dart';
import 'package:foundervers/app/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foundervers/core/storage_utils.dart';

/// Widget to display a single notification
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    required this.notification,
    required this.onTap,
    this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        color: notification.read ? Colors.white : AppColors.primary.withOpacity(0.05),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar or Icon
                _buildLeading(),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.read
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unread indicator
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Time
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    // Show author avatar if available
    if (notification.authorAvatarUrl != null &&
        notification.authorAvatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: StorageUtils.getMediaUrl(
            path: notification.authorAvatarUrl,
            bucket: 'startupbuilder',
          ),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 44,
            height: 44,
            color: AppColors.border,
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            width: 44,
            height: 44,
            color: AppColors.border,
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ),
      );
    }

    // Fallback to icon based on type
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          notification.icon,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case NotificationType.comment:
        return const Color(0xFF6B4EE6).withOpacity(0.15); // Purple
      case NotificationType.reply:
        return AppColors.primary.withOpacity(0.15); // Orange
      case NotificationType.dm:
        return Colors.blue.withOpacity(0.15);
      case NotificationType.bookmark:
        return const Color(0xFF10B981).withOpacity(0.15); // Green
      case NotificationType.collabRequest:
        return AppColors.accent.withOpacity(0.15); // Yellow
      case NotificationType.system:
        return Colors.grey.withOpacity(0.15);
    }
  }
}

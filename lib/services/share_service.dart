import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'deep_link_service.dart';

/// Advanced sharing service for viral growth and user acquisition
class ShareService {
  /// Share post with native OS share sheet and deep links
  ///
  /// IMPORTANT iOS Requirements:
  /// - iOS doesn't support the 'subject' parameter (removed to fix silent failure)
  /// - iOS/iPadOS requires sharePositionOrigin for popover positioning
  ///
  /// [sharePositionOrigin] - Required for iPad to position the share sheet popover.
  /// Pass a Rect relative to the button that triggered the share.
  static Future<void> sharePost({
    required int postId,
    required String title,
    String? description,
    String? imageUrl,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final shareUrl = DeepLinkService.generatePostLink(postId);
      final shareText = _buildShareText(title, description, shareUrl);

      // iOS FIX: Provide sharePositionOrigin for iPad popover positioning
      // If not provided, use center of screen as fallback
      final result = await Share.share(
        shareText,
        sharePositionOrigin:
            sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 100, 100),
      );

      debugPrint('Share result status: ${result.status}');

      // Don't show snackbar for dismissed shares - that's normal user behavior
      if (result.status == ShareResultStatus.success) {
        debugPrint('✅ Share completed successfully');
      } else if (result.status == ShareResultStatus.dismissed) {
        debugPrint('Share dismissed by user');
      } else if (result.status == ShareResultStatus.unavailable) {
        debugPrint('⚠️ Share unavailable on this platform');
      }

      _trackShareAttempt(postId);
    } catch (e) {
      debugPrint('❌ Share error: $e');
      // Only show error if there's an actual failure, not dismissal
      rethrow;
    }
  }

  /// Build engaging share text
  static String _buildShareText(
      String title, String? description, String shareUrl) {
    final buffer = StringBuffer();

    // Hook line
    buffer.writeln('💡 Check out this startup idea:');
    buffer.writeln();

    // Post content
    buffer.writeln(title);

    if (description != null && description.isNotEmpty) {
      // Truncate description for sharing
      final truncated = description.length > 100
          ? '${description.substring(0, 100)}...'
          : description;
      buffer.writeln();
      buffer.writeln(truncated);
    }

    buffer.writeln();
    buffer.writeln('👆 Tap to join the discussion');
    buffer.writeln(shareUrl);
    buffer.writeln();
    buffer.writeln(
        'No app yet? Download FounderVers: ${DeepLinkService.fallbackDownloadUrl}');
    buffer.writeln();
    buffer.writeln('#startups #entrepreneurship #FounderVers');

    return buffer.toString();
  }

  /// Track sharing analytics
  static void _trackShareAttempt(int postId) {
    debugPrint('📤 Share attempt for post $postId');
    // Implement analytics tracking (Firebase, Mixpanel, etc.)
  }
}

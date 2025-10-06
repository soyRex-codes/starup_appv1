import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Advanced sharing service for viral growth and user acquisition
class ShareService {
  static const String _baseUrl =
      'https://startupnest-a3jdnswbja-uc.a.run.app'; // Your actual deployed URL

  /// Share post with native OS share sheet and deep links
  static Future<void> sharePost({
    required int postId,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    try {
      // Generate shareable deep link (simplified for now)
      final shareUrl = _generateShareUrl(postId);

      // Create compelling share text
      final shareText = _buildShareText(title, description, shareUrl);

      // Track sharing attempt
      _trackShareAttempt(postId);

      // Trigger native share sheet
      final result = await Share.shareWithResult(
        shareText,
        subject: title,
      );

      // Track successful shares
      if (result.status == ShareResultStatus.success) {
        _trackShareSuccess(postId, result.raw);
      }
    } catch (e) {
      debugPrint('Advanced share failed: $e');
      // Fallback to simple clipboard copy
      await _fallbackShare(title, description);
    }
  }

  /// Generate deep link URL for post (simplified version without API call)
  static String _generateShareUrl(int postId) {
    // For now, generate a simple deep link URL
    // Later, you can enhance this to call your backend API for tracking
    return '$_baseUrl/posts/$postId?utm_source=app&utm_medium=share';
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
    buffer.writeln('#startups #entrepreneurship #FounderVers');

    return buffer.toString();
  }

  /// Fallback sharing method
  static Future<void> _fallbackShare(String title, String? description) async {
    final text = description != null ? '$title\n\n$description' : title;
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Track sharing analytics
  static void _trackShareAttempt(int postId) {
    debugPrint('📤 Share attempt for post $postId');
    // Implement analytics tracking (Firebase, Mixpanel, etc.)
  }

  static void _trackShareSuccess(int postId, String platform) {
    debugPrint('✅ Share success for post $postId on $platform');
    // Track successful shares for growth metrics
  }

  /// Show share options (legacy method - now simplified)
  static void showShareOptions(
    BuildContext context, {
    required String title,
    String? description,
    String? imageUrl,
  }) {
    // Direct share - no modal needed
    sharePost(
      postId: 0, // You'll need to pass the actual post ID
      title: title,
      description: description,
      imageUrl: imageUrl,
    );
  }
}

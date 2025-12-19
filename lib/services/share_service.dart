import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

      // iOS FIX: Validate and sanitize sharePositionOrigin coordinates
      // Ensure coordinates are non-negative and within reasonable bounds
      final validatedOrigin = _validateSharePosition(sharePositionOrigin);

      ShareResult result;

      // Try to download and share image if available
      XFile? imageFile;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(imageUrl);
          final response = await http.get(uri);
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File('${tempDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            imageFile = XFile(file.path, mimeType: 'image/jpeg');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to download share image: $e');
        }
      }

      if (imageFile != null) {
        result = await Share.shareXFiles(
          [imageFile],
          text: shareText,
          sharePositionOrigin: validatedOrigin,
        );
      } else {
        result = await Share.share(
          shareText,
          sharePositionOrigin: validatedOrigin,
        );
      }

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

  /// Validate and sanitize sharePositionOrigin coordinates
  ///
  /// Ensures coordinates are:
  /// - Non-negative (fixes negative Y coordinate crashes)
  /// - Within reasonable bounds (0-10000 range)
  /// - Non-zero width and height
  ///
  /// Returns a safe default if validation fails.
  static Rect _validateSharePosition(Rect? origin) {
    // Default safe position (center-ish of typical screen)
    const defaultRect = Rect.fromLTWH(100, 200, 100, 100);

    if (origin == null) {
      return defaultRect;
    }

    // Check for invalid coordinates (negative, NaN, infinite, or unreasonably large)
    if (origin.left < 0 ||
        origin.top < 0 ||
        origin.left.isNaN ||
        origin.top.isNaN ||
        origin.left.isInfinite ||
        origin.top.isInfinite ||
        origin.left > 10000 ||
        origin.top > 10000) {
      debugPrint(
          '⚠️ Invalid sharePositionOrigin detected: $origin. Using safe default.');
      return defaultRect;
    }

    // Check for zero or negative width/height
    if (origin.width <= 0 || origin.height <= 0) {
      debugPrint(
          '⚠️ Invalid sharePositionOrigin dimensions: ${origin.width}x${origin.height}. Using safe default.');
      return defaultRect;
    }

    // Coordinates are valid
    return origin;
  }

  /// Track sharing analytics
  static void _trackShareAttempt(int postId) {
    debugPrint('📤 Share attempt for post $postId');
    // Implement analytics tracking (Firebase, Mixpanel, etc.)
  }
}

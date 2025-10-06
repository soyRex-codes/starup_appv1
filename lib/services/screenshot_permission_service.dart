import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to manage screenshot permissions for social media sharing
class ScreenshotPermissionService {
  static const MethodChannel _channel = MethodChannel('screenshot_permission');

  /// Enable screenshots throughout the app (for social media sharing)
  static Future<void> enableScreenshots() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('enableScreenshots');
      } catch (e) {
        debugPrint('Failed to enable screenshots: $e');
      }
    }
  }

  /// Temporarily disable screenshots (for sensitive content)
  static Future<void> disableScreenshots() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('disableScreenshots');
      } catch (e) {
        debugPrint('Failed to disable screenshots: $e');
      }
    }
  }
}

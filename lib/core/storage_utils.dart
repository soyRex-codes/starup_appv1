import 'package:foundervers/core/env.dart';

/// Utility class for handling storage URLs and media operations
class StorageUtils {
  StorageUtils._();

  /// Generate optimal URL for displaying media from storage
  static String getMediaUrl({
    required String? path,
    required String bucket,
    bool preferSigned = false,
  }) {
    if (path == null || path.isEmpty) {
      return '';
    }

    // If already a full URL, return as-is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // For public buckets like 'startupbuilder', use public URL for better performance
    if (bucket == 'startupbuilder' && !preferSigned) {
      return '${AppEnv.supabaseUrl}/storage/v1/object/public/$bucket/$path';
    }

    // For private buckets, would need signed URL (handled by calling code)
    return '${AppEnv.supabaseUrl}/storage/v1/object/public/$bucket/$path';
  }

  /// Check if a file extension is supported for upload
  static bool isSupportedFileType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    const supportedExtensions = {
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'webp',
      // Videos
      'mp4', 'mov',
      // Documents
      'pdf',
    };
    return supportedExtensions.contains(ext);
  }

  /// Get MIME type from file extension
  static String getMimeType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  /// Check if file size is within limits
  static bool isFileSizeValid(int bytes, {int maxMB = 50}) {
    return bytes <= maxMB * 1024 * 1024;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

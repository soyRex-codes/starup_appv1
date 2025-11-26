import 'package:foundervers/core/env.dart';

/// Utility class for handling storage URLs and media operations
class StorageUtils {
  StorageUtils._();

  /// Generate optimal URL for displaying media from storage
  static String getMediaUrl({
    required String? path,
    required String bucket,
    bool preferSigned = false,
    int? width,
    int? height,
    int? quality,
    String? resize, // 'cover', 'contain', 'fill'
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
      final baseUrl = '${AppEnv.supabaseUrl}/storage/v1/object/public/$bucket/$path';
      return _appendTransformations(baseUrl, width, height, quality, resize);
    }

    // For private buckets, would need signed URL (handled by calling code)
    final baseUrl = '${AppEnv.supabaseUrl}/storage/v1/object/public/$bucket/$path';
    return _appendTransformations(baseUrl, width, height, quality, resize);
  }

  static String _appendTransformations(
    String url,
    int? width,
    int? height,
    int? quality,
    String? resize,
  ) {
    if (width == null && height == null && quality == null) return url;

    final params = <String>[];
    if (width != null) params.add('width=$width');
    if (height != null) params.add('height=$height');
    if (quality != null) params.add('quality=$quality');
    if (resize != null) params.add('resize=$resize');

    if (params.isEmpty) return url;
    return '$url?${params.join('&')}';
  }

  /// Normalize avatar/media paths to full public URLs.
  /// Accepts absolute URLs, storage paths, or file names and ensures
  /// callers always receive a browser-ready URL.
  static String? resolvePublicUrl(
    String? path, {
    String? bucket,
    int? width,
    int? height,
    int? quality,
    String? resize,
  }) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final resolvedBucket = bucket ?? AppEnv.startupbuilderBucket;
    return getMediaUrl(
      path: path, 
      bucket: resolvedBucket,
      width: width,
      height: height,
      quality: quality,
      resize: resize,
    );
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

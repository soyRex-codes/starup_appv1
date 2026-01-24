import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for compressing images and videos before upload
///
/// Performance targets:
/// - Images: 2MB -> 300KB (85% reduction)
/// - Videos: Maintain quality while reducing file size by 40-60%
///
/// Quality settings:
/// - High: 85% quality, minimal compression (for professional content)
/// - Medium: 70% quality, balanced (default, recommended)
/// - Low: 50% quality, maximum compression (for previews)
class MediaCompressionService {
  MediaCompressionService._();
  static final MediaCompressionService instance = MediaCompressionService._();

  // =============================================
  // IMAGE COMPRESSION
  // =============================================

  /// Compress an image file with quality control
  ///
  /// [file] - Original image file
  /// [quality] - Compression quality (0-100, default: 70)
  /// [maxWidth] - Maximum width in pixels (default: 1920)
  /// [maxHeight] - Maximum height in pixels (default: 1920)
  ///
  /// Returns compressed file or original if compression fails
  Future<File> compressImage(
    File file, {
    int quality = 70,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      debugPrint('Compressing image: ${file.path}');
      final originalSize = await file.length();
      debugPrint('   Original size: ${_formatBytes(originalSize)}');

      // Get file extension
      final extension = path.extension(file.path).toLowerCase();

      // Determine output format
      CompressFormat format;
      String outputExtension;

      if (extension == '.png') {
        // PNG with transparency should stay PNG
        format = CompressFormat.png;
        outputExtension = '.png';
      } else {
        // Convert everything else to JPEG for better compression
        format = CompressFormat.jpeg;
        outputExtension = '.jpg';
      }

      // Create output path in temp directory
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${path.basenameWithoutExtension(file.path)}_compressed$outputExtension',
      );

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format,
        keepExif: false, // Remove EXIF data to save space
      );

      if (result == null) {
        debugPrint('Compression failed, using original file');
        return file;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final reduction = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint('   Compressed size: ${_formatBytes(compressedSize)}');
      debugPrint('   Reduction: ${reduction.toStringAsFixed(1)}%');

      // If compressed file is larger (rare), use original
      if (compressedSize >= originalSize) {
        debugPrint('Compressed file larger than original, using original');
        await compressedFile.delete();
        return file;
      }

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file; // Return original on error
    }
  }

  /// Compress multiple images in parallel
  ///
  /// [files] - List of image files to compress
  /// [quality] - Compression quality (default: 70)
  ///
  /// Returns list of compressed files
  Future<List<File>> compressImages(
    List<File> files, {
    int quality = 70,
  }) async {
    debugPrint('Batch compressing ${files.length} images...');

    final results = await Future.wait(
      files.map((file) => compressImage(file, quality: quality)),
    );

    final totalOriginal = await Future.wait(files.map((f) => f.length()));
    final totalCompressed = await Future.wait(results.map((f) => f.length()));

    final originalSize = totalOriginal.fold<int>(0, (sum, size) => sum + size);
    final compressedSize =
        totalCompressed.fold<int>(0, (sum, size) => sum + size);
    final reduction = ((originalSize - compressedSize) / originalSize * 100);

    debugPrint('Batch compression complete:');
    debugPrint('   Total original: ${_formatBytes(originalSize)}');
    debugPrint('   Total compressed: ${_formatBytes(compressedSize)}');
    debugPrint('   Total reduction: ${reduction.toStringAsFixed(1)}%');

    return results;
  }

  // =============================================
  // VIDEO COMPRESSION
  // =============================================

  /// Compress a video file
  ///
  /// [file] - Original video file
  /// [quality] - Video quality (VideoQuality.MediumQuality recommended)
  ///
  /// Returns compressed file or original if compression fails
  Future<File> compressVideo(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    try {
      debugPrint('Compressing video: ${file.path}');
      final originalSize = await file.length();
      debugPrint('   Original size: ${_formatBytes(originalSize)}');

      // Don't compress videos smaller than 5MB (already optimized)
      if (originalSize < 5 * 1024 * 1024) {
        debugPrint('   Video already small, skipping compression');
        return file;
      }

      // Start compression
      final mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: quality,
        deleteOrigin: false, // Keep original file
        includeAudio: true,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        debugPrint('Video compression failed, using original file');
        return file;
      }

      final compressedFile = mediaInfo.file!;
      final compressedSize = await compressedFile.length();
      final reduction = ((originalSize - compressedSize) / originalSize * 100);

      debugPrint('   Compressed size: ${_formatBytes(compressedSize)}');
      debugPrint('   Reduction: ${reduction.toStringAsFixed(1)}%');

      // If compressed file is larger, use original
      if (compressedSize >= originalSize) {
        debugPrint('Compressed video larger than original, using original');
        await compressedFile.delete();
        return file;
      }

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return file; // Return original on error
    }
  }

  /// Get video compression progress stream
  /// Use this to show progress UI during video compression
  ///
  /// Returns a broadcast stream that can be listened to by multiple widgets.
  /// The stream automatically cleans up resources when all listeners cancel.
  Stream<double> getVideoCompressionProgress() {
    // Create a broadcast stream controller to allow multiple listeners
    final controller = StreamController<double>.broadcast();

    dynamic subscription;
    bool isSubscribed = false;

    // Lazy subscription - only subscribe when first listener attaches
    controller.onListen = () {
      if (!isSubscribed) {
        try {
          subscription = VideoCompress.compressProgress$.subscribe(
            (progress) {
              // Forward progress to stream, checking if controller is still open
              if (!controller.isClosed) {
                try {
                  controller.add(progress);
                } catch (e) {
                  // If adding fails, stream is likely closed - clean up
                  if (subscription != null) {
                    try {
                      subscription.unsubscribe();
                    } catch (_) {
                      // Ignore unsubscribe errors
                    }
                  }
                }
              }
            },
          );
          isSubscribed = true;
        } catch (e) {
          // If subscription fails, add error to stream and close
          if (!controller.isClosed) {
            controller.addError(e);
            controller.close();
          }
        }
      }
    };

    // Clean up subscription when last listener cancels
    controller.onCancel = () {
      if (isSubscribed && subscription != null) {
        try {
          subscription.unsubscribe();
        } catch (e) {
          // Ignore unsubscribe errors during cleanup
        }
        isSubscribed = false;
        subscription = null;
      }
      // Close controller to prevent resource leaks
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  /// Cancel ongoing video compression
  Future<void> cancelVideoCompression() async {
    await VideoCompress.cancelCompression();
  }

  /// Delete all temporary compressed files
  Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
      debugPrint('Cleared compression cache');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // =============================================
  // UTILITY METHODS
  // =============================================

  /// Check if file is an image
  bool isImage(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        .contains(extension);
  }

  /// Check if file is a video
  bool isVideo(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v']
        .contains(extension);
  }

  /// Compress a file (auto-detect image or video)
  ///
  /// [file] - File to compress
  /// [imageQuality] - Quality for images (default: 70)
  /// [videoQuality] - Quality for videos (default: MediumQuality)
  ///
  /// Returns compressed file or original if not supported
  Future<File> compressFile(
    File file, {
    int imageQuality = 70,
    VideoQuality videoQuality = VideoQuality.MediumQuality,
  }) async {
    if (isImage(file)) {
      return compressImage(file, quality: imageQuality);
    } else if (isVideo(file)) {
      return compressVideo(file, quality: videoQuality);
    } else {
      debugPrint('File type not supported for compression: ${file.path}');
      return file;
    }
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Quality presets for easy usage
enum CompressionQuality {
  /// 85% quality - minimal compression, best for professional content
  high,

  /// 70% quality - balanced (recommended for most use cases)
  medium,

  /// 50% quality - maximum compression, best for previews/thumbnails
  low,
}

/// Extension methods for easy compression
extension CompressionQualityExtension on CompressionQuality {
  int get value {
    switch (this) {
      case CompressionQuality.high:
        return 85;
      case CompressionQuality.medium:
        return 70;
      case CompressionQuality.low:
        return 50;
    }
  }
}

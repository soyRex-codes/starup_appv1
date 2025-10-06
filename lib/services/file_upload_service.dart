/// File Upload Service for Business Applications
/// Handles file uploads to Supabase storage bucket and manages file operations
library;

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/utils/logger.dart';
import '../core/storage_utils.dart';

class FileUploadService {
  static final _supabase = Supabase.instance.client;
  static const String bucketName = AppConstants.applicationsBucket;

  /// Log error with detailed information
  static void _logError(String message, dynamic error, StackTrace? stackTrace) {
    Logger.error(message, error: error, stackTrace: stackTrace);
  }

  /// Upload a single file to Supabase storage
  /// Returns the public URL of the uploaded file
  static Future<String?> uploadFile({
    required PlatformFile file,
    required String applicationId,
    String? customFileName,
  }) async {
    try {
      // Input validation
      if (applicationId.isEmpty) {
        const error = 'Application ID cannot be empty';
        _logError('Upload validation failed', error, StackTrace.current);
        return null;
      }

      if (file.name.isEmpty) {
        const error = 'File name cannot be empty';
        _logError('Upload validation failed', error, StackTrace.current);
        return null;
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          customFileName ?? '${applicationId}_${timestamp}_${file.name}';
      final filePath = 'applications/$applicationId/$fileName';

      // Upload file based on platform
      String uploadedFilePath;
      try {
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          // Web platform - use bytes
          uploadedFilePath = await _supabase.storage
              .from(bucketName)
              .uploadBinary(filePath, file.bytes!);
        } else if (file.path != null && file.path!.isNotEmpty) {
          // Mobile platform - use file path
          final fileToUpload = File(file.path!);
          if (!await fileToUpload.exists()) {
            const error = 'File does not exist at the specified path';
            _logError('File validation failed', error, StackTrace.current);
            return null;
          }
          uploadedFilePath = await _supabase.storage
              .from(bucketName)
              .upload(filePath, fileToUpload);
        } else {
          const error = 'No valid file data available (neither bytes nor path)';
          _logError('File data validation failed', error, StackTrace.current);
          return null;
        }
      } catch (e, stackTrace) {
        _logError('File upload to storage failed', e, stackTrace);
        return null;
      }

      // Validate upload response
      if (uploadedFilePath.isEmpty) {
        const error = 'Upload returned empty path';
        _logError('Upload validation failed', error, StackTrace.current);
        return null;
      }

      // Get public URL using the original file path for consistency
      try {
        final publicUrl =
            _supabase.storage.from(bucketName).getPublicUrl(filePath);

        if (publicUrl.isEmpty) {
          const error = 'Failed to generate public URL';
          _logError('Public URL generation failed', error, StackTrace.current);
          return null;
        }

        return publicUrl;
      } catch (e, stackTrace) {
        _logError('Public URL generation failed', e, stackTrace);
        return null;
      }
    } catch (e, stackTrace) {
      _logError('Unexpected error during file upload', e, stackTrace);
      return null;
    }
  }

  /// Upload multiple files for an application
  /// Returns a list of file info objects with URLs
  static Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<PlatformFile> files,
    required String applicationId,
  }) async {
    final uploadedFiles = <Map<String, dynamic>>[];

    for (final file in files) {
      final url = await uploadFile(
        file: file,
        applicationId: applicationId,
      );

      if (url != null) {
        uploadedFiles.add(generateFileMetadata(
          fileName: file.name,
          fileUrl: url,
          fileSize: file.size,
          fileType: file.extension ?? 'unknown',
        ));
      }
    }

    return uploadedFiles;
  }

  /// Delete a file from storage
  static Future<bool> deleteFile(String filePath) async {
    try {
      await _supabase.storage.from(bucketName).remove([filePath]);
      return true;
    } catch (e, stackTrace) {
      _logError('Error deleting file', e, stackTrace);
      return false;
    }
  }

  /// Delete all files for an application
  static Future<bool> deleteApplicationFiles(String applicationId) async {
    try {
      final files = await _supabase.storage
          .from(bucketName)
          .list(path: 'applications/$applicationId');

      if (files.isNotEmpty) {
        final filePaths = files
            .map((file) => 'applications/$applicationId/${file.name}')
            .toList();

        await _supabase.storage.from(bucketName).remove(filePaths);
      }

      return true;
    } catch (e, stackTrace) {
      _logError('Error deleting application files', e, stackTrace);
      return false;
    }
  }

  /// Validate file before upload
  static String? validateFile(PlatformFile file) {
    // Check file size (50MB limit)
    const maxSize = 50 * 1024 * 1024; // 50MB in bytes
    if (file.size > maxSize) {
      return 'File size must be less than 50MB';
    }

    // Check file type
    const allowedExtensions = [
      'pdf', 'doc', 'docx', 'txt', 'rtf', // Documents
      'jpg', 'jpeg', 'png', 'gif', 'webp', // Images
      'xls', 'xlsx', 'csv', // Spreadsheets
      'ppt', 'pptx', // Presentations
      'zip', 'rar', // Archives
    ];

    final extension = file.extension?.toLowerCase();
    if (extension != null && !allowedExtensions.contains(extension)) {
      return 'File type not allowed. Supported: ${allowedExtensions.join(', ')}';
    }

    return null; // File is valid
  }

  /// Pick files using file picker
  static Future<List<PlatformFile>?> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      return result?.files;
    } catch (e, stackTrace) {
      _logError('Error picking files', e, stackTrace);
      return null;
    }
  }

  /// Generate file metadata for database storage
  static Map<String, dynamic> generateFileMetadata({
    required String fileName,
    required String fileUrl,
    required int fileSize,
    required String fileType,
    String? description,
  }) {
    return {
      'name': fileName,
      'url': fileUrl,
      'size': fileSize,
      'type': fileType,
      'size_formatted': StorageUtils.formatFileSize(fileSize),
      'uploaded_at': DateTime.now().toIso8601String(),
      'description': description,
    };
  }
}

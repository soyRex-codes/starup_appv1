import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Types of permissions used in the app
enum PermissionType {
  camera,
  photos,
  notifications,
}

/// Helper class for managing app permissions
class PermissionsHelper {
  PermissionsHelper._();
  
  /// Request camera permission with explanation dialog
  /// Returns true if permission granted
  static Future<bool> requestCameraPermission(BuildContext context) async {
    // Web doesn't need permission requests
    if (kIsWeb) return true;
    
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      // Show settings dialog
      if (context.mounted) {
        await _showPermissionExplanationDialog(
          context,
          PermissionType.camera,
          isPermanentlyDenied: true,
        );
      }
      return false;
    }
    
    // Request permission directly (Guideline 5.1.1)
    // We rely on the usage description in Info.plist to explain why we need access
    
    // Request permission
    final result = await Permission.camera.request();
    
    if (result.isGranted) {
      return true;
    }
    
    // If permission denied (or already denied), show settings dialog
    if (context.mounted) {
      await showPermissionDeniedDialog(context, PermissionType.camera);
    }
    
    return false;
  }
  
  /// Request photo library permission with explanation dialog
  /// Returns true if permission granted
  static Future<bool> requestPhotoPermission(BuildContext context) async {
    // Web doesn't need permission requests
    if (kIsWeb) return true;

    // iOS 14+ uses PHPicker via FilePicker, which doesn't require explicit permission
    // The system handles the UI and grants access to selected items only.
    if (!kIsWeb && Platform.isIOS) return true;
    
    final permission = Permission.storage;
    final status = await permission.status;
    
    if (status.isGranted || status.isLimited) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showPermissionExplanationDialog(
          context,
          PermissionType.photos,
          isPermanentlyDenied: true,
        );
      }
      return false;
    }
    
    // Request permission directly (Guideline 5.1.1)
    // We rely on the usage description in Info.plist to explain why we need access
    
    // Request permission
    final result = await permission.request();
    
    if (result.isGranted || result.isLimited) {
      return true;
    }
    
    // If permission denied (or already denied), show settings dialog
    if (context.mounted) {
      await showPermissionDeniedDialog(context, PermissionType.photos);
    }
    
    return false;
  }
  
  /// Show explanation dialog before requesting permission
  /// Returns true if user wants to proceed
  static Future<bool> _showPermissionExplanationDialog(
    BuildContext context,
    PermissionType type, {
    bool isPermanentlyDenied = false,
  }) async {
    final permissionInfo = _getPermissionInfo(type);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPermanentlyDenied 
            ? '${permissionInfo['title']} Permission Required' 
            : 'Allow ${permissionInfo['title']}?'),
        content: Text(isPermanentlyDenied
            ? '${permissionInfo['explanation']}\n\nTo enable this permission, please go to Settings > FounderVers > Permissions and turn on ${permissionInfo['title']}.'
            : permissionInfo['explanation'] as String),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              if (isPermanentlyDenied) {
                openAppSettings();
              }
            },
            child: Text(isPermanentlyDenied ? 'Open Settings' : 'Continue'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Get permission information for display
  static Map<String, String> _getPermissionInfo(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return {
          'title': 'Camera',
          'explanation': 'FounderVers needs access to your camera to let you take photos for your posts.',
        };
      case PermissionType.photos:
        return {
          'title': 'Photos',
          'explanation': 'FounderVers needs access to your photo library to let you select images for your posts.',
        };
      case PermissionType.notifications:
        return {
          'title': 'Notifications',
          'explanation': 'FounderVers would like to send you notifications for new messages and updates.',
        };
    }
  }
  
  /// Show dialog when permission is denied
  /// Guides user to app settings
  static Future<void> showPermissionDeniedDialog(
    BuildContext context,
    PermissionType type,
  ) async {
    final permissionInfo = _getPermissionInfo(type);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${permissionInfo['title']} Permission Denied'),
        content: Text(
          'To use this feature, please enable ${permissionInfo['title']} permission in Settings.\n\n'
          'Go to: Settings > FounderVers > Permissions > ${permissionInfo['title']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

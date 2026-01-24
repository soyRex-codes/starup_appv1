import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Network Service for handling connectivity and DNS issues
/// Specifically addresses Samsung Galaxy S25 Ultra and other Android device network problems
class NetworkService {
  static final instance = NetworkService._();
  NetworkService._();

  /// Check network connectivity and DNS resolution
  Future<bool> checkConnectivity() async {
    try {
      // First, try to resolve DNS
      final addresses = await InternetAddress.lookup('google.com');
      if (addresses.isNotEmpty && addresses[0].rawAddress.isNotEmpty) {
        if (kDebugMode) debugPrint('DNS resolution working');
        return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DNS resolution failed: $e');
    }
    return false;
  }

  /// Initialize Supabase with retry logic and fallback configurations
  /// Specifically handles Samsung Galaxy network issues
  static Future<bool> initializeSupabaseWithRetry({
    required String url,
    required String anonKey,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) debugPrint('Supabase init attempt $attempt/$maxRetries');
        
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        
        // Test the connection immediately
        final client = Supabase.instance.client;
        await client.from('users').select('id').limit(1);
        
        if (kDebugMode) debugPrint('Supabase initialized successfully');
        return true;
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Supabase init attempt $attempt failed: $e');
          if (e.toString().contains('SocketException')) {
            debugPrint('Network/DNS issue detected - will retry');
          }
        }
        
        if (attempt < maxRetries) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    
    if (kDebugMode) debugPrint('All Supabase init attempts failed');
    return false;
  }

  /// Test Supabase connection health
  Future<bool> testSupabaseConnection() async {
    try {
      final client = Supabase.instance.client;
      await client.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Supabase connection test failed: $e');
      return false;
    }
  }

  /// Get network error message for user display
  String getNetworkErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Check for Supabase API errors first (not network issues)
    if (errorStr.contains('over_email_send_rate_limit') || 
        errorStr.contains('rate_limit') ||
        errorStr.contains('429')) {
      final match = RegExp(r'after (\d+) seconds').firstMatch(errorStr);
      final waitTime = match?.group(1);
      if (waitTime != null) {
        return 'Too many email requests. Please wait $waitTime seconds before trying again.';
      }
      return 'Too many requests. Please wait a minute before trying again.';
    }
    
    if (errorStr.contains('invalid_email')) {
      return 'Invalid email address. Please check and try again.';
    }
    
    if (errorStr.contains('user_not_found')) {
      return 'Account not found. Please sign up first.';
    }
    
    if (errorStr.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    }
    
    // Actual network errors
    if (errorStr.contains('socketexception') || errorStr.contains('failed host lookup')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }
    
    if (errorStr.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    if (errorStr.contains('certificate') || errorStr.contains('ssl')) {
      return 'Security certificate issue. Please check your device date/time settings.';
    }
    
    // Default for unknown errors
    return error.toString().replaceFirst('Exception: ', '');
  }
}
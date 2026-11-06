import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Network Service for handling connectivity and DNS issues
/// Specifically addresses Samsung Galaxy S25 Ultra and other Android device network problems
class NetworkService {
  static final instance = NetworkService._();
  NetworkService._();

  /// Check whether the device currently has a network interface.
  /// This is web-safe; dart:io DNS lookups are not available in browsers.
  Future<bool> checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      if (kDebugMode) debugPrint('Connectivity check failed: $e');
    }
    return false;
  }

  /// Initialize the Supabase client.
  ///
  /// Initialization itself does not require a table query. The previous
  /// implementation queried `users` here, which incorrectly blocked startup
  /// whenever RLS denied anonymous access or the table name changed.
  static Future<bool> initializeSupabaseWithRetry({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      if (kDebugMode) debugPrint('Supabase client initialized');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Supabase initialization failed: $e');
      return false;
    }
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
    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup')) {
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

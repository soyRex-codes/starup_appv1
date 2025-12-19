import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:foundervers/app/auth_gate.dart';
import 'package:foundervers/services/network_service.dart';
import 'package:foundervers/services/iap_service.dart';
import 'package:foundervers/widgets/foundervers_logo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foundervers/services/push_notification_service.dart';

/// Handles async initialization of Supabase while showing loading UI.
/// Defers Firebase/Push notifications until after first frame.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final supabaseUrl = dotenv.dotenv.maybeGet('SUPABASE_URL') ??
          const String.fromEnvironment('SUPABASE_URL');
      final supabaseAnonKey = dotenv.dotenv.maybeGet('SUPABASE_ANON_KEY') ??
          const String.fromEnvironment('SUPABASE_ANON_KEY');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Missing Supabase configuration');
      }

      // Initialize Supabase (required for auth)
      final success = await NetworkService.initializeSupabaseWithRetry(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      if (!success) {
        throw Exception('Failed to connect to server');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Defer non-critical initialization to AFTER first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeDeferredServices();
        });
      }
    } catch (e) {
      log('❌ App initialization failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  /// Initialize Firebase and Push Notifications AFTER the first frame is rendered.
  /// This ensures the UI appears fast while these services load in the background.
  Future<void> _initializeDeferredServices() async {
    // Firebase (for push notifications)
    try {
      await Firebase.initializeApp();
      log('✅ Firebase initialized (deferred)');
    } catch (e) {
      log('⚠️ Firebase initialization failed: $e');
    }

    // Push Notifications
    try {
      await PushNotificationService.instance.initialize();
      log('✅ Push Notifications initialized (deferred)');
    } catch (e) {
      log('⚠️ Push Notification initialization failed: $e');
    }

    // Apple In-App Purchase for iOS (premium subscriptions)
    if (!kIsWeb && Platform.isIOS) {
      try {
        final iapService = IAPService();
        final isAvailable = await iapService.initialize();
        if (isAvailable) {
          log('✅ Apple In-App Purchase initialized (deferred)');
        } else {
          log('⚠️ Apple In-App Purchase not available');
        }
      } catch (e) {
        log('⚠️ IAP initialization failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_hasError) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'Connection Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to connect to the server.\nPlease check your internet connection.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                    _initializeApp();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading state - show branded loading screen
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SplashLogo(),
              const SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Initialized - show AuthGate
    return const AuthGate();
  }
}

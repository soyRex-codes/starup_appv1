import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:foundervers/app/auth_gate.dart';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/services/network_service.dart';
import 'package:foundervers/widgets/terai_logo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foundervers/services/push_notification_service.dart';
import 'package:foundervers/features/feed/feed_history_service.dart';
import 'package:foundervers/firebase_options.dart';

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
      final supabaseUrl = AppEnv.supabaseUrl;
      final supabaseAnonKey = AppEnv.supabaseAnonKey;

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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log('✅ Firebase initialized (deferred)');
    } catch (e) {
      log('⚠️ Firebase initialization failed: $e');
    }

    // Feed History Service (for smart feed shuffle)
    try {
      await FeedHistoryService.instance.init();
      log('✅ FeedHistoryService initialized (deferred)');
    } catch (e) {
      log('⚠️ FeedHistoryService initialization failed: $e');
    }

    // Push Notifications
    try {
      await PushNotificationService.instance.initialize();
      log('✅ Push Notifications initialized (deferred)');
    } catch (e) {
      log('⚠️ Push Notification initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_hasError) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.cloud_off_outlined,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 22),
                        Text('We could not connect',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(
                          'Check your connection, then try again. Your account and data are safe.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() => _hasError = false);
                            _initializeApp();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Loading state - show branded loading screen
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SplashLogo(),
                const SizedBox(height: 30),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initialized - show AuthGate
    return const AuthGate();
  }
}

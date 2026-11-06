import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/app/home_page.dart';
import 'package:foundervers/features/auth/sign_in_page.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/widgets/terai_logo.dart';
import 'package:foundervers/services/bookmark_service.dart';
import 'package:foundervers/services/notification_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _isAuthenticated;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Check initial session
    try {
      final session = Supabase.instance.client.auth.currentSession;
      setState(() {
        _isAuthenticated = session != null;
        _isLoading = false;
        _error = null;
      });

      if (session != null) {
        _postAuthHousekeeping(session.user, context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to connect. Please check your internet connection.';
          _isLoading = false;
        });
      }
      return;
    }

    // Listen for changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        final bool isAuth = session != null;

        if (_isAuthenticated != isAuth) {
          // Status changed (Login or Logout)
          if (mounted) {
            setState(() {
              _isAuthenticated = isAuth;
              _error = null;
            });
          }
        }

        // Run housekeeping only on explicit sign-in
        if (event == AuthChangeEvent.signedIn && session != null) {
          _postAuthHousekeeping(session.user, context);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = 'Connection lost. Please check your internet connection.';
          });
        }
      },
    );
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _authSubscription?.cancel();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SplashLogo(),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Handle connection error - show offline page
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Connection Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isAuthenticated == true) {
      return const HomePage();
    } else {
      return const SignInPage();
    }
  }
}

Future<void> _postAuthHousekeeping(User user, BuildContext context) async {
  // Fire and forget; minor if it fails.
  try {
    // First check if user is suspended
    final userProfile = await Supabase.instance.client
        .from('users')
        .select('is_suspended, suspension_reason')
        .eq('id', user.id)
        .maybeSingle();

    if (userProfile != null && userProfile['is_suspended'] == true) {
      // User is suspended - sign them out immediately
      await Supabase.instance.client.auth.signOut();

      final reason = userProfile['suspension_reason'] as String? ??
          'Your account has been suspended. Please contact support.';

      if (context.mounted) {
        // Show suspension message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account suspended: $reason'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // If not suspended, proceed with normal housekeeping
    final svc = UserService();
    await svc.upsertUser(
      userId: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? '',
      username: user.email?.split('@')[0],
      fullName: user.userMetadata?['full_name'],
      // NOTE: avatarUrl intentionally NOT passed here - profile data should
      // be managed separately from auth flow to prevent overwriting user's
      // custom avatar with null from auth metadata
      emailVerified: user.emailConfirmedAt != null,
      updateLastLoginOnlyIfExists: false,
    );

    // Warm up bookmark cache in background (don't await - fire and forget)
    BookmarkService.instance.refreshCache().then((_) {
      debugPrint('🔥 Bookmark cache warmed up on login');
    }).catchError((e) {
      debugPrint('⚠️ Failed to warm bookmark cache: $e');
    });

    // Start listening for notifications
    NotificationService.instance.startListening().then((_) {
      debugPrint('🔔 Notification listener started');
    }).catchError((e) {
      debugPrint('⚠️ Failed to start notification listener: $e');
    });
  } catch (e, st) {
    if (kDebugMode) debugPrint('Auth housekeeping failed: $e\n$st');
  }
}

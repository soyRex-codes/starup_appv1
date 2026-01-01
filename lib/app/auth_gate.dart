import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/app/home_page.dart';
import 'package:foundervers/features/auth/sign_in_page.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/widgets/foundervers_logo.dart';
import 'package:foundervers/services/bookmark_service.dart';
import 'package:foundervers/services/notification_service.dart';
import 'package:foundervers/services/premium_subscription_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Handle initial loading
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No Internet Connection',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please connect to the internet and try again.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Force re-render to retry connection
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final session = snapshot.data?.session;
        if (session == null) return const SignInPage();

        // On auth state change, ensure profile row exists and check suspension
        _postAuthHousekeeping(session.user, context);
        return const HomePage();
      },
    );
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

    // Check and refresh premium subscription status
    PremiumSubscriptionService().checkPremiumStatus().then((isActive) {
      debugPrint('💎 Premium status checked: $isActive');
    }).catchError((e) {
      debugPrint('⚠️ Failed to check premium status: $e');
    });
  } catch (e, st) {
    if (kDebugMode) debugPrint('Auth housekeeping failed: $e\n$st');
  }
}

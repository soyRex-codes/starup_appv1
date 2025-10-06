import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/app/home_page.dart';
import 'package:foundervers/features/auth/sign_in_page.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/widgets/foundervers_logo.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
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

        final session = snapshot.data?.session;
        if (session == null) return const SignInPage();

        // On auth state change, ensure profile row exists
        _postAuthHousekeeping(session.user);
        return const HomePage();
      },
    );
  }
}

Future<void> _postAuthHousekeeping(User user) async {
  // Fire and forget; minor if it fails.
  try {
    final svc = UserService();
    await svc.upsertUser(
      userId: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? '',
      username: user.email?.split('@')[0],
      fullName: user.userMetadata?['full_name'],
      avatarUrl: user.userMetadata?['avatar_url'],
      emailVerified: user.emailConfirmedAt != null,
      updateLastLoginOnlyIfExists: false,
    );
  } catch (e, st) {
    if (kDebugMode) debugPrint('Auth housekeeping failed: $e\n$st');
  }
}

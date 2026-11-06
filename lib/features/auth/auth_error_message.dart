import 'package:supabase_flutter/supabase_flutter.dart';

/// Distinguishes server responses from transport failures without displaying
/// raw response bodies, URLs, or provider details to users.
String? authInfrastructureErrorMessage(Object error) {
  if (error is! AuthException) return null;

  final message = error.message.toLowerCase();
  if (message.contains('error sending confirmation email') ||
      message.contains('error sending recovery email')) {
    return 'We could not send your verification email. Please try again later or contact support.';
  }

  final status = int.tryParse(error.statusCode ?? '');
  if (status != null && status >= 500) {
    return 'The authentication service is temporarily unavailable. Please try again later.';
  }

  // The SDK also uses this exception for HTTP 5xx; check status above first.
  if (error is AuthRetryableFetchException && status == null) {
    return 'Unable to reach the authentication service. Please check your connection and try again.';
  }
  return null;
}

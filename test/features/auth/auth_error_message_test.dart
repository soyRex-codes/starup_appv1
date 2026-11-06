import 'package:flutter_test/flutter_test.dart';
import 'package:foundervers/features/auth/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('confirmation email HTTP 500 is not reported as a connection failure',
      () {
    final message = authInfrastructureErrorMessage(AuthRetryableFetchException(
      message:
          '{"code":"unexpected_failure","message":"Error sending confirmation email"}',
      statusCode: '500',
    ));
    expect(message, contains('could not send your verification email'));
    expect(message, isNot(contains('connection')));
    expect(message, isNot(contains('unexpected_failure')));
  });

  test('other HTTP 5xx errors are service failures', () {
    expect(
        authInfrastructureErrorMessage(AuthRetryableFetchException(
          message: 'internal provider details',
          statusCode: '503',
        )),
        contains('temporarily unavailable'));
  });

  test('transport failure without HTTP response is a connection failure', () {
    expect(
        authInfrastructureErrorMessage(AuthRetryableFetchException(
          message: 'ClientException: Failed to fetch',
        )),
        contains('Unable to reach'));
  });

  test('credential, confirmation and rate-limit errors retain their handling',
      () {
    for (final code in [
      'invalid_credentials',
      'email_not_confirmed',
      'over_email_send_rate_limit'
    ]) {
      expect(
          authInfrastructureErrorMessage(AuthApiException(
            code,
            statusCode: '400',
            code: code,
          )),
          isNull);
    }
  });
}

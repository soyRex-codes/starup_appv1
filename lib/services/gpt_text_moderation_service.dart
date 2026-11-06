import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GPTModerationResult {
  final bool blocked;
  final bool pending;
  final List<String> reasons;
  final String? explanation;
  final int? statusCode;

  const GPTModerationResult({
    required this.blocked,
    this.pending = false,
    this.reasons = const [],
    this.explanation,
    this.statusCode,
  });

  bool get approved => !blocked && !pending;

  static const approvedResult = GPTModerationResult(blocked: false);
  static const pendingResult =
      GPTModerationResult(blocked: false, pending: true);

  static GPTModerationResult blockedResult(
    List<String> reasons, {
    String? explanation,
    int? statusCode,
  }) =>
      GPTModerationResult(
        blocked: true,
        reasons: reasons,
        explanation: explanation,
        statusCode: statusCode,
      );
}

/// Text moderation client. The OpenAI credential stays inside the authenticated
/// `moderate-text` Supabase Edge Function and is never shipped to the app.
class GPTTextModerationService {
  final SupabaseClient _supabase;

  GPTTextModerationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<GPTModerationResult> moderateText({
    required String content,
    String contentType = 'post',
    bool failClosed = true,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return GPTModerationResult.approvedResult;

    try {
      final response = await _supabase.functions.invoke(
        'moderate-text',
        body: {
          'content': trimmed,
          'contentType': contentType,
        },
      );

      if (response.status != 200 || response.data is! Map) {
        return failClosed
            ? GPTModerationResult.pendingResult
            : GPTModerationResult.approvedResult;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final reasons = (data['reasons'] as List?)
              ?.map((reason) => reason.toString())
              .toList() ??
          const <String>[];

      if (data['pending'] == true) {
        return GPTModerationResult(
          blocked: false,
          pending: true,
          reasons: reasons,
          statusCode: response.status,
        );
      }

      if (data['blocked'] == true) {
        return GPTModerationResult.blockedResult(
          reasons,
          explanation: data['explanation'] as String?,
          statusCode: response.status,
        );
      }

      return GPTModerationResult.approvedResult;
    } catch (error) {
      if (kDebugMode) debugPrint('Text moderation function failed: $error');
      return failClosed
          ? GPTModerationResult.pendingResult
          : GPTModerationResult.approvedResult;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HiveAIModerationResult {
  final bool blocked;
  final bool pending;
  final List<String> reasons;
  final Map<String, double> scores;
  final int? statusCode;

  const HiveAIModerationResult({
    required this.blocked,
    this.pending = false,
    this.reasons = const [],
    this.scores = const {},
    this.statusCode,
  });

  bool get approved => !blocked && !pending;

  static const approvedResult = HiveAIModerationResult(blocked: false);
  static const pendingResult =
      HiveAIModerationResult(blocked: false, pending: true);

  static HiveAIModerationResult blockedResult(
    List<String> reasons, {
    Map<String, double>? scores,
    int? statusCode,
  }) =>
      HiveAIModerationResult(
        blocked: true,
        reasons: reasons,
        scores: scores ?? const {},
        statusCode: statusCode,
      );
}

/// Image moderation client. Image downloads and the Hive API credential remain
/// inside the authenticated `moderate-image` Supabase Edge Function.
class HiveAIService {
  final SupabaseClient _supabase;

  HiveAIService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<HiveAIModerationResult> moderateImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) return HiveAIModerationResult.approvedResult;

    try {
      final response = await _supabase.functions.invoke(
        'moderate-image',
        body: {'imageUrl': imageUrl.trim()},
      );

      if (response.status != 200 || response.data is! Map) {
        return HiveAIModerationResult.pendingResult;
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final reasons = (data['reasons'] as List?)
              ?.map((reason) => reason.toString())
              .toList() ??
          const <String>[];
      final rawScores = data['scores'] as Map? ?? const {};
      final scores = <String, double>{};
      for (final entry in rawScores.entries) {
        if (entry.value is num) {
          scores[entry.key.toString()] = (entry.value as num).toDouble();
        }
      }

      if (data['pending'] == true) {
        return HiveAIModerationResult(
          blocked: false,
          pending: true,
          reasons: reasons,
          scores: scores,
          statusCode: response.status,
        );
      }
      if (data['blocked'] == true) {
        return HiveAIModerationResult.blockedResult(
          reasons,
          scores: scores,
          statusCode: response.status,
        );
      }

      return HiveAIModerationResult.approvedResult;
    } catch (error) {
      if (kDebugMode) debugPrint('Image moderation function failed: $error');
      return HiveAIModerationResult.pendingResult;
    }
  }

  Future<List<HiveAIModerationResult>> moderateImages(
    List<String> imageUrls,
  ) =>
      Future.wait(imageUrls.map(moderateImage));

  Future<HiveAIModerationResult> moderateImagesAny(
    List<String> imageUrls,
  ) async {
    final results = await moderateImages(imageUrls);
    for (final result in results) {
      if (result.blocked || result.pending) return result;
    }
    return HiveAIModerationResult.approvedResult;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../core/env.dart';

/// Result object for Hive AI image moderation
class HiveAIModerationResult {
  final bool blocked;
  final List<String> reasons;
  final Map<String, double> scores;
  final int? statusCode;

  const HiveAIModerationResult({
    required this.blocked,
    this.reasons = const [],
    this.scores = const {},
    this.statusCode,
  });

  bool get approved => !blocked;

  static const approvedResult = HiveAIModerationResult(blocked: false);

  static HiveAIModerationResult blockedResult(
    List<String> reasons, {
    Map<String, double>? scores,
    int? statusCode,
  }) =>
      HiveAIModerationResult(
        blocked: true,
        reasons: reasons,
        scores: scores ?? {},
        statusCode: statusCode,
      );
}

/// Hive AI Image Moderation Service (API v3)
/// Provides accurate NSFW/inappropriate content detection for images
/// API v3 pricing: $3 per 1,000 images
class HiveAIService {
  static const String _baseUrl =
      'https://api.thehive.ai/api/v3/sync/moderation';
  static String get _apiKey => AppEnv.hiveAIAPIKey;

  // Cache for moderation results (URL hash -> result)
  static const int _cacheCapacity = 500;
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  // Rate limiting
  // NOTE: Hive AI actual limit depends on your plan (Basic: 300/min, Pro: 1000/min)
  // Set conservatively to avoid hitting limits, adjust based on your plan
  static const int _maxCallsPerMinute =
      300; // Increased from 50 to 300 (Basic plan limit)
  static final List<DateTime> _apiCallTimestamps = <DateTime>[];
  static DateTime? _cooldownUntil;

  /// Moderation thresholds for different content types
  /// Higher score = more likely to be inappropriate
  static const Map<String, double> _thresholds = {
    // Sexual content (strict)
    'yes_sexual_activity': 0.85,
    'yes_sexual_nudity': 0.85,
    'animated_sexual_activity': 0.90,

    // Suggestive content (moderate)
    'general_suggestive': 0.92,

    // Violence (strict)
    'yes_blood': 0.80,
    'yes_gore': 0.75,
    'yes_violence': 0.85,

    // Other inappropriate
    'yes_drugs': 0.88,
    'yes_weapon': 0.90,
    'yes_hate_symbols': 0.70,
  };

  static String _hash(String url) => sha1.convert(utf8.encode(url)).toString();

  static HiveAIModerationResult? _getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Cache TTL: 1 hour (images don't change URLs often)
    if (DateTime.now().difference(entry.ts) > const Duration(hours: 1)) {
      _cache.remove(key);
      return null;
    }
    return entry.result;
  }

  static void _putCache(String key, HiveAIModerationResult result) {
    if (_cache.length >= _cacheCapacity) {
      // Remove oldest entry
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.ts.isBefore(b.value.ts) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }
    _cache[key] = _CacheEntry(result);
  }

  static bool _underCooldown() =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  static void _registerApiCall() {
    final now = DateTime.now();
    _apiCallTimestamps.add(now);
    _apiCallTimestamps.removeWhere(
      (t) => now.difference(t) > const Duration(seconds: 60),
    );
  }

  static bool _wouldExceedRateLimit() {
    final now = DateTime.now();
    _apiCallTimestamps.removeWhere(
      (t) => now.difference(t) > const Duration(seconds: 60),
    );
    return _apiCallTimestamps.length >= _maxCallsPerMinute;
  }

  /// Moderate a single image URL
  /// Returns HiveAIModerationResult with blocking decision
  Future<HiveAIModerationResult> moderateImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) {
      return HiveAIModerationResult.approvedResult;
    }

    // Check if API key is configured
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Hive AI API key not configured - approving image by default',
        );
      }
      return HiveAIModerationResult.approvedResult;
    }

    // Check cache
    final cacheKey = _hash(imageUrl);
    final cached = _getCached(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        debugPrint(
          '🗂️ Hive AI cache hit for image (blocked=${cached.blocked})',
        );
      }
      return cached;
    }

    // Check rate limits
    if (_underCooldown()) {
      if (kDebugMode) {
        debugPrint('⏳ Hive AI cooldown active - approving image');
      }
      return HiveAIModerationResult.approvedResult;
    }

    if (_wouldExceedRateLimit()) {
      if (kDebugMode) {
        debugPrint('⏳ Hive AI rate limit - approving image');
      }
      return HiveAIModerationResult.approvedResult;
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '🔍 Hive AI: Moderating image: ${imageUrl.substring(0, 50)}...',
        );
        debugPrint(
          '🔑 Hive AI API key configured: ${_apiKey.isNotEmpty ? "YES (${_apiKey.length} chars)" : "NO"}',
        );
      }

      // Hive AI v3 API - Download image and send as base64
      // Note: v3 API requires image data, not just URL
      if (kDebugMode) {
        debugPrint('📥 Downloading image from Supabase...');
      }

      final imageResponse = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 10));

      if (imageResponse.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('❌ Failed to download image: ${imageResponse.statusCode}');
        }
        return HiveAIModerationResult.approvedResult;
      }

      final imageBytes = imageResponse.bodyBytes;

      // Check if image is too large (Hive AI has a 5MB limit per image)
      const maxImageSize = 5 * 1024 * 1024; // 5MB
      if (imageBytes.length > maxImageSize) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Image too large (${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB) - skipping moderation',
          );
        }
        return HiveAIModerationResult.approvedResult;
      }

      final base64Image = base64Encode(imageBytes);

      if (kDebugMode) {
        debugPrint(
          '✅ Image downloaded (${(imageBytes.length / 1024).toStringAsFixed(1)}KB, base64: ${base64Image.length} chars)',
        );
      }

      // Determine media type from URL or default to image/jpeg
      String mediaType = 'image/jpeg';
      if (imageUrl.toLowerCase().endsWith('.png')) {
        mediaType = 'image/png';
      } else if (imageUrl.toLowerCase().endsWith('.gif')) {
        mediaType = 'image/gif';
      } else if (imageUrl.toLowerCase().endsWith('.webp')) {
        mediaType = 'image/webp';
      }

      final requestBody = jsonEncode({
        'media': [
          {'data': base64Image, 'media_type': mediaType},
        ],
      });

      if (kDebugMode) {
        debugPrint('📤 Sending to Hive AI v3 API (media_type: $mediaType)...');
        debugPrint('   URL: $_baseUrl');
        debugPrint('   Payload size: ${requestBody.length} bytes');
        debugPrint('   Authorization: token ${_apiKey.substring(0, 10)}...');
      }

      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'accept': 'application/json',
          'authorization': 'token $_apiKey',
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-App/1.0',
        },
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 30), // Increased timeout for large images
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏰ Hive AI request timed out after 30s');
          }
          throw http.ClientException('Request timeout');
        },
      );

      if (kDebugMode) {
        debugPrint('📨 Hive AI response: ${response.statusCode}');
      }

      _registerApiCall();

      if (response.statusCode == 429) {
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
        if (kDebugMode) {
          debugPrint('⏳ Hive AI rate limit (429) - setting cooldown');
        }
        return HiveAIModerationResult.approvedResult;
      }

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            '❌ Hive AI error: ${response.statusCode} - ${response.body}',
          );
        }
        return HiveAIModerationResult.approvedResult;
      }

      final result = jsonDecode(response.body);

      // Parse Hive AI v3 response format
      // v3 returns: { "media": [{ "classes": {...}, "status": "success" }] }
      final media = result['media'] as List?;
      if (media == null || media.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Hive AI: No media in response');
        }
        return HiveAIModerationResult.approvedResult;
      }

      final firstMedia = media[0] as Map<String, dynamic>;
      final status = firstMedia['status'] as String?;

      if (status != 'success') {
        if (kDebugMode) {
          debugPrint('⚠️ Hive AI: Processing failed - status: $status');
        }
        return HiveAIModerationResult.approvedResult;
      }

      final classes = firstMedia['classes'] as Map<String, dynamic>?;
      if (classes == null || classes.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Hive AI: No classes in response');
        }
        return HiveAIModerationResult.approvedResult;
      }

      // Check scores against thresholds
      final reasons = <String>[];
      final scores = <String, double>{};

      classes.forEach((className, scoreValue) {
        final score = (scoreValue as num).toDouble();
        scores[className] = score;

        // Check if this class exceeds threshold
        final threshold = _thresholds[className];
        if (threshold != null && score >= threshold) {
          reasons.add('$className (${(score * 100).toStringAsFixed(1)}%)');
        }
      });

      if (reasons.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🚫 Hive AI BLOCKED image: ${reasons.join(', ')}');
        }
        final blockedResult = HiveAIModerationResult.blockedResult(
          reasons,
          scores: scores,
          statusCode: response.statusCode,
        );
        _putCache(cacheKey, blockedResult);
        return blockedResult;
      }

      if (kDebugMode) {
        debugPrint('✅ Hive AI approved image');
      }
      _putCache(cacheKey, HiveAIModerationResult.approvedResult);
      return HiveAIModerationResult.approvedResult;
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hive AI network error: $e');
        debugPrint('   This usually means:');
        debugPrint('   1. No internet connection');
        debugPrint('   2. Hive AI API is down');
        debugPrint('   3. CORS issue (if running on web)');
        debugPrint('   4. Invalid API endpoint');
      }
      // Fail open for availability
      return HiveAIModerationResult.approvedResult;
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hive AI JSON parsing error: $e');
        debugPrint('   Response format may have changed');
      }
      return HiveAIModerationResult.approvedResult;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Hive AI unexpected exception: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
      // Fail open for availability
      return HiveAIModerationResult.approvedResult;
    }
  }

  /// Moderate multiple images in parallel
  /// Returns list of results in same order as input URLs
  Future<List<HiveAIModerationResult>> moderateImages(
    List<String> imageUrls,
  ) async {
    if (imageUrls.isEmpty) return [];

    // Process all images in parallel for speed
    final futures = imageUrls.map((url) => moderateImage(url)).toList();
    return await Future.wait(futures);
  }

  /// Check if any image in the list is blocked
  /// Returns the first blocked result, or approved if all pass
  Future<HiveAIModerationResult> moderateImagesAny(
    List<String> imageUrls,
  ) async {
    final results = await moderateImages(imageUrls);

    for (final result in results) {
      if (result.blocked) {
        return result;
      }
    }

    return HiveAIModerationResult.approvedResult;
  }
}

class _CacheEntry {
  final HiveAIModerationResult result;
  final DateTime ts;
  _CacheEntry(this.result) : ts = DateTime.now();
}

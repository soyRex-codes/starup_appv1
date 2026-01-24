import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../core/env.dart';

/// Result object for GPT-based content moderation
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

/// Improved Text Moderation using GPT-4o-mini
/// More nuanced and context-aware than OpenAI Moderation API
/// Cost: ~$0.03 per 1,000 posts (vs frequent false positives with Moderation API)
class GPTTextModerationService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';
  static String get _apiKey => AppEnv.openAIAPIKey;

  // Cache for moderation results
  static const int _cacheCapacity = 300;
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  // Rate limiting
  static const int _maxCallsPerMinute = 60;
  static final List<DateTime> _apiCallTimestamps = <DateTime>[];
  static DateTime? _cooldownUntil;

  static String _hash(String content) =>
      sha1.convert(utf8.encode(content)).toString();

  static GPTModerationResult? _getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Cache TTL: 1 hour
    if (DateTime.now().difference(entry.ts) > const Duration(hours: 1)) {
      _cache.remove(key);
      return null;
    }
    return entry.result;
  }

  static void _putCache(String key, GPTModerationResult result) {
    if (_cache.length >= _cacheCapacity) {
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
    _apiCallTimestamps
        .removeWhere((t) => now.difference(t) > const Duration(seconds: 60));
  }

  static bool _wouldExceedRateLimit() {
    final now = DateTime.now();
    _apiCallTimestamps
        .removeWhere((t) => now.difference(t) > const Duration(seconds: 60));
    return _apiCallTimestamps.length >= _maxCallsPerMinute;
  }

  /// Moderate text content using GPT-4o-mini with context-aware analysis
  Future<GPTModerationResult> moderateText({
    required String content,
    String contentType = 'post', // 'post', 'message', 'comment'
    bool failClosed = true,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return GPTModerationResult.approvedResult;

    // Check if API key is configured
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('OpenAI API key not configured - approving content');
      }
      return GPTModerationResult.approvedResult;
    }

    // Check cache
    final cacheKey = _hash('$contentType:$trimmed');
    final cached = _getCached(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        debugPrint('GPT moderation cache hit (blocked=${cached.blocked})');
      }
      return cached;
    }

    // Check rate limits
    if (_underCooldown()) {
      if (kDebugMode) {
        debugPrint('GPT moderation cooldown active');
      }
      return failClosed
          ? GPTModerationResult.pendingResult
          : GPTModerationResult.approvedResult;
    }

    if (_wouldExceedRateLimit()) {
      if (kDebugMode) {
        debugPrint('GPT moderation rate limit');
      }
      return failClosed
          ? GPTModerationResult.pendingResult
          : GPTModerationResult.approvedResult;
    }

    try {
      if (kDebugMode) {
        debugPrint('GPT: Moderating $contentType (${trimmed.length} chars)');
      }

      final systemPrompt = _buildSystemPrompt(contentType);

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': trimmed},
              ],
              'temperature': 0.3,
              'max_tokens': 150,
            }),
          )
          .timeout(const Duration(seconds: 15));

      _registerApiCall();

      if (response.statusCode == 429) {
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
        if (kDebugMode) {
          debugPrint('GPT rate limit (429)');
        }
        return failClosed
            ? GPTModerationResult.pendingResult
            : GPTModerationResult.approvedResult;
      }

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('GPT moderation error: ${response.statusCode}');
        }
        return failClosed
            ? GPTModerationResult.pendingResult
            : GPTModerationResult.approvedResult;
      }

      final result = jsonDecode(response.body);
      final choices = result['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return GPTModerationResult.approvedResult;
      }

      final message = choices[0]['message'];
      final responseText = message['content'] as String;

      // Parse JSON response from GPT
      final moderationData = jsonDecode(responseText);
      final shouldBlock = moderationData['block'] as bool? ?? false;
      final severity = moderationData['severity'] as String? ?? 'none';
      final categories = (moderationData['categories'] as List?)
              ?.map((c) => c.toString())
              .toList() ??
          [];
      final explanation = moderationData['explanation'] as String?;

      if (shouldBlock) {
        if (kDebugMode) {
          debugPrint(
              'GPT BLOCKED $contentType: $categories (severity: $severity)');
        }
        final blockedResult = GPTModerationResult.blockedResult(
          categories,
          explanation: explanation,
          statusCode: response.statusCode,
        );
        _putCache(cacheKey, blockedResult);
        return blockedResult;
      }

      if (kDebugMode) {
        debugPrint('GPT approved $contentType');
      }
      _putCache(cacheKey, GPTModerationResult.approvedResult);
      return GPTModerationResult.approvedResult;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GPT moderation exception: $e');
      }
      return failClosed
          ? GPTModerationResult.pendingResult
          : GPTModerationResult.approvedResult;
    }
  }

  String _buildSystemPrompt(String contentType) {
    return '''You are a content moderator for a professional startup/founder community platform.

Analyze the following $contentType and determine if it should be blocked.

BLOCK if content contains:
- Explicit sexual content or pornography
- Graphic violence or gore
- Hate speech or severe harassment
- Threats or incitement to violence
- Illegal activities (drugs, weapons sales, etc.)
- Spam or malicious links
- Severe profanity used as attack

ALLOW if content contains:
- Professional business discussions
- Constructive criticism or debate
- Mild profanity in casual context
- Startup/founder topics
- Networking or collaboration requests
- Personal stories or experiences
- Questions or advice seeking

Context matters: Consider the overall message, not just individual words.

Respond ONLY with a valid JSON object in this exact format:
{
  "block": true/false,
  "severity": "none|low|medium|high",
  "categories": ["category1", "category2"],
  "explanation": "brief reason if blocked"
}

Examples:
- Spam: {"block": true, "severity": "medium", "categories": ["spam"], "explanation": "promotional content"}
- Swearing in context: {"block": false, "severity": "none", "categories": [], "explanation": ""}
- Hate speech: {"block": true, "severity": "high", "categories": ["hate"], "explanation": "discriminatory language"}''';
  }
}

class _CacheEntry {
  final GPTModerationResult result;
  final DateTime ts;
  _CacheEntry(this.result) : ts = DateTime.now();
}

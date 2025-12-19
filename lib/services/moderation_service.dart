import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../core/env.dart';
import 'hive_ai_service.dart';
import 'gpt_text_moderation_service.dart';
import 'local_text_filter_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result object for a moderation decision
class ModerationResult {
  final bool blocked; // TRUE = block immediately
  final bool pending; // TRUE = treat as pending (fallback state)
  final List<String> reasons; // Human‑readable reasons / categories
  final int? statusCode; // HTTP status for debugging
  final String? rawCategoryJson; // Raw categories JSON for logging/analytics

  const ModerationResult({
    required this.blocked,
    this.pending = false,
    this.reasons = const [],
    this.statusCode,
    this.rawCategoryJson,
  });

  bool get approved => !blocked && !pending;

  static const approvedResult = ModerationResult(blocked: false);
  static const pendingResult = ModerationResult(blocked: false, pending: true);
  static ModerationResult blockedResult(List<String> reasons,
          {int? statusCode, String? raw}) =>
      ModerationResult(
          blocked: true,
          reasons: reasons,
          statusCode: statusCode,
          rawCategoryJson: raw);
}

/// Simple content moderation service using OpenAI Moderation API
class ModerationService {
  static const String _baseUrl = 'https://api.openai.com/v1/moderations';
  static const String _model = 'omni-moderation-latest';
  static String get _apiKey => AppEnv.openAIAPIKey;

  // Extremely obvious disallowed terms (lower-case, no punctuation). Keep short & targeted.
  static final List<RegExp> _hardBlockPatterns = [
    // Sexual explicit
    RegExp(r'\b(porn|porno|hardcore|xxx|gangbang)s?\b'),
    RegExp(r'\b(nude|nudity|naked)\b'),
    RegExp(r'\b(anal|cumshot|blowjob|handjob)\b'),
    // Profanity sexual emphasis
    RegExp(r'\b(fuck|fuxk|f\*+k|motherf\w+)\b'),
    // Child / extreme (immediate block)
    RegExp(r'\b(cp|child porn|underage)\b'),
  ];

  static List<String> _localBlockReasons(String content) {
    final lc = content.toLowerCase();
    final reasons = <String>[];
    for (final p in _hardBlockPatterns) {
      if (p.hasMatch(lc)) {
        reasons
            .add('Matched explicit term: ${p.pattern.replaceAll('\\b', '')}');
      }
    }
    return reasons.toSet().toList();
  }

  // ------------ Runtime Rate & Cache Controls ---------------
  static const int _maxApiCallsPerMinute = 40; // Soft client-side throttle
  static const int _cacheCapacity = 200;
  static final List<DateTime> _apiCallTimestamps =
      <DateTime>[]; // rotating window
  static final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  static DateTime? _cooldownUntil; // Set after 429 responses

  static bool _underCooldown() =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  static void _registerApiCall() {
    final now = DateTime.now();
    _apiCallTimestamps.add(now);
    // Drop entries older than 60s
    _apiCallTimestamps
        .removeWhere((t) => now.difference(t) > const Duration(seconds: 60));
  }

  static bool _wouldExceedRateLimit() {
    final now = DateTime.now();
    _apiCallTimestamps
        .removeWhere((t) => now.difference(t) > const Duration(seconds: 60));
    return _apiCallTimestamps.length >= _maxApiCallsPerMinute;
  }

  static String _hash(String content) =>
      sha1.convert(utf8.encode(content)).toString();

  static ModerationResult? _getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    // Cache TTL (optional) – keep for 30 minutes
    if (DateTime.now().difference(entry.ts) > const Duration(minutes: 30)) {
      _cache.remove(key);
      return null;
    }
    return entry.result;
  }

  static void _putCache(String key, ModerationResult r) {
    if (_cache.length >= _cacheCapacity) {
      // Simple eviction: remove oldest
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.ts.isBefore(b.value.ts) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }
    _cache[key] = _CacheEntry(r);
  }

  // ---------------- Two-tier Orchestrator (local -> remote) -----------------
  // High-risk keywords => immediate flag, skip API (escalate=false because it's obvious)
  static const List<String> _highRiskKeywords = [
    'child porn',
    'underage',
    'cp',
    'rape',
    'bestiality',
    'incest',
    'suicide instructions',
    'kill yourself',
    'bomb recipe'
  ];

  // Soft-risk keywords => trigger remote API but not auto flag
  static const List<String> _softRiskKeywords = [
    'sex',
    'sexual',
    'nude',
    'naked',
    'porn',
    'suicide',
    'self-harm',
    'cutting',
    'violent',
    'kill',
    'murder',
    'hate',
    'racist',
    'terror',
    'bomb',
    'shoot'
  ];

  // Cache for orchestrated responses separate namespace
  static final Map<String, Map<String, dynamic>> _orchestratorCache = {};

  /// Two-tier moderation orchestrator per spec.
  /// Output JSON shape:
  /// {
  ///  "flagged": bool,
  ///  "escalate": bool,               // true only if external API indicates severe category
  ///  "local_hits": [list of matched local keywords],
  ///  "api_categories": { ... } | null,
  ///  "final_reason": string
  /// }
  /// If external call skipped (high-risk local) => api_categories=null, escalate=false.
  Future<Map<String, dynamic>> orchestrateModeration(String content) async {
    final original = content;
    final text = original.trim();
    if (text.isEmpty) {
      return {
        'flagged': false,
        'escalate': false,
        'local_hits': <String>[],
        'api_categories': null,
        'final_reason': 'empty'
      };
    }

    final lower = text.toLowerCase();
    final localHits = <String>[];

    bool matchWholeWord(String kw) {
      // if keyword has space treat as phrase search; else enforce word boundary
      if (kw.contains(' ')) return lower.contains(kw);
      final re = RegExp(r'(?<![a-z0-9])' + RegExp.escape(kw) + r'(?![a-z0-9])');
      return re.hasMatch(lower);
    }

    // 1. Check high-risk
    for (final kw in _highRiskKeywords) {
      if (matchWholeWord(kw)) {
        localHits.add(kw);
      }
    }
    if (localHits.isNotEmpty) {
      return {
        'flagged': true,
        'escalate':
            false, // obvious disallow; no need for remote severity escalation
        'local_hits': localHits,
        'api_categories': null,
        'final_reason': 'keyword:${localHits.join(',')}'
      };
    }

    // 2. Check soft-risk
    final softHits = <String>[];
    for (final kw in _softRiskKeywords) {
      if (matchWholeWord(kw)) softHits.add(kw);
    }

    final needsApi = softHits.isNotEmpty ||
        softHits.isEmpty; // always true unless high-risk triggered

    // 3. Cache lookup (by SHA1 of text and presence of soft hits)
    final orchestratorKey =
        'orc:${_hash('v1|${softHits.join('|')}|$text')}';
    final cached = _orchestratorCache[orchestratorKey];
    if (cached != null) {
      if (kDebugMode) debugPrint('🗂️ Orchestrator cache hit');
      return cached;
    }

    if (!needsApi) {
      // Should not happen with current logic, but keep for completeness
      final result = {
        'flagged': false,
        'escalate': false,
        'local_hits': softHits,
        'api_categories': null,
        'final_reason':
            softHits.isEmpty ? 'clean_local' : 'soft_hits:${softHits.join(',')}'
      };
      _orchestratorCache[orchestratorKey] = result;
      return result;
    }

    // 4. Remote API path (unless under cooldown / rate limited -> skip gracefully)
    if (_apiKey.isEmpty) {
      final result = {
        'flagged': false,
        'escalate': false,
        'local_hits': softHits,
        'api_categories': null,
        'final_reason':
            softHits.isEmpty ? 'clean_local_no_api_key' : 'soft_hits_no_api_key'
      };
      _orchestratorCache[orchestratorKey] = result;
      return result;
    }

    if (_underCooldown() || _wouldExceedRateLimit()) {
      final result = {
        'flagged': false, // we have no strong evidence yet
        'escalate': false,
        'local_hits': softHits,
        'api_categories': null,
        'final_reason':
            _underCooldown() ? 'cooldown_skip' : 'local_rate_throttle_skip'
      };
      _orchestratorCache[orchestratorKey] = result;
      return result;
    }

    try {
      final resp = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'model': _model, 'input': text}),
          )
          .timeout(const Duration(seconds: 12));

      _registerApiCall();

      if (resp.statusCode == 429) {
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 12));
        final result = {
          'flagged': false,
          'escalate': false,
          'local_hits': softHits,
          'api_categories': null,
          'final_reason': 'api_429_skip'
        };
        _orchestratorCache[orchestratorKey] = result;
        return result;
      }
      if (resp.statusCode != 200) {
        final result = {
          'flagged': false,
          'escalate': false,
          'local_hits': softHits,
          'api_categories': null,
          'final_reason': 'api_error_${resp.statusCode}'
        };
        _orchestratorCache[orchestratorKey] = result;
        return result;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List).cast<Map>();
      // Merge categories across results (usually 1)
      final mergedCategories = <String, dynamic>{};
      bool apiFlagged = false;
      bool escalate = false;

      const severeKeys = [
        'sexual/minors',
        'self-harm',
        'violence',
        'hate',
        'hate/threatening'
      ];

      for (final r in results) {
        if (r['flagged'] == true) apiFlagged = true;
        final cats = (r['categories'] as Map?)?.cast<String, dynamic>() ?? {};
        cats.forEach((k, v) {
          // Keep true if any result reports true
          if (mergedCategories.containsKey(k)) {
            if (v == true) mergedCategories[k] = true;
          } else {
            mergedCategories[k] = v;
          }
        });
        final scores = (r['category_scores'] as Map<String, dynamic>?) ?? {};
        scores.forEach((k, v) {
          final score = (v is num) ? v.toDouble() : 0.0;
          // Reuse thresholds from earlier logic
          double? threshold;
          if (k.contains('sexual/minors')) {
            threshold = 0.20;
          } else if (k.contains('self-harm')) {
            threshold = 0.45;
          } else if (k.contains('hate')) {
            threshold = 0.60;
          } else if (k.contains('sexual')) {
            threshold = 0.65;
          } else if (k.contains('violence')) {
            threshold = 0.70;
          }
          if (threshold != null && score >= threshold) {
            apiFlagged = true;
            if (severeKeys.any((sev) => k.contains(sev))) {
              escalate = true;
            }
          }
        });
      }

      final finalReason = apiFlagged
          ? (escalate ? 'api_severe_flag' : 'api_flag')
          : (softHits.isNotEmpty ? 'soft_hits:${softHits.join(',')}' : 'clean');

      final result = {
        'flagged': apiFlagged,
        'escalate': escalate,
        'local_hits': softHits,
        'api_categories': mergedCategories.isEmpty ? {} : mergedCategories,
        'final_reason': finalReason,
      };
      _orchestratorCache[orchestratorKey] = result;
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Orchestrator exception: $e');
      final result = {
        'flagged': false,
        'escalate': false,
        'local_hits': softHits,
        'api_categories': null,
        'final_reason': 'api_exception'
      };
      _orchestratorCache[orchestratorKey] = result;
      return result;
    }
  }

  /// Quick debug ping to verify key validity (returns true if 200)
  Future<bool> verifyApiKey() async {
    if (_apiKey.isEmpty) return false;
    try {
      final resp = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'input': 'ping',
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (kDebugMode) {
        debugPrint('🔐 Moderation verify status: ${resp.statusCode}');
      }
      return resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('🔐 Moderation verify failed: $e');
      return false;
    }
  }

  /// Core moderation wrapper using 3-layer approach:
  /// LAYER 1: Local word filter (instant, free, catches obvious violations)
  /// LAYER 2: GPT-4o-mini (context-aware AI, reduces false positives)
  /// LAYER 3: Hive AI (for images only, called separately)
  ///
  /// This saves API costs by blocking ~60-70% of violations locally
  /// failClosed=true => if API fails, we return pending (NOT auto-approved).
  Future<ModerationResult> moderateText({
    required String content,
    bool failClosed = true,
    String contentType = 'post',
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return ModerationResult.approvedResult;

    // ========================================================================
    // LAYER 1: Local word filter (FIRST - catches 60-70% of violations)
    // ========================================================================
    // This is FREE and INSTANT - no API calls needed
    final localFilterResult = LocalTextFilterService.filterText(
      trimmed,
      contentType: contentType,
    );

    // If blocked by local filter, stop immediately (save API costs!)
    if (localFilterResult.blocked) {
      if (kDebugMode) {
        debugPrint(
            '🚫 LAYER 1 BLOCKED: ${localFilterResult.categories.join(", ")} '
            '(matched: ${localFilterResult.matchedTerms.take(3).join(", ")})');
      }
      return ModerationResult.blockedResult(localFilterResult.categories);
    }

    // If flagged for manual review, mark as pending
    if (localFilterResult.needsReview) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ LAYER 1 FLAGGED: ${localFilterResult.categories.join(", ")} '
            '- Needs manual review');
      }
      // For now, let it pass to GPT for second opinion
    }

    // ========================================================================
    // LAYER 2: GPT-4o-mini moderation (context-aware AI)
    // ========================================================================
    // Only called if local filter passes (saves ~60-70% of API calls!)
    if (kDebugMode) {
      debugPrint('✅ LAYER 1 PASSED → Checking LAYER 2 (GPT-4o-mini)...');
    }

    final gptService = GPTTextModerationService();
    final gptResult = await gptService.moderateText(
      content: trimmed,
      contentType: contentType,
      failClosed: failClosed,
    );

    // Convert GPTModerationResult to ModerationResult
    if (gptResult.blocked) {
      if (kDebugMode) {
        debugPrint('🚫 LAYER 2 BLOCKED: ${gptResult.reasons.join(", ")}');
      }
      return ModerationResult.blockedResult(
        gptResult.reasons,
        statusCode: gptResult.statusCode,
      );
    }

    if (gptResult.pending) {
      if (kDebugMode) {
        debugPrint('⚠️ LAYER 2 PENDING: Manual review needed');
      }
      return ModerationResult.pendingResult;
    }

    if (kDebugMode) {
      debugPrint('✅ LAYER 2 PASSED: Content approved');
    }

    return ModerationResult.approvedResult;
  }

  /// Legacy moderation using OpenAI Moderation API (kept for fallback)
  /// Use moderateText() instead for better accuracy
  @Deprecated('Use moderateText() which now uses GPT-4o-mini')
  Future<ModerationResult> moderateTextLegacy({
    required String content,
    bool failClosed = true,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return ModerationResult.approvedResult;

    // 1. Local heuristic block first (fast path)
    final localReasons = _localBlockReasons(trimmed);
    if (localReasons.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('🚫 Local moderation blocked: ${localReasons.join('; ')}');
      }
      return ModerationResult.blockedResult(localReasons);
    }

    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ No OpenAI key; treating as approved (dev fallback)');
      }
      return ModerationResult.approvedResult;
    }

    // 2. Cache lookup
    final cacheKey = _hash(trimmed);
    final cached = _getCached(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        debugPrint(
            '🗂️ Moderation cache hit (blocked=${cached.blocked}, pending=${cached.pending})');
      }
      return cached;
    }

    // 3. Cooldown / rate-limit check BEFORE hitting API
    if (_underCooldown()) {
      if (kDebugMode) {
        debugPrint('⏳ Skipping remote moderation (cooldown active)');
      }
      final pendingOrApproved = failClosed
          ? ModerationResult.pendingResult
          : ModerationResult.approvedResult;
      _putCache(cacheKey, pendingOrApproved);
      return pendingOrApproved;
    }
    if (_wouldExceedRateLimit()) {
      if (kDebugMode) {
        debugPrint('⏳ Local throttle: too many moderation calls this minute');
      }
      final pendingOrApproved = failClosed
          ? ModerationResult.pendingResult
          : ModerationResult.approvedResult;
      _putCache(cacheKey, pendingOrApproved);
      return pendingOrApproved;
    }
    try {
      final resp = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'input': trimmed,
            }),
          )
          .timeout(const Duration(seconds: 12));

      _registerApiCall();

      if (resp.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('⚠️ Moderation HTTP ${resp.statusCode}: ${resp.body}');
        }
        if (resp.statusCode == 429) {
          // Backoff: shorter cooldown to reduce user friction
          _cooldownUntil = DateTime.now().add(const Duration(seconds: 12));
        }
        return failClosed
            ? ModerationResult.pendingResult
            : ModerationResult.approvedResult;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List).cast<Map>();
      bool anyFlagged = false;
      final reasons = <String>[];
      for (final r in results) {
        if (r['flagged'] == true) {
          anyFlagged = true;
          final cats = r['categories'] as Map<String, dynamic>?;
          if (cats != null) {
            cats.forEach((k, v) {
              if (v == true) reasons.add(k);
            });
          }
        }
        // Evaluate category_scores for additional heuristic blocking (OpenAI sometimes leaves flagged=false with high-risk category scores)
        final scores = (r['category_scores'] as Map<String, dynamic>?) ?? {};

        // Category-specific thresholds (more nuanced than single global threshold)
        const categoryThresholds = <String, double>{
          // lower threshold for self-harm to be more cautious
          'self-harm': 0.45,
          // explicit sexual content (not minors)
          'sexual': 0.65,
          // hate / harassment categories
          'hate': 0.60,
          // violence content
          'violence': 0.70,
          // sexual content involving minors (very strict)
          'sexual/minors': 0.20,
        };

        scores.forEach((k, v) {
          final rawScore = (v is num) ? v.toDouble() : 0.0;
          if (rawScore <= 0) return;

          // Find first matching configured category key (substring match)
          for (final entry in categoryThresholds.entries) {
            if (k.contains(entry.key)) {
              final threshold = entry.value;
              if (rawScore >= threshold) {
                anyFlagged = true;
                reasons.add(
                    'score-$k=${rawScore.toStringAsFixed(2)}>=${threshold.toStringAsFixed(2)}');
              }
              break; // avoid double counting if multiple partial matches
            }
          }
        });
      }
      if (anyFlagged) {
        if (kDebugMode) {
          debugPrint('🚫 Moderation blocked: ${reasons.join(', ')}');
        }
        final blockedRes = ModerationResult.blockedResult(reasons,
            statusCode: resp.statusCode,
            raw: jsonEncode(results.first['categories']));
        _putCache(cacheKey, blockedRes);
        return blockedRes;
      }

      _putCache(cacheKey, ModerationResult.approvedResult);
      return ModerationResult.approvedResult;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Moderation exception: $e');
      }
      return failClosed
          ? ModerationResult.pendingResult
          : ModerationResult.approvedResult;
    }
  }

  /// Combined post moderation (text + images via Hive AI).
  /// Text is checked via OpenAI, images are checked via Hive AI for NSFW/inappropriate content.
  Future<ModerationResult> moderatePost({
    required String title,
    String? description,
    List<String> imageUrls = const [],
  }) async {
    // Step 1: Check text content first (faster, cheaper)
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) buffer.writeln('TITLE: ${title.trim()}');
    if (description != null && description.trim().isNotEmpty) {
      buffer.writeln('DESCRIPTION: ${description.trim()}');
    }

    final combinedText = buffer.toString();
    if (combinedText.trim().isNotEmpty) {
      final lowRisk = _isLowRisk(combinedText);
      final textResult =
          await moderateText(content: combinedText, failClosed: !lowRisk);

      // If text is blocked, no need to check images
      if (textResult.blocked) {
        if (kDebugMode) {
          debugPrint(
              '🚫 Post blocked due to text content: ${textResult.reasons.join(', ')}');
        }
        return textResult;
      }

      // If text is pending, mark whole post as pending
      if (textResult.pending) {
        if (kDebugMode) {
          debugPrint('⏳ Post marked as pending due to text moderation');
        }
        return textResult;
      }
    }

    // Step 2: Check images with Hive AI (if any)
    if (imageUrls.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('🔍 Checking ${imageUrls.length} image(s) with Hive AI...');
      }

      final hiveService = HiveAIService();
      final imageResult = await hiveService.moderateImagesAny(imageUrls);

      if (imageResult.blocked) {
        if (kDebugMode) {
          debugPrint(
              '🚫 Post blocked due to inappropriate images: ${imageResult.reasons.join(', ')}');
        }
        // Convert HiveAIModerationResult to ModerationResult
        return ModerationResult.blockedResult(
          imageResult.reasons.map((r) => 'Image: $r').toList(),
          statusCode: imageResult.statusCode,
        );
      }
    }

    // All checks passed
    if (kDebugMode) {
      debugPrint(
          '✅ Post approved (text and ${imageUrls.length} images checked)');
    }
    return ModerationResult.approvedResult;
  }

  /// Backwards compatibility for existing calls
  @Deprecated('Use moderateText')
  Future<bool> shouldBlockText(String content) async {
    final r = await moderateText(content: content);
    return r.blocked;
  }



  /// Report a user for violating community guidelines
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final reporterId = supabase.auth.currentUser?.id;
      if (reporterId == null) return false;

      await supabase.from('user_reports').insert({
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error reporting user: $e');
      return false;
    }
  }
}

class _CacheEntry {
  final ModerationResult result;
  final DateTime ts;
  _CacheEntry(this.result) : ts = DateTime.now();
}

/// Simple heuristic to classify very low-risk text so we can safely approve
/// when the remote moderation API is temporarily unavailable or rate-limited.
bool _isLowRisk(String text) {
  final lc = text.toLowerCase();
  // Already caught explicit terms via regex earlier; here we just check structure.
  if (lc.length > 600) return false; // long form content -> want remote
  if (RegExp(r'https?://').allMatches(lc).length > 2) {
    return false; // too many links
  }
  if (RegExp(r'[0-9]{5,}').hasMatch(lc)) return false; // large numeric blobs
  if (RegExp(r'[^a-z0-9\s,.!?:;\-\[\]\(\)\n]').allMatches(lc).length > 20) {
    return false; // excessive symbols
  }
  // If it passes these structural checks and no hard block patterns matched earlier, treat as low risk.
  return true;
}

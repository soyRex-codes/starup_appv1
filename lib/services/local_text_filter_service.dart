import 'package:flutter/foundation.dart';
import '../config/moderation_filters.dart';

/// Result of local text filtering
class LocalFilterResult {
  final bool blocked;
  final bool needsReview; // Flag for manual admin review
  final List<String> matchedTerms;
  final List<String> categories;
  final String severity; // 'high', 'medium', 'low'

  const LocalFilterResult({
    required this.blocked,
    required this.needsReview,
    required this.matchedTerms,
    required this.categories,
    required this.severity,
  });

  bool get passed => !blocked && !needsReview;

  static const LocalFilterResult clean = LocalFilterResult(
    blocked: false,
    needsReview: false,
    matchedTerms: [],
    categories: [],
    severity: 'none',
  );
}

/// Fast local text filtering before expensive AI calls
/// This is the FIRST layer of moderation - catches obvious violations instantly
class LocalTextFilterService {
  /// Check text against local filters
  /// Returns result indicating if blocked, needs review, or clean
  static LocalFilterResult filterText(String text,
      {String contentType = 'post'}) {
    if (text.trim().isEmpty) {
      return LocalFilterResult.clean;
    }

    final matchedTerms = <String>[];
    final categories = <String>{};
    String highestSeverity = 'none';

    // Normalize text for checking
    final normalizedText = ModerationFilters.normalizeText(text);
    final lowerText = text.toLowerCase();

    // Check if text has professional context (might allow some flagged terms)
    final hasProfessionalContext =
        ModerationFilters.hasProfessionalContext(text);

    // 1. Check HIGH SEVERITY terms (instant block)
    final highSeverityMatches = _checkTerms(
      lowerText,
      normalizedText,
      ModerationFilters.sexualExplicit,
      'sexual_explicit',
      hasProfessionalContext,
    );
    matchedTerms.addAll(highSeverityMatches);
    if (highSeverityMatches.isNotEmpty) {
      categories.add('sexual_explicit');
      highestSeverity = 'high';
    }

    final hateSpeechMatches = _checkTerms(
      lowerText,
      normalizedText,
      ModerationFilters.hateSpeech,
      'hate_speech',
      false, // Never allow professional context for hate speech
    );
    matchedTerms.addAll(hateSpeechMatches);
    if (hateSpeechMatches.isNotEmpty) {
      categories.add('hate_speech');
      highestSeverity = 'high';
    }

    final threatMatches = _checkTerms(
      lowerText,
      normalizedText,
      ModerationFilters.threats,
      'threats',
      false, // Never allow professional context for threats
    );
    matchedTerms.addAll(threatMatches);
    if (threatMatches.isNotEmpty) {
      categories.add('threats');
      highestSeverity = 'high';
    }

    final illegalMatches = _checkTerms(
      lowerText,
      normalizedText,
      ModerationFilters.illegalActivities,
      'illegal',
      false, // Never allow professional context for illegal activities
    );
    matchedTerms.addAll(illegalMatches);
    if (illegalMatches.isNotEmpty) {
      categories.add('illegal');
      highestSeverity = 'high';
    }

    final selfHarmMatches = _checkTerms(
      lowerText,
      normalizedText,
      ModerationFilters.selfHarm,
      'self_harm',
      false, // Never allow professional context for self-harm
    );
    matchedTerms.addAll(selfHarmMatches);
    if (selfHarmMatches.isNotEmpty) {
      categories.add('self_harm');
      highestSeverity = 'high';
    }

    // 2. Check MEDIUM SEVERITY terms (flag for review)
    if (highestSeverity != 'high') {
      final spamMatches = _checkTerms(
        lowerText,
        normalizedText,
        ModerationFilters.spam,
        'spam',
        hasProfessionalContext,
      );
      matchedTerms.addAll(spamMatches);
      if (spamMatches.isNotEmpty) {
        categories.add('spam');
        highestSeverity = 'medium';
      }

      final harassmentMatches = _checkTerms(
        lowerText,
        normalizedText,
        ModerationFilters.harassment,
        'harassment',
        hasProfessionalContext,
      );
      matchedTerms.addAll(harassmentMatches);
      if (harassmentMatches.isNotEmpty) {
        categories.add('harassment');
        highestSeverity = 'medium';
      }
    }

    // 3. Check regex patterns
    if (ModerationFilters.repeatedChars.hasMatch(text)) {
      categories.add('spam_pattern');
      if (highestSeverity == 'none') highestSeverity = 'medium';
    }

    if (ModerationFilters.excessivePunctuation.hasMatch(text)) {
      categories.add('spam_pattern');
      if (highestSeverity == 'none') highestSeverity = 'medium';
    }

    if (ModerationFilters.suspiciousUrls.hasMatch(text)) {
      categories.add('suspicious_url');
      if (highestSeverity == 'none') highestSeverity = 'medium';
    }

    // 4. Determine action based on severity
    final blocked = highestSeverity == 'high';
    final needsReview = highestSeverity == 'medium' && !hasProfessionalContext;

    if (blocked || needsReview || categories.isNotEmpty) {
      debugPrint(
          'Local Filter: ${blocked ? "BLOCKED" : needsReview ? "FLAGGED" : "DETECTED"} '
          '(severity: $highestSeverity, categories: ${categories.join(", ")}, '
          'matched: ${matchedTerms.take(3).join(", ")}${matchedTerms.length > 3 ? "..." : ""})');
    }

    return LocalFilterResult(
      blocked: blocked,
      needsReview: needsReview,
      matchedTerms: matchedTerms,
      categories: categories.toList(),
      severity: highestSeverity,
    );
  }

  /// Check text against a list of terms
  static List<String> _checkTerms(
    String lowerText,
    String normalizedText,
    List<String> terms,
    String category,
    bool allowProfessionalContext,
  ) {
    final matched = <String>[];

    for (final term in terms) {
      final lowerTerm = term.toLowerCase();

      // Check in both original lowercase and normalized text
      if (lowerText.contains(lowerTerm) || normalizedText.contains(lowerTerm)) {
        // Check if this term is in the allowlist and context is professional
        if (allowProfessionalContext && _isInAllowlist(term)) {
          continue;
        }

        matched.add(term);
      }
    }

    return matched;
  }

  /// Check if a term is in the professional allowlist
  static bool _isInAllowlist(String term) {
    final lowerTerm = term.toLowerCase();
    return ModerationFilters.allowlist.any(
      (allowed) =>
          allowed.toLowerCase().contains(lowerTerm) ||
          lowerTerm.contains(allowed.toLowerCase()),
    );
  }

  /// Get user-friendly message for blocked content
  static String getBlockedMessage(LocalFilterResult result) {
    if (!result.blocked && !result.needsReview) {
      return '';
    }

    if (result.blocked) {
      // High severity - instant block
      if (result.categories.contains('hate_speech')) {
        return 'Your content contains hate speech or discriminatory language that violates our community guidelines.';
      }
      if (result.categories.contains('threats')) {
        return 'Your content contains threats or violent language that violates our community guidelines.';
      }
      if (result.categories.contains('sexual_explicit')) {
        return 'Your content contains explicit sexual content that violates our community guidelines.';
      }
      if (result.categories.contains('illegal')) {
        return 'Your content references illegal activities that violates our community guidelines.';
      }
      if (result.categories.contains('self_harm')) {
        return 'Your content references self-harm. If you\'re struggling, please reach out to a crisis helpline.';
      }

      return 'Your content violates our community guidelines and cannot be posted.';
    }

    if (result.needsReview) {
      // Medium severity - flag for review
      return 'Your content has been flagged for review by our moderation team. It will be visible after approval.';
    }

    return '';
  }

  /// Check if content should skip AI moderation (already blocked locally)
  static bool shouldSkipAI(LocalFilterResult result) {
    // If blocked by local filter, no need to waste API calls
    return result.blocked;
  }

  /// Get statistics for monitoring
  static Map<String, dynamic> getStats(LocalFilterResult result) {
    return {
      'blocked': result.blocked,
      'needs_review': result.needsReview,
      'severity': result.severity,
      'categories': result.categories,
      'matched_count': result.matchedTerms.length,
      'passed': result.passed,
    };
  }
}

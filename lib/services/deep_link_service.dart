import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

/// Service for handling deep links and app-to-app navigation
class DeepLinkService {
  static const String _primaryHost = 'foundervers.com';
  static const String _legacyHost = 'startupnest-a3jdnswbja-uc.a.run.app';
  static const String _downloadUrl = 'https://foundervers.com/download';

  static late AppLinks _appLinks;
  static BuildContext? _context;

  /// Public fallback URL in case the app is not installed.
  static String get fallbackDownloadUrl => _downloadUrl;

  /// Initialize deep link service
  static Future<void> initialize(BuildContext context) async {
    _context = context;
    _appLinks = AppLinks();

    // Listen for incoming links when app is already running
    _appLinks.uriLinkStream.listen(
      (Uri uri) => handleIncomingLink(uri),
      onError: (err) => debugPrint('Deep link error: $err'),
    );

    // Check for link that opened the app (cold start)
    await _handleInitialLink();
  }

  /// Handle initial link (app opened from link)
  static Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await handleIncomingLink(initialLink);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  /// Process incoming deep link and navigate accordingly
  static Future<void> handleIncomingLink(Uri link) async {
    if (_context == null) return;

    if (!_isSupportedLink(link)) {
      debugPrint('Ignored unsupported link: ${link.toString()}');
      return;
    }

    debugPrint('🔗 Handling incoming link: ${link.toString()}');

    try {
      final normalizedSegments = _normalizeSegments(link);

      if (normalizedSegments.isEmpty) {
        // Base URL - go to home
        _navigateToHome();
        return;
      }

      switch (normalizedSegments[0]) {
        case 'posts':
          await _handlePostLink(normalizedSegments);
          break;
        case 'profile':
          await _handleProfileLink(normalizedSegments);
          break;
        case 'feed':
          _navigateToFeed();
          break;
        default:
          debugPrint('Unknown deep link path: ${normalizedSegments[0]}');
          _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      _navigateToHome();
    }
  }

  /// Handle post-specific deep links
  static Future<void> _handlePostLink(List<String> pathSegments) async {
    if (pathSegments.length < 2) {
      _navigateToFeed();
      return;
    }

    final postIdString = pathSegments[1];
    final postId = int.tryParse(postIdString);

    if (postId == null) {
      debugPrint('Invalid post ID: $postIdString');
      _navigateToFeed();
      return;
    }

    debugPrint('📱 Navigating to post $postId');

    // Navigate to specific post
    Navigator.of(_context!).pushNamed(
      '/post_detail',
      arguments: {'postId': postId},
    );
  }

  /// Handle profile-specific deep links
  static Future<void> _handleProfileLink(List<String> pathSegments) async {
    if (pathSegments.length < 2) {
      _navigateToProfile();
      return;
    }

    final userId = pathSegments[1];
    debugPrint('👤 Navigating to profile $userId');

    // Navigate to specific user profile
    Navigator.of(_context!).pushNamed(
      '/profile',
      arguments: {'userId': userId},
    );
  }

  /// Navigation helpers
  static void _navigateToHome() {
    Navigator.of(_context!).pushNamedAndRemoveUntil('/', (route) => false);
  }

  static void _navigateToFeed() {
    Navigator.of(_context!).pushNamed('/feed');
  }

  static void _navigateToProfile() {
    Navigator.of(_context!).pushNamed('/profile');
  }

  /// Generate shareable deep link for content
  static String generatePostLink(int postId, {String? userId}) {
    final queryParams = <String, String>{};

    if (userId != null) {
      queryParams['ref'] = userId;
    }

    // Add UTM parameters for tracking
    queryParams.addAll({
      'utm_source': 'app',
      'utm_medium': 'share',
      'utm_campaign': 'viral_growth',
    });

    final uri = Uri.https(_primaryHost, '/posts/$postId', queryParams);

    return uri.toString();
  }

  /// Generate profile deep link
  static String generateProfileLink(String userId, {String? referrerId}) {
    final queryParams = <String, String>{
      'utm_source': 'app',
      'utm_medium': 'profile_share',
    };

    if (referrerId != null) {
      queryParams['ref'] = referrerId;
    }

    final uri = Uri.https(_primaryHost, '/profile/$userId', queryParams);

    return uri.toString();
  }

  static bool _isSupportedLink(Uri link) {
    if (link.scheme == 'foundervers') {
      return true;
    }

    if (link.scheme == 'https') {
      return link.host == _primaryHost || link.host == _legacyHost;
    }

    return false;
  }

  static List<String> _normalizeSegments(Uri link) {
    final segments = <String>[];

    if (link.scheme == 'foundervers' && link.host.isNotEmpty) {
      segments.add(link.host);
    }

    segments.addAll(link.pathSegments);
    return segments;
  }

  /// Test deep link functionality (development only)
  static Future<void> testDeepLink(String testUrl) async {
    if (!const bool.fromEnvironment('dart.vm.product')) {
      debugPrint('🧪 Testing deep link: $testUrl');
      await handleIncomingLink(Uri.parse(testUrl));
    }
  }
}

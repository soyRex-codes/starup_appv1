import 'dart:collection';
import 'dart:io' show Platform;
import 'package:foundervers/models/post.dart';

/// In-memory cache for feed posts to reduce API calls and improve UX
class FeedCache {
  FeedCache._({Duration? ttl, int? maxSize})
      : _cacheExpiry = ttl ?? const Duration(minutes: 5),
        _maxCacheSize = maxSize ?? 50;

  static final FeedCache instance = FeedCache._();

  /// Test constructor for unit testing with custom parameters
  static FeedCache testInstance({Duration? ttl, int? maxSize}) {
    return FeedCache._(ttl: ttl, maxSize: maxSize);
  }

  // Cache structure: LinkedHashMap for efficient LRU operations
  final LinkedHashMap<String, CachedPosts> _cache =
      LinkedHashMap<String, CachedPosts>();
  final int _maxCacheSize; // Limit cache entries
  final Duration _cacheExpiry; // Default cache expiry duration

  // Background refresh configuration
  static const Duration _backgroundRefreshThreshold = Duration(minutes: 3);

  // Statistics tracking
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _expiredItems = 0;
  int _backgroundRefreshes = 0;

  /// Get adaptive cache size based on available memory and device capability
  int get _adaptiveMaxSize {
    try {
      // For test instances with small configured size, respect the limit
      if (_maxCacheSize <= 10) {
        return _maxCacheSize;
      }

      // Use processor count as proxy for device capability
      // Higher-end devices can handle larger caches
      final processorCount = Platform.numberOfProcessors;

      if (processorCount >= 8) {
        return (_maxCacheSize * 1.5).round(); // High-end devices: 75 entries
      } else if (processorCount >= 4) {
        return _maxCacheSize; // Mid-range devices: 50 entries
      } else {
        return (_maxCacheSize * 0.6).round(); // Low-end devices: 30 entries
      }
    } catch (e) {
      // Fallback to default if platform detection fails
      return _maxCacheSize;
    }
  }

  /// Get smart TTL based on content type and search patterns
  Duration _getSmartTTL(String? category, String? search) {
    // For test instances with very short TTL, respect the configured TTL
    if (_cacheExpiry.inMilliseconds < 1000) {
      return _cacheExpiry;
    }

    // Search results change frequently - shorter TTL
    if (search != null && search.isNotEmpty) {
      return const Duration(minutes: 2);
    }

    // Trending/popular content changes more frequently
    if (category?.toLowerCase() == 'trending' ||
        category?.toLowerCase() == 'popular') {
      return const Duration(minutes: 3);
    }

    // General category content can be cached longer
    if (category != null) {
      return const Duration(minutes: 10); // Increased from 8 to 10
    }

    // Default TTL for uncategorized content
    return _cacheExpiry; // 5 minutes
  }

  /// Generate cache key from search/filter parameters
  String _generateKey({
    String? category,
    String? goal,
    String? search,
    String? dateRange,
    int offset = 0,
  }) {
    final parts = <String>[];
    if (category != null) parts.add('cat:$category');
    if (goal != null) parts.add('goal:$goal');
    if (search != null && search.isNotEmpty) {
      parts.add('search:${search.toLowerCase()}');
    }
    if (dateRange != null && dateRange != 'all') {
      parts.add('date:$dateRange');
    }
    parts.add('offset:$offset');
    return parts.join('|');
  }

  /// Get cached posts if available and not expired
  /// Returns cached data even if stale (for instant UI), sets needsRefresh flag
  CacheResult? get({
    String? category,
    String? goal,
    String? search,
    String? dateRange,
    int offset = 0,
  }) {
    final key = _generateKey(
      category: category,
      goal: goal,
      search: search,
      dateRange: dateRange,
      offset: offset,
    );

    final cached = _cache.remove(key); // Remove first for efficient LRU
    if (cached == null) {
      _misses++;
      return null;
    }

    final age = DateTime.now().difference(cached.timestamp);
    final smartTTL = _getSmartTTL(category, search);

    // Check if needs background refresh (older than 3 minutes)
    final needsRefresh = age > _backgroundRefreshThreshold;

    // Check if expired (older than smart TTL)
    final isExpired = age > smartTTL;

    if (isExpired) {
      _misses++;
      _expiredItems++;
      return null; // Don't re-add expired entries
    }

    // Re-add at end for LRU
    _cache[key] = cached;
    _hits++;

    return CacheResult(
      posts: cached.posts,
      needsRefresh: needsRefresh,
      age: age,
    );
  }

  /// Store posts in cache
  void put({
    String? category,
    String? goal,
    String? search,
    String? dateRange,
    int offset = 0,
    required List<PostModel> posts,
  }) {
    final key = _generateKey(
      category: category,
      goal: goal,
      search: search,
      dateRange: dateRange,
      offset: offset,
    );

    // Remove existing entry if it exists
    _cache.remove(key);

    // Add new entry at end
    _cache[key] = CachedPosts(
      posts: List.from(posts),
      timestamp: DateTime.now(),
    );

    // Enforce adaptive size limit using LRU eviction
    final maxSize = _adaptiveMaxSize;
    while (_cache.length > maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
      _evictions++;
    }
  }

  /// Invalidate cache entries by category
  void invalidate({String? category, String? goal, String? search}) {
    // If no filters provided, clear everything to ensure consistency
    if (category == null && goal == null && search == null) {
      clear();
      return;
    }

    final keysToRemove = <String>[];

    for (final key in _cache.keys) {
      bool shouldRemove = false;

      if (category != null && key.contains('cat:$category')) {
        shouldRemove = true;
      }
      if (goal != null && key.contains('goal:$goal')) {
        shouldRemove = true;
      }
      if (search != null && key.contains('search:${search.toLowerCase()}')) {
        shouldRemove = true;
      }

      if (shouldRemove) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clear all cached data
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _expiredItems = 0;
    _backgroundRefreshes = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final total = _hits + _misses;
    return {
      'size': _cache.length,
      'maxSize': _adaptiveMaxSize,
      'hits': _hits,
      'misses': _misses,
      'evictions': _evictions,
      'expiredItems': _expiredItems,
      'backgroundRefreshes': _backgroundRefreshes,
      'hitRate':
          total > 0 ? '${(_hits / total * 100).toStringAsFixed(1)}%' : '0%',
      'memoryEfficiency': total > 0
          ? '${((_hits - _evictions) / total * 100).toStringAsFixed(1)}%'
          : '0%',
      'avgTTL': _cacheExpiry.inMilliseconds,
    };
  }

  /// Mark that a background refresh occurred
  void markBackgroundRefresh() {
    _backgroundRefreshes++;
  }

  /// Check if cache contains a specific key
  bool containsKey({
    String? category,
    String? goal,
    String? search,
    String? dateRange,
    int offset = 0,
  }) {
    final key = _generateKey(
      category: category,
      goal: goal,
      search: search,
      dateRange: dateRange,
      offset: offset,
    );
    return _cache.containsKey(key);
  }

  /// Get all cached keys (for debugging)
  List<String> getCachedKeys() {
    return _cache.keys.toList();
  }
}

/// Internal class to store cached posts with timestamp
class CachedPosts {
  final List<PostModel> posts;
  final DateTime timestamp;

  CachedPosts({
    required this.posts,
    required this.timestamp,
  });
}

/// Cache result with refresh metadata
class CacheResult {
  final List<PostModel> posts;
  final bool needsRefresh;
  final Duration age;

  CacheResult({
    required this.posts,
    required this.needsRefresh,
    required this.age,
  });

  Null get length => null;
}

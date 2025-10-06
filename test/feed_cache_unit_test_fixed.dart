import 'package:flutter_test/flutter_test.dart';
import 'package:foundervers/core/cache/feed_cache.dart';
import 'package:foundervers/models/post.dart';

void main() {
  group('FeedCache Unit Tests', () {
    late FeedCache cache;

    setUp(() {
      cache = FeedCache.instance;
      cache.clear(); // Start with clean cache
    });

    test('should store and retrieve posts correctly', () {
      // Create mock posts
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Test Post 1',
          description: 'Description 1',
          category: 'Tech',
          name: 'Author 1',
          createdAt: DateTime.now(),
        ),
        PostModel(
          id: 2,
          userId: 'user2',
          title: 'Test Post 2',
          description: 'Description 2',
          category: 'Business',
          name: 'Author 2',
          createdAt: DateTime.now(),
        ),
      ];

      // Store in cache
      cache.put(
        category: 'Tech',
        goal: null,
        search: null,
        offset: 0,
        posts: mockPosts,
      );

      // Retrieve from cache
      final cached = cache.get(
        category: 'Tech',
        goal: null,
        search: null,
        offset: 0,
      );

      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached[0].title, equals('Test Post 1'));
      expect(cached[1].title, equals('Test Post 2'));
    });

    test('should generate different keys for different parameters', () {
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Test Post',
          description: 'Description',
          category: 'Tech',
          name: 'Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Store with different parameters
      cache.put(
          category: 'Tech',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: 'Business',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: null,
          goal: 'Startup',
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: null,
          goal: null,
          search: 'flutter',
          offset: 0,
          posts: mockPosts);

      // All should be stored separately
      expect(cache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: 'Business', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: null, goal: 'Startup', search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: null, goal: null, search: 'flutter', offset: 0),
          isNotNull);

      // Different parameters should return null
      expect(
          cache.get(
              category: 'NonExistent', goal: null, search: null, offset: 0),
          isNull);
    });

    test('should track cache statistics correctly', () {
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Test Post',
          description: 'Description',
          category: 'Tech',
          name: 'Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Initial stats should be zero
      final initialStats = cache.getStats();
      expect(initialStats['hits'], equals(0));
      expect(initialStats['misses'], equals(0));

      // Store a post
      cache.put(
          category: 'Tech',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);

      // Cache miss (not found)
      final miss = cache.get(
          category: 'NonExistent', goal: null, search: null, offset: 0);
      expect(miss, isNull);

      // Cache hit (found)
      final hit =
          cache.get(category: 'Tech', goal: null, search: null, offset: 0);
      expect(hit, isNotNull);

      final finalStats = cache.getStats();
      expect(finalStats['hits'], equals(1));
      expect(finalStats['misses'], equals(1));
    });

    test('should handle cache expiration (TTL)', () async {
      // Create cache with very short TTL for testing
      final testCache = FeedCache.testInstance(ttl: Duration(milliseconds: 50));

      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Test Post',
          description: 'Description',
          category: 'Tech',
          name: 'Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Store in cache
      testCache.put(
          category: 'Tech',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);

      // Should be available immediately
      expect(
          testCache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNotNull);

      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 100));

      // Should be expired and return null
      expect(
          testCache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNull);
    });

    test('should handle cache size limits', () {
      // Create cache with small size limit for testing
      final testCache = FeedCache.testInstance(maxSize: 2);

      final mockPost = PostModel(
        id: 1,
        userId: 'user1',
        title: 'Test Post',
        description: 'Description',
        category: 'Tech',
        name: 'Author',
        createdAt: DateTime.now(),
      );

      // Fill cache to limit
      testCache.put(
          category: 'Tech',
          goal: null,
          search: null,
          offset: 0,
          posts: [mockPost]);
      testCache.put(
          category: 'Business',
          goal: null,
          search: null,
          offset: 0,
          posts: [mockPost]);

      // Both should be available
      expect(
          testCache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          testCache.get(
              category: 'Business', goal: null, search: null, offset: 0),
          isNotNull);

      // Add third entry - should evict oldest
      testCache.put(
          category: 'Finance',
          goal: null,
          search: null,
          offset: 0,
          posts: [mockPost]);

      // First entry should be evicted, last two should remain
      expect(
          testCache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNull);
      expect(
          testCache.get(
              category: 'Business', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          testCache.get(
              category: 'Finance', goal: null, search: null, offset: 0),
          isNotNull);
    });

    test('should invalidate cache entries correctly', () {
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Test Post',
          description: 'Description',
          category: 'Tech',
          name: 'Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Store multiple entries
      cache.put(
          category: 'Tech',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: 'Tech',
          goal: 'Startup',
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: 'Business',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);

      // All should be available
      expect(cache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: 'Tech', goal: 'Startup', search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: 'Business', goal: null, search: null, offset: 0),
          isNotNull);

      // Invalidate specific category
      cache.invalidate(category: 'Tech');

      // Tech entries should be invalidated, Business should remain
      expect(cache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNull);
      expect(
          cache.get(category: 'Tech', goal: 'Startup', search: null, offset: 0),
          isNull);
      expect(
          cache.get(category: 'Business', goal: null, search: null, offset: 0),
          isNotNull);
    });

    test('should clear all cache entries', () {
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Test Post',
          description: 'Description',
          category: 'Tech',
          name: 'Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Store multiple entries
      cache.put(
          category: 'Tech',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: 'Business',
          goal: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          category: null,
          goal: 'Startup',
          search: null,
          offset: 0,
          posts: mockPosts);

      // All should be available
      expect(cache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: 'Business', goal: null, search: null, offset: 0),
          isNotNull);
      expect(
          cache.get(category: null, goal: 'Startup', search: null, offset: 0),
          isNotNull);

      // Clear all
      cache.clear();

      // All should be null after clear
      expect(cache.get(category: 'Tech', goal: null, search: null, offset: 0),
          isNull);
      expect(
          cache.get(category: 'Business', goal: null, search: null, offset: 0),
          isNull);
      expect(
          cache.get(category: null, goal: 'Startup', search: null, offset: 0),
          isNull);

      // Stats should be reset
      final stats = cache.getStats();
      expect(stats['size'], equals(0));
    });
  });
}

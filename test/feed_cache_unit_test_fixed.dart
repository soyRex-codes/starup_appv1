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
        categories: ['Tech'],
        goals: null,
        search: null,
        offset: 0,
        posts: mockPosts,
      );

      // Retrieve from cache
      final cached = cache.get(
        categories: ['Tech'],
        goals: null,
        search: null,
        offset: 0,
      )?.posts;

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
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: ['Business'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: null,
          goals: ['Startup'],
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: null,
          goals: null,
          search: 'flutter',
          offset: 0,
          posts: mockPosts);

      // All should be stored separately
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache
              .get(
                  categories: null, goals: ['Startup'], search: null, offset: 0)
              ?.posts,
          isNotNull);
      expect(
          cache
              .get(categories: null, goals: null, search: 'flutter', offset: 0)
              ?.posts,
          isNotNull);

      // Different parameters should return null
      expect(
          cache.get(
              categories: ['NonExistent'],
              goals: null,
              search: null,
              offset: 0)?.posts,
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
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);

      // Cache miss (not found)
      final miss = cache.get(
          categories: ['NonExistent'],
          goals: null,
          search: null,
          offset: 0)?.posts;
      expect(miss, isNull);

      // Cache hit (found)
      final hit = cache.get(
          categories: ['Tech'], goals: null, search: null, offset: 0)?.posts;
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
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);

      // Should be available immediately
      expect(
          testCache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);

      // Wait for expiration
      await Future.delayed(Duration(milliseconds: 100));

      // Should be expired and return null
      expect(
          testCache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
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
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 0,
          posts: [mockPost]);
      testCache.put(
          categories: ['Business'],
          goals: null,
          search: null,
          offset: 0,
          posts: [mockPost]);

      // Both should be available
      expect(
          testCache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          testCache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);

      // Add third entry - should evict oldest
      testCache.put(
          categories: ['Finance'],
          goals: null,
          search: null,
          offset: 0,
          posts: [mockPost]);

      // First entry should be evicted, last two should remain
      expect(
          testCache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNull);
      expect(
          testCache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          testCache.get(
              categories: ['Finance'],
              goals: null,
              search: null,
              offset: 0)?.posts,
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
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: ['Tech'],
          goals: ['Startup'],
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: ['Business'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);

      // All should be available
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache.get(
              categories: ['Tech'],
              goals: ['Startup'],
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);

      // Invalidate specific category
      cache.invalidate(categories: ['Tech']);

      // Tech entries should be invalidated, Business should remain
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNull);
      expect(
          cache.get(
              categories: ['Tech'],
              goals: ['Startup'],
              search: null,
              offset: 0)?.posts,
          isNull);
      expect(
          cache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
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
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: ['Business'],
          goals: null,
          search: null,
          offset: 0,
          posts: mockPosts);
      cache.put(
          categories: null,
          goals: ['Startup'],
          search: null,
          offset: 0,
          posts: mockPosts);

      // All should be available
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache
              .get(
                  categories: null, goals: ['Startup'], search: null, offset: 0)
              ?.posts,
          isNotNull);

      // Clear all
      cache.clear();

      // All should be null after clear
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNull);
      expect(
          cache.get(
              categories: ['Business'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNull);
      expect(
          cache
              .get(
                  categories: null, goals: ['Startup'], search: null, offset: 0)
              ?.posts,
          isNull);

      // Stats should be reset
      final stats = cache.getStats();
      expect(stats['size'], equals(0));
    });
  });
}

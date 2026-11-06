import 'package:flutter_test/flutter_test.dart';
import 'package:foundervers/core/cache/feed_cache.dart';
import 'package:foundervers/models/post.dart';

void main() {
  group('FeedCache Workflow Tests', () {
    late FeedCache cache;

    setUp(() {
      cache = FeedCache.instance;
      cache.clear(); // Start with clean cache for each test
    });

    test('should cache and retrieve feed response posts', () {
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Integration Test Post',
          description: 'Testing cache integration',
          category: 'Tech',
          name: 'Test Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Manually cache some data to simulate API response
      cache.put(
        categories: ['Tech'],
        goals: null,
        search: null,
        offset: 0,
        posts: mockPosts,
      );

      // Verify cache integration
      final cached = cache.get(
        categories: ['Tech'],
        goals: null,
        search: null,
        offset: 0,
      )?.posts;

      expect(cached, isNotNull);
      expect(cached!.length, equals(1));
      expect(cached[0].title, equals('Integration Test Post'));

      print('✅ Feed service cache integration test passed');
    });

    test('should handle concurrent cache operations', () async {
      final mockPosts1 = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Concurrent Test 1',
          description: 'Testing concurrent access',
          category: 'Tech',
          name: 'Author 1',
          createdAt: DateTime.now(),
        ),
      ];

      final mockPosts2 = [
        PostModel(
          id: 2,
          userId: 'user2',
          title: 'Concurrent Test 2',
          description: 'Testing concurrent access',
          category: 'Business',
          name: 'Author 2',
          createdAt: DateTime.now(),
        ),
      ];

      // Simulate concurrent cache operations
      final futures = [
        Future(() => cache.put(
            categories: ['Tech'],
            goals: null,
            search: null,
            offset: 0,
            posts: mockPosts1)),
        Future(() => cache.put(
            categories: ['Business'],
            goals: null,
            search: null,
            offset: 0,
            posts: mockPosts2)),
        Future(() => cache.get(
            categories: ['Tech'], goals: null, search: null, offset: 0)?.posts),
        Future(() => cache.get(
            categories: ['Business'],
            goals: null,
            search: null,
            offset: 0)?.posts),
      ];

      await Future.wait(futures);

      // Verify both entries are cached correctly
      final techPosts = cache.get(
          categories: ['Tech'], goals: null, search: null, offset: 0)?.posts;
      final businessPosts = cache.get(
          categories: ['Business'],
          goals: null,
          search: null,
          offset: 0)?.posts;

      expect(techPosts, isNotNull);
      expect(businessPosts, isNotNull);
      expect(techPosts![0].title, equals('Concurrent Test 1'));
      expect(businessPosts![0].title, equals('Concurrent Test 2'));

      print('✅ Concurrent cache operations test passed');
    });

    test('should handle cache warming and preloading', () {
      final categories = ['Tech', 'Business', 'Finance', 'Healthcare'];
      final mockPosts = List.generate(
          10,
          (index) => PostModel(
                id: index,
                userId: 'user$index',
                title: 'Warmup Post $index',
                description: 'Cache warming test',
                category: categories[index % categories.length],
                name: 'Author $index',
                createdAt: DateTime.now(),
              ));

      // Warm cache with different categories
      for (final category in categories) {
        final categoryPosts =
            mockPosts.where((p) => p.category == category).toList();
        cache.put(
          categories: [category],
          goals: null,
          search: null,
          offset: 0,
          posts: categoryPosts,
        );
      }

      // Verify all categories are cached
      for (final category in categories) {
        final cached = cache.get(
            categories: [category],
            goals: null,
            search: null,
            offset: 0)?.posts;
        expect(cached, isNotNull);
        expect(cached!.isNotEmpty, isTrue);
        print('✅ Category $category cached with ${cached.length} posts');
      }

      // Check cache statistics
      final stats = cache.getStats();
      expect(stats['size'], equals(categories.length));
      expect(stats['hits'], greaterThan(0));

      print('✅ Cache warming test passed');
    });

    test('should handle cache invalidation scenarios', () {
      final mockPosts = [
        PostModel(
          id: 1,
          userId: 'user1',
          title: 'Invalidation Test',
          description: 'Testing cache invalidation',
          category: 'Tech',
          name: 'Test Author',
          createdAt: DateTime.now(),
        ),
      ];

      // Cache data for multiple scenarios
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

      // Verify all are cached
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

      // Verify selective invalidation
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

      print('✅ Cache invalidation integration test passed');
    });

    test('should handle memory pressure and cleanup', () {
      // Create cache with small limits for testing
      final testCache =
          FeedCache.testInstance(maxSize: 3, ttl: Duration(seconds: 1));

      final mockPost = PostModel(
        id: 1,
        userId: 'user1',
        title: 'Memory Test',
        description: 'Testing memory management',
        category: 'Tech',
        name: 'Test Author',
        createdAt: DateTime.now(),
      );

      // Fill cache beyond capacity
      final categories = [
        'Tech',
        'Business',
        'Finance',
        'Healthcare',
        'Education'
      ];
      for (int i = 0; i < categories.length; i++) {
        testCache.put(
          categories: [categories[i]],
          goals: null,
          search: null,
          offset: 0,
          posts: [mockPost],
        );
      }

      // Verify LRU eviction - oldest entries should be removed
      final stats = testCache.getStats();
      expect(stats['size'], lessThanOrEqualTo(3));

      // Check that most recent entries are still available
      expect(
          testCache.get(
              categories: ['Education'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          testCache.get(
              categories: ['Healthcare'],
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

      print('✅ Memory pressure handling test passed');
    });

    test('should handle real-world usage patterns', () async {
      final mockPosts = List.generate(
          20,
          (index) => PostModel(
                id: index,
                userId: 'user$index',
                title: 'Real World Post $index',
                description: 'Simulating real usage',
                category: ['Tech', 'Business', 'Finance'][index % 3],
                name: 'Author $index',
                createdAt: DateTime.now().subtract(Duration(hours: index)),
              ));

      // Simulate user browsing different categories
      final categories = ['Tech', 'Business', 'Finance'];

      for (final category in categories) {
        final categoryPosts =
            mockPosts.where((p) => p.category == category).toList();
        cache.put(
            categories: [category],
            goals: null,
            search: null,
            offset: 0,
            posts: categoryPosts);
      }

      // Simulate user searches
      cache.put(
          categories: null,
          goals: null,
          search: 'flutter',
          offset: 0,
          posts: mockPosts.take(5).toList());
      cache.put(
          categories: null,
          goals: null,
          search: 'startup',
          offset: 0,
          posts: mockPosts.skip(5).take(5).toList());

      // Simulate pagination
      cache.put(
          categories: ['Tech'],
          goals: null,
          search: null,
          offset: 20,
          posts: mockPosts.take(10).toList());

      // Verify all scenarios work
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 0)?.posts,
          isNotNull);
      expect(
          cache
              .get(categories: null, goals: null, search: 'flutter', offset: 0)
              ?.posts,
          isNotNull);
      expect(
          cache.get(
              categories: ['Tech'],
              goals: null,
              search: null,
              offset: 20)?.posts,
          isNotNull);

      final stats = cache.getStats();
      print('Final cache stats: $stats');
      print('✅ Real-world usage patterns test passed');
    });
  });
}

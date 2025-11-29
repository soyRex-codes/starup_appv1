import 'dart:async';
import 'package:flutter/foundation.dart';

/// Data class to hold post counts
@immutable
class PostCounts {
  final int views;
  final int comments;

  const PostCounts({
    this.views = 0,
    this.comments = 0,
  });

  PostCounts copyWith({
    int? views,
    int? comments,
  }) {
    return PostCounts(
      views: views ?? this.views,
      comments: comments ?? this.comments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostCounts &&
          runtimeType == other.runtimeType &&
          views == other.views &&
          comments == other.comments;

  @override
  int get hashCode => views.hashCode ^ comments.hashCode;

  @override
  String toString() => 'PostCounts(views: $views, comments: $comments)';
}

/// Singleton service to manage post view and comment counts globally
/// This provides persistence across widget rebuilds and synchronization
/// between different instances of the same post (feed vs detail view)
class PostCountsManager {
  // Singleton instance
  static final PostCountsManager _instance = PostCountsManager._internal();
  factory PostCountsManager() => _instance;
  static PostCountsManager get instance => _instance;
  PostCountsManager._internal();

  // In-memory cache: Map<postId, PostCounts>
  final Map<int, PostCounts> _cache = {};

  // Stream controller for broadcasting count updates
  final _controller = StreamController<Map<int, PostCounts>>.broadcast();

  // Stream for global updates (if needed)
  Stream<Map<int, PostCounts>> get updates => _controller.stream;

  /// Get current counts for a post (instant, synchronous)
  PostCounts getCounts(int postId) {
    return _cache[postId] ?? const PostCounts();
  }

  /// Get view count for a post
  int getViewCount(int postId) {
    return _cache[postId]?.views ?? 0;
  }

  /// Get comment count for a post
  int getCommentCount(int postId) {
    return _cache[postId]?.comments ?? 0;
  }

  /// Update view count for a post
  void updateViewCount(int postId, int views) {
    final current = _cache[postId] ?? const PostCounts();
    _cache[postId] = current.copyWith(views: views);
    _controller.add(_cache);
    
    if (kDebugMode) {
      debugPrint('📊 PostCountsManager: Updated views for post $postId: $views');
    }
  }

  /// Update comment count for a post
  void updateCommentCount(int postId, int comments) {
    final current = _cache[postId] ?? const PostCounts();
    _cache[postId] = current.copyWith(comments: comments);
    _controller.add(_cache);
    
    if (kDebugMode) {
      debugPrint('📊 PostCountsManager: Updated comments for post $postId: $comments');
    }
  }

  /// Increment comment count (convenience method)
  void incrementCommentCount(int postId) {
    final current = _cache[postId] ?? const PostCounts();
    _cache[postId] = current.copyWith(comments: current.comments + 1);
    _controller.add(_cache);
    
    if (kDebugMode) {
      debugPrint('📊 PostCountsManager: Incremented comments for post $postId: ${current.comments + 1}');
    }
  }

  /// Update both counts at once
  void updateCounts(int postId, {int? views, int? comments}) {
    final current = _cache[postId] ?? const PostCounts();
    _cache[postId] = current.copyWith(
      views: views,
      comments: comments,
    );
    _controller.add(_cache);
    
    if (kDebugMode) {
      debugPrint('📊 PostCountsManager: Updated counts for post $postId: ${_cache[postId]}');
    }
  }

  /// Watch counts for a specific post (returns a stream)
  /// Use this in widgets to reactively update UI
  Stream<PostCounts> watchCounts(int postId) {
    return _controller.stream.map((allCounts) {
      return allCounts[postId] ?? const PostCounts();
    }).distinct(); // Only emit when counts actually change
  }

  /// Batch sync from database (called by FeedService after fetch)
  void syncFromDatabase(Map<int, PostCounts> counts) {
    var updateCount = 0;
    counts.forEach((postId, newCounts) {
      final current = _cache[postId];
      // Only update if counts are newer (higher)
      if (current == null || 
          newCounts.views >= current.views || 
          newCounts.comments >= current.comments) {
        _cache[postId] = PostCounts(
          views: newCounts.views > (current?.views ?? 0) ? newCounts.views : (current?.views ?? 0),
          comments: newCounts.comments > (current?.comments ?? 0) ? newCounts.comments : (current?.comments ?? 0),
        );
        updateCount++;
      }
    });
    
    if (updateCount > 0) {
      _controller.add(_cache);
      if (kDebugMode) {
        debugPrint('📊 PostCountsManager: Synced $updateCount posts from database');
      }
    }
  }

  /// Clear all cached counts (useful on logout)
  void clear() {
    _cache.clear();
    _controller.add(_cache);
    if (kDebugMode) {
      debugPrint('📊 PostCountsManager: Cleared all cached counts');
    }
  }

  /// Remove old entries to prevent memory bloat
  /// Call this periodically or when memory is low
  void pruneOldEntries({int maxEntries = 500}) {
    if (_cache.length > maxEntries) {
      // Keep only the most recently accessed entries
      // For simplicity, just remove oldest half
      final entriesToRemove = _cache.length - maxEntries;
      final keysToRemove = _cache.keys.take(entriesToRemove).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      
      if (kDebugMode) {
        debugPrint('📊 PostCountsManager: Pruned $entriesToRemove old entries');
      }
    }
  }

  /// Dispose (cleanup)
  void dispose() {
    _controller.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewAnalyticsService {
  // Singleton instance
  static final ViewAnalyticsService _instance = ViewAnalyticsService._internal();
  factory ViewAnalyticsService() => _instance;
  ViewAnalyticsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _storageKey = 'pending_post_views';
  static const Duration _flushInterval = Duration(seconds: 30);
  
  // In-memory queue of post IDs to be synced
  final Set<String> _pendingViews = {};
  
  // Session debounce: Track posts viewed in this session to prevent spamming
  // Map<PostID, Timestamp>
  final Map<String, DateTime> _sessionViews = {};
  static const Duration _sessionCooldown = Duration(minutes: 10);

  Timer? _flushTimer;
  bool _isInitialized = false;

  /// Initialize service: load pending views from storage and start timer
  Future<void> init() async {
    if (_isInitialized) return;
    
    await _loadFromStorage();
    _startFlushTimer();
    _isInitialized = true;
  }

  /// Track a view for a post
  /// Returns true if the view was counted (passed debounce check)
  Future<bool> trackView(String postId) async {
    if (!_isInitialized) await init();

    // 1. Session Debounce Check
    final now = DateTime.now();
    if (_sessionViews.containsKey(postId)) {
      final lastViewed = _sessionViews[postId]!;
      if (now.difference(lastViewed) < _sessionCooldown) {
        return false; // Too soon to count again
      }
    }

    // 2. Add to session tracker
    _sessionViews[postId] = now;

    // 3. Add to pending queue
    _pendingViews.add(postId);

    // 4. Persist immediately to storage (Safety Net)
    await _saveToStorage();
    
    return true;
  }

  /// Get pending view count for a post (for Optimistic UI)
  int getPendingViewCount(String postId) {
    // If it's in the pending queue, we assume it's +1 view that hasn't synced yet
    // Note: This is a simple implementation. For more complex scenarios, 
    // we might need a Map<String, int> if we allowed multiple views per batch.
    return _pendingViews.contains(postId) ? 1 : 0;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? stored = prefs.getStringList(_storageKey);
      if (stored != null) {
        _pendingViews.addAll(stored);
      }
    } catch (e) {
      debugPrint('Error loading pending views: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _pendingViews.toList());
    } catch (e) {
      debugPrint('Error saving pending views: $e');
    }
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  /// Flush pending views to database
  Future<void> _flush() async {
    if (_pendingViews.isEmpty) return;

    // Create a batch copy to send
    final batch = List<String>.from(_pendingViews);
    
    try {
      // Call RPC function
      await _supabase.rpc('increment_post_views', params: {
        'post_ids': batch,
      });

      // On success, remove these IDs from pending
      _pendingViews.removeAll(batch);
      await _saveToStorage();
      
      debugPrint('Flushed ${batch.length} views to DB');
    } catch (e) {
      debugPrint('Error flushing views to DB: $e');
      // On failure, they stay in _pendingViews and will be retried next time
    }
  }

  /// Force flush (e.g., on app pause)
  Future<void> forceFlush() async {
    await _flush();
  }
  
  void dispose() {
    _flushTimer?.cancel();
  }
}

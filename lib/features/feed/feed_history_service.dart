import 'package:shared_preferences/shared_preferences.dart';

/// Service to track which posts a user has seen locally.
/// Used by FeedService to prioritize unseen content.
class FeedHistoryService {
  static final FeedHistoryService _instance = FeedHistoryService._internal();
  static FeedHistoryService get instance => _instance;
  FeedHistoryService._internal();

  static const _keySeenPosts = 'seen_post_ids';
  static const _maxHistorySize = 100;

  SharedPreferences? _prefs;
  Set<int> _seenIds = {};

  /// Initialize the service (call once at app startup)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final stored = _prefs?.getStringList(_keySeenPosts) ?? [];
    _seenIds = stored.map((s) => int.tryParse(s)).whereType<int>().toSet();
  }

  /// Check if a post has been seen
  bool isSeen(int id) => _seenIds.contains(id);

  /// Mark posts as seen (debounced batch call recommended)
  Future<void> markAsSeen(List<int> ids) async {
    if (ids.isEmpty) return;
    
    _seenIds.addAll(ids);
    
    // Enforce FIFO limit: keep most recent entries
    if (_seenIds.length > _maxHistorySize) {
      final list = _seenIds.toList();
      _seenIds = list.sublist(list.length - _maxHistorySize).toSet();
    }
    
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final list = _seenIds.map((id) => id.toString()).toList();
    await _prefs?.setStringList(_keySeenPosts, list);
  }

  /// Clear history (for logout)
  Future<void> clear() async {
    _seenIds.clear();
    await _prefs?.remove(_keySeenPosts);
  }

  /// Get all seen IDs (for debugging)
  Set<int> get seenIds => Set.unmodifiable(_seenIds);
}

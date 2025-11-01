/// In-memory cache for global chat messages to reduce database load
/// Particularly useful for high-traffic public chat
class GlobalChatCache {
  GlobalChatCache._();
  static final GlobalChatCache instance = GlobalChatCache._();

  // Cache configuration
  final Duration _ttl = const Duration(minutes: 3); // Shorter TTL for real-time chat
  final int _maxMessages = 200; // Cache last 200 messages

  // Cache storage
  List<Map<String, dynamic>>? _cachedMessages;
  DateTime? _cacheTimestamp;

  // Statistics
  int _hits = 0;
  int _misses = 0;

  /// Get cached messages if available and not expired
  List<Map<String, dynamic>>? get() {
    if (_cachedMessages == null || _cacheTimestamp == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (DateTime.now().difference(_cacheTimestamp!) > _ttl) {
      _misses++;
      _cachedMessages = null; // Clear expired cache
      _cacheTimestamp = null;
      return null;
    }

    _hits++;
    return List.from(_cachedMessages!); // Return copy
  }

  /// Cache messages
  void put(List<Map<String, dynamic>> messages) {
    // Limit to max messages (keep most recent)
    final messagesToCache = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;

    _cachedMessages = List.from(messagesToCache);
    _cacheTimestamp = DateTime.now();
  }

  /// Append a new message to cache (optimistic update for sent messages)
  void appendMessage(Map<String, dynamic> message) {
    if (_cachedMessages == null) return;

    _cachedMessages!.add(message);

    // Limit to max messages
    if (_cachedMessages!.length > _maxMessages) {
      _cachedMessages = _cachedMessages!.sublist(
        _cachedMessages!.length - _maxMessages,
      );
    }

    // Update timestamp when adding new message
    _cacheTimestamp = DateTime.now();
  }

  /// Update a message in cache (e.g., moderation status change)
  void updateMessage(String messageId, Map<String, dynamic> updatedMessage) {
    if (_cachedMessages == null) return;

    final index = _cachedMessages!.indexWhere((msg) => msg['id'] == messageId);
    if (index != -1) {
      _cachedMessages![index] = updatedMessage;
    }
  }

  /// Remove a message from cache (e.g., deleted or moderated)
  void removeMessage(String messageId) {
    if (_cachedMessages == null) return;

    _cachedMessages!.removeWhere((msg) => msg['id'] == messageId);
  }

  /// Check if cache is valid (not expired)
  bool isValid() {
    if (_cachedMessages == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) <= _ttl;
  }

  /// Clear cache (e.g., on logout or manual refresh)
  void clear() {
    _cachedMessages = null;
    _cacheTimestamp = null;
    _hits = 0;
    _misses = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final total = _hits + _misses;
    return {
      'is_cached': _cachedMessages != null,
      'cached_messages': _cachedMessages?.length ?? 0,
      'max_messages': _maxMessages,
      'hits': _hits,
      'misses': _misses,
      'hit_rate': total > 0 ? '${(_hits / total * 100).toStringAsFixed(1)}%' : '0%',
      'ttl_minutes': _ttl.inMinutes,
      'is_valid': isValid(),
    };
  }

  /// Get time until cache expires (in seconds)
  int? getSecondsUntilExpiry() {
    if (_cacheTimestamp == null) return null;
    final elapsed = DateTime.now().difference(_cacheTimestamp!);
    final remaining = _ttl - elapsed;
    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }
}

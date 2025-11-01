import 'dart:collection';
import 'models/message.dart';

/// In-memory cache for DM messages to reduce database queries
/// and improve conversation loading performance
class DMMessageCache {
  DMMessageCache._();
  static final DMMessageCache instance = DMMessageCache._();

  // Cache structure: conversationId -> cached messages
  final LinkedHashMap<String, CachedConversation> _cache =
      LinkedHashMap<String, CachedConversation>();

  // Configuration
  final Duration _ttl = const Duration(minutes: 5);
  final int _maxConversations = 20; // Cache up to 20 recent conversations
  final int _messagesPerConversation = 100; // Cache last 100 messages per conversation

  // Statistics
  int _hits = 0;
  int _misses = 0;

  /// Get cached messages for a conversation
  List<Message>? get(String conversationId) {
    final cached = _cache.remove(conversationId); // Remove for LRU
    if (cached == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (DateTime.now().difference(cached.timestamp) > _ttl) {
      _misses++;
      return null; // Don't re-add expired entries
    }

    // Re-add at end for LRU
    _cache[conversationId] = cached;
    _hits++;
    return List.from(cached.messages); // Return copy to prevent external modification
  }

  /// Cache messages for a conversation
  void put(String conversationId, List<Message> messages) {
    // Remove existing entry
    _cache.remove(conversationId);

    // Limit messages to configured maximum
    final messagesToCache = messages.length > _messagesPerConversation
        ? messages.sublist(messages.length - _messagesPerConversation)
        : messages;

    // Add new entry at end
    _cache[conversationId] = CachedConversation(
      messages: List.from(messagesToCache),
      timestamp: DateTime.now(),
    );

    // Enforce max conversations limit using LRU eviction
    while (_cache.length > _maxConversations) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Append a new message to cached conversation (optimistic update)
  void appendMessage(String conversationId, Message message) {
    final cached = _cache[conversationId];
    if (cached == null) return;

    // Add message to end
    final updatedMessages = [...cached.messages, message];

    // Limit to max messages
    final messagesToCache = updatedMessages.length > _messagesPerConversation
        ? updatedMessages.sublist(updatedMessages.length - _messagesPerConversation)
        : updatedMessages;

    // Update cache with new timestamp
    _cache[conversationId] = CachedConversation(
      messages: messagesToCache,
      timestamp: DateTime.now(),
    );
  }

  /// Update a message in cache (e.g., status change from sending to sent)
  void updateMessage(String conversationId, Message updatedMessage) {
    final cached = _cache[conversationId];
    if (cached == null) return;

    final updatedMessages = cached.messages.map((msg) {
      // Match by ID or localId
      if (msg.id == updatedMessage.id ||
          (msg.localId != null && msg.localId == updatedMessage.localId)) {
        return updatedMessage;
      }
      return msg;
    }).toList();

    _cache[conversationId] = CachedConversation(
      messages: updatedMessages,
      timestamp: cached.timestamp, // Keep original timestamp
    );
  }

  /// Remove a specific message from cache (e.g., message deleted)
  void removeMessage(String conversationId, String messageId) {
    final cached = _cache[conversationId];
    if (cached == null) return;

    final updatedMessages = cached.messages
        .where((msg) => msg.id != messageId)
        .toList();

    _cache[conversationId] = CachedConversation(
      messages: updatedMessages,
      timestamp: cached.timestamp,
    );
  }

  /// Invalidate (clear) cache for a specific conversation
  void invalidate(String conversationId) {
    _cache.remove(conversationId);
  }

  /// Clear all cached messages
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final total = _hits + _misses;
    return {
      'cached_conversations': _cache.length,
      'max_conversations': _maxConversations,
      'hits': _hits,
      'misses': _misses,
      'hit_rate': total > 0 ? '${(_hits / total * 100).toStringAsFixed(1)}%' : '0%',
      'ttl_minutes': _ttl.inMinutes,
    };
  }

  /// Check if conversation is cached
  bool isCached(String conversationId) {
    final cached = _cache[conversationId];
    if (cached == null) return false;
    return DateTime.now().difference(cached.timestamp) <= _ttl;
  }
}

/// Internal class to store cached messages with timestamp
class CachedConversation {
  final List<Message> messages;
  final DateTime timestamp;

  CachedConversation({
    required this.messages,
    required this.timestamp,
  });
}

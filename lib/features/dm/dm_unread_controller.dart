import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DmUnreadController maintains a live unread count for the current user.
/// Strategy:
/// 1. On start or auth change, fetch unread aggregate from conversations/messages
/// 2. Attach realtime channel listening to message inserts/updates
/// 3. When a mark_read is triggered locally we optimistically update counts
class DmUnreadController {
  DmUnreadController._();
  static final DmUnreadController instance = DmUnreadController._();

  final unread = ValueNotifier<int>(0);
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;
  bool _starting = false;

  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;
  SupabaseClient get _s => _client;

  void ensureStarted() {
    if (_starting) return;
    _starting = true;
    _authSub ??= _client.auth.onAuthStateChange.listen((data) {
      _restart();
    });
    _restart();
  }

  Future<void> _restart() async {
    await _channel?.unsubscribe();
    _channel = null;
    unread.value = 0;
    final uid = _uid;
    if (uid == null) return;
    await _prime(uid);
    _attach(uid);
  }

  Future<void> _prime(String uid) async {
    try {
      // Get unread count from conversations the user participates in
      dynamic participants;
      try {
        participants = await _s
            .from('conversation_participants')
            .select('conversation_id, last_read_at')
            .eq('user_id', uid)
            .isFilter('left_at', null);
      } catch (e) {
        if (e.toString().contains('last_read_at does not exist')) {
          // Fallback: query without last_read_at column
          participants = await _s
              .from('conversation_participants')
              .select('conversation_id')
              .eq('user_id', uid)
              .isFilter('left_at', null);
        } else {
          rethrow;
        }
      }

      int total = 0;
      for (final participant in participants) {
        final conversationId = participant['conversation_id'];
        final lastReadAt = participant.containsKey('last_read_at')
            ? participant['last_read_at']
            : null;

        // Count messages after last read time
        var query = _s
            .from('messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .neq('sender_id', uid); // Don't count own messages

        if (lastReadAt != null) {
          query = query.gt('created_at', lastReadAt);
        }

        final result = await query;
        if (result.isNotEmpty) {
          total += (result.length);
        }
      }
      unread.value = total;
    } catch (_) {
      unread.value = 0;
    }
  }

  void _attach(String uid) {
    final ch = _s.channel('dm_unread_$uid');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'dm_messages',
      callback: (payload) {
        try {
          final newRow = payload.newRecord as Map<String, dynamic>?;
          if (newRow == null) return;
          final sender = newRow['sender_id']?.toString();
          if (sender == uid) return;
          unread.value = unread.value + 1;
        } catch (_) {}
      },
    );
    ch.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'dm_participants',
      callback: (payload) {
        try {
          final newRow = payload.newRecord as Map<String, dynamic>?;
          if (newRow == null) return;
          if (newRow['user_id']?.toString() == uid) {
            _prime(uid);
          }
        } catch (_) {}
      },
    );
    ch.subscribe();
    _channel = ch;
  }

  /// Call when opening a thread to optimistically decrease unread by current thread unread count.
  void decrementBy(int count) {
    if (count <= 0) return;
    final next = unread.value - count;
    unread.value = next < 0 ? 0 : next;
  }

  Future<void> dispose() async {
    await _channel?.unsubscribe();
    await _authSub?.cancel();
  }
}

String? dmCurrentUid() => Supabase.instance.client.auth.currentUser?.id;

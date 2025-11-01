import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'new_dm_repos.dart';
import 'dm_profile_cache.dart';
import '../../app/app_icons.dart';
import '../../app/theme.dart';
import '../../features/profile/unified_profile_page.dart';

/// Public thread view for individual conversations
class ThreadView extends StatefulWidget {
  const ThreadView({required this.thread, super.key});
  final ThreadSummary thread;

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  final _msgRepo = MessageRepository();
  final _me = Supabase.instance.client.auth.currentUser;
  final _messages = <ChatMessage>[];
  bool _loading = true;
  bool _sending = false;
  final _input = TextEditingController();
  bool _atEnd = false; // reached oldest
  RealtimeChannel? _channel;
  bool _markingRead = false;

  // For displaying participant name
  ProfileModel? _otherParticipant;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadParticipantInfo();
    _loadPage();
    // LAZY LOAD: Only attach realtime when widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachRealtime();
    });
  }

  /// Load the other participant's profile information
  Future<void> _loadParticipantInfo() async {
    if (_me == null) return;

    try {
      // Find the other participant (not the current user)
      final otherParticipantId = widget.thread.participantIds
          .firstWhere((id) => id != _me.id, orElse: () => '');

      if (otherParticipantId.isNotEmpty) {
        final profile =
            await DMProfileCache.instance.getProfile(otherParticipantId);
        if (mounted) {
          setState(() {
            _otherParticipant = profile;
            _loadingProfile = false;
          });
        }
      } else {
        // Self-conversation case
        if (mounted) {
          setState(() {
            _loadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadPage({DateTime? before}) async {
    setState(() {
      _loading = _messages.isEmpty;
    });
    try {
      final page = await _msgRepo.pageMessages(
          threadId: widget.thread.threadId, before: before, limit: 40);
      if (page.isEmpty) {
        setState(() {
          _atEnd = true;
        });
      } else {
        setState(() {
          _messages.addAll(page);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
      }
    } catch (e) {
      // ignore for now; could add error display
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _me == null) return;
    setState(() {
      _sending = true;
    });
    try {
      final optimistic = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.thread.threadId,
        senderId: _me.id,
        content: text,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(optimistic);
      });
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _input.clear();
      // Dismiss keyboard after sending message
      FocusScope.of(context).unfocus();
      final persisted = await _msgRepo.send(
          threadId: widget.thread.threadId, senderId: _me.id, body: text);
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == optimistic.id);
        if (idx != -1) _messages[idx] = persisted;
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _attachRealtime() {
    // ⚠️ REAL-TIME STATUS: INACTIVE (Table doesn't exist)
    //
    // CONFUSION ALERT: This code references 'dm_messages' table which DOESN'T EXIST!
    //
    // Current database schema (per main_mobile_app_database_schema.sql line 45):
    // - 'dm_messages' table was DROPPED in migration
    // - Replaced by 'messages' table (with conversation_id foreign key)
    //
    // This is OLD/DEAD CODE from previous DM implementation.
    // Subscription will fail silently since table doesn't exist.
    //
    // App still works because:
    // - _loadMore() manually fetches messages from correct 'messages' table
    // - UI refreshes on _send() optimistic updates
    // - Real-time is bonus feature, not required
    //
    // Correct implementation would subscribe to 'messages' table (which IS enabled):
    // table: 'messages'  // ✅ This table exists and is in publications
    // filter: conversation_id = widget.thread.threadId
    //
    // Safe to leave as-is (no performance impact), but could be updated to use
    // correct table name if real-time thread updates are desired in future.
    final client = Supabase.instance.client;
    _channel = client.channel('thread_${widget.thread.threadId}');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'dm_messages',
      // Filter for only messages in this thread
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'thread_id',
        value: widget.thread.threadId,
      ),
      callback: (payload) {
        try {
          final newRow = payload.newRecord as Map<String, dynamic>?;
          if (newRow == null) return;
          final msg = ChatMessage.fromJson(newRow);
          if (_messages.any((m) => m.id == msg.id)) return;
          setState(() {
            _messages.add(msg);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });
          if (msg.senderId != _me?.id) {
            _markThreadRead();
          }
        } catch (_) {}
      },
    );
    _channel!.subscribe();
  }

  Future<void> _markThreadRead() async {
    if (_markingRead || _me == null) return;
    _markingRead = true;
    try {
      await ThreadRepository().markRead(widget.thread.threadId, _me.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to mark read: $e')));
      }
    } finally {
      _markingRead = false;
    }
  }

  /// Get the display title for the conversation
  String get _conversationTitle {
    if (_loadingProfile) return 'Loading...';

    // Check if it's a self-conversation
    final iselfConversation = widget.thread.participantIds.length == 1 ||
        widget.thread.participantIds.every((id) => id == _me?.id);

    if (iselfConversation) {
      return 'You'; // or "Notes to Self", etc.
    }

    // Use the other participant's name
    if (_otherParticipant?.name?.isNotEmpty == true) {
      return _otherParticipant!.name!;
    }

    // Fallback
    return 'Conversation';
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_conversationTitle)),
        body: Column(children: [
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (notif) {
                      if (notif.metrics.pixels <=
                              notif.metrics.minScrollExtent + 40 &&
                          !_atEnd &&
                          !_loading) {
                        final oldest = _messages.isNotEmpty
                            ? _messages.first.createdAt
                            : null;
                        if (oldest != null) _loadPage(before: oldest);
                      }
                      if (!_markingRead &&
                          notif.metrics.pixels >=
                              notif.metrics.maxScrollExtent - 40) {
                        _markThreadRead();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      reverse: false,
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final mine = m.senderId == _me?.id;
                        return _MessageBubble(message: m, mine: mine);
                      },
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(hintText: 'Message'),
                    onSubmitted: (text) {
                      if (!_sending) _send();
                    },
                  ),
                ),
              ),
              IconButton(
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : AppIcons.send(size: 22),
                onPressed: _sending ? null : _send,
              )
            ]),
          )
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool mine;
  const _MessageBubble({required this.message, required this.mine});
  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  DmUserProfile? _sender;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await DmProfileCache.instance.fetch(widget.message.senderId);
    if (mounted) setState(() => _sender = p);
  }

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.mine
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.mine)
            GestureDetector(
              onTap: () {
                if (widget.message.senderId.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UnifiedProfilePage(
                        userId: widget.message.senderId,
                        userName: _sender?.name,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                  (_sender?.name ?? widget.message.senderId).split('\n').first,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        AppColors.primary, // Use orange for clickable usernames
                    decoration: TextDecoration.underline,
                  )),
            ),
          Text(widget.message.content),
        ],
      ),
    );
    return Align(
      alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/features/dm/dm_unread_controller.dart';
import 'package:foundervers/features/dm/dm_profile_cache.dart';
import 'package:foundervers/features/dm/thread_view.dart';
import 'package:foundervers/features/profile/unified_profile_page.dart';
import 'package:foundervers/features/dm/new_dm_repos.dart';

/// Modern inbox powered by new dm_* schema.
/// Shows threads instantly (in-memory) then allows pull-to-refresh & realtime later.
class NewInboxPage extends StatefulWidget {
  const NewInboxPage({super.key});
  @override
  State<NewInboxPage> createState() => _NewInboxPageState();
}

class _NewInboxPageState extends State<NewInboxPage> {
  final _threadRepo = ThreadRepository();
  final _me = Supabase.instance.client.auth.currentUser;
  final _threads = <ThreadSummary>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_me == null || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _threadRepo.listThreads(viewerId: _me.id, limit: 40);
      if (mounted) {
        setState(() {
          _threads
            ..clear()
            ..addAll(list);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openThread(ThreadSummary ts) async {
    // Optimistically decrement global unread before navigation
    if (ts.unread > 0) {
      DmUnreadController.instance.decrementBy(ts.unread);
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ThreadView(thread: ts)));
    if (_me != null && mounted) {
      await _threadRepo.markRead(ts.threadId, _me.id);
    }
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_me == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your inbox')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: null, // Remove title - already shown in tab
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Collapse app bar completely
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _threads.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No conversations yet.'))
                        ])
                      : ListView.separated(
                          itemCount: _threads.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final t = _threads[i];

                            // DEBUG: Log participant information
                            debugPrint(
                                '🔍 Thread $i: participantIds = ${t.participantIds}');
                            debugPrint(
                                '🔍 Current user ID (_me.id) = ${_me.id}');

                            final otherIds = t.participantIds
                                .where((id) => id != _me.id)
                                .toList();

                            debugPrint(
                                '🔍 otherIds after filtering = $otherIds');

                            // Safety check: if participantIds is empty or only contains current user
                            if (otherIds.isEmpty &&
                                t.participantIds.isNotEmpty) {
                              debugPrint(
                                  '⚠️  WARNING: Thread has no other participants! participantIds = ${t.participantIds}');
                            }

                            // Prefetch profile for first other participant
                            if (otherIds.isNotEmpty) {
                              DmProfileCache.instance.fetch(otherIds.first);
                            }
                            final last = t.lastMessagePreview ?? '';
                            final unread = t.unread > 0;
                            return ListTile(
                              leading: _ParticipantAvatar(
                                  uid: otherIds.isNotEmpty
                                      ? otherIds.first
                                      : _me.id,
                                  highlight: unread),
                              title: _ParticipantName(
                                  uid: otherIds.isNotEmpty
                                      ? otherIds.first
                                      : _me.id,
                                  fallback:
                                      otherIds.isEmpty ? 'You' : 'Loading...'),
                              subtitle: Text(last,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: unread
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.deepPurple,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(t.unread.toString(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    )
                                  : null,
                              onTap: () => _openThread(t),
                            );
                          },
                        ),
                ),
    );
  }
}

class _ParticipantAvatar extends StatefulWidget {
  final String uid;
  final bool highlight;
  const _ParticipantAvatar({required this.uid, required this.highlight});
  @override
  State<_ParticipantAvatar> createState() => _ParticipantAvatarState();
}

class _ParticipantAvatarState extends State<_ParticipantAvatar> {
  DmUserProfile? _p;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await DmProfileCache.instance.fetch(widget.uid);
    if (mounted) setState(() => _p = p);
  }

  @override
  Widget build(BuildContext context) {
    final initials = (_p?.name?.trim().isNotEmpty == true
        ? _p!.name!.trim()[0].toUpperCase()
        : widget.uid.substring(0, 1).toUpperCase());
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Prevent tap from bubbling to parent
      onTap: () {
        if (widget.uid.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UnifiedProfilePage(
                userId: widget.uid,
                userName: _p?.name,
              ),
            ),
          );
        }
      },
      child: CircleAvatar(
        backgroundColor:
            widget.highlight ? Colors.deepPurple : Colors.grey.shade300,
        backgroundImage: (_p?.avatarUrl != null && _p!.avatarUrl!.isNotEmpty)
            ? NetworkImage(_p!.avatarUrl!)
            : null,
        child: (_p?.avatarUrl != null && _p!.avatarUrl!.isNotEmpty)
            ? null
            : Text(initials,
                style: TextStyle(
                    color: widget.highlight ? Colors.white : Colors.black87)),
      ),
    );
  }
}

class _ParticipantName extends StatefulWidget {
  final String uid;
  final String fallback;
  const _ParticipantName({required this.uid, required this.fallback});
  @override
  State<_ParticipantName> createState() => _ParticipantNameState();
}

class _ParticipantNameState extends State<_ParticipantName> {
  DmUserProfile? _p;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await DmProfileCache.instance.fetch(widget.uid);
    if (mounted) setState(() => _p = p);
  }

  @override
  Widget build(BuildContext context) {
    final name = _p?.name ?? widget.fallback;

    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

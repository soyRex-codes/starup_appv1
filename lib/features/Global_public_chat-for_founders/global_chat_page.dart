import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/core/visibility.dart';
import 'package:foundervers/features/profile/unified_profile_page.dart';
import 'package:foundervers/services/moderation_service.dart';
import 'global_chat_cache.dart';

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final _controller = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _cache = GlobalChatCache.instance;

  // Get current user from Supabase
  User? get _currentUser => _supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  /// Load initial messages with caching
  Future<void> _loadInitialMessages() async {
    // Check cache first
    final cached = _cache.get();
    if (cached != null) {
      debugPrint('📦 Global Chat Cache HIT - ${cached.length} messages');
      return; // Use real-time stream with cached data
    }

    debugPrint('📭 Global Chat Cache MISS - fetching from database');

    // Fetch from database
    try {
      final messages = await _supabase
          .from('chat_messages')
          .select('*')
          .order('created_at', ascending: true)
          .limit(200);

      final messageList = (messages as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Cache the results
      _cache.put(messageList);
    } catch (e) {
      debugPrint('Error loading initial messages: $e');
    }
  }

  // Stream messages from chat_messages table with cache integration
  Stream<List<Map<String, dynamic>>> _streamMessages({int limit = 200}) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(limit)
        .map((rows) {
          final messages =
              rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();

          // Update cache with streamed messages
          if (messages.isNotEmpty) {
            _cache.put(messages);
          }

          return messages;
        });
  }

  // Send message to chat_messages table
  Future<void> _sendMessage(String content) async {
    if (_currentUser == null) return;

    try {
      // Check content moderation before sending
      final moderationService = ModerationService();
      final moderationResult =
          await moderationService.moderateText(content: content);
      final shouldBlock = moderationResult.blocked;

      if (shouldBlock) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Message violates community guidelines. Please revise and try again.')),
          );
        }
        return;
      }

      // Get user profile for display name
      final userProfile = await _supabase
          .from('users')
          .select('name, full_name, username')
          .eq('id', _currentUser!.id)
          .single();

      // Use full_name, then name, then username, then email as fallback
      final displayName = userProfile['full_name'] ??
          userProfile['name'] ??
          userProfile['username'] ??
          _currentUser!.email?.split('@')[0] ??
          'User';

      await _supabase.from('chat_messages').insert({
        'user_id': _currentUser!.id,
        'user_name': displayName,
        'content': content,
      });

      // Note: Real-time stream will automatically update the UI and cache
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamMessages(limit: 200),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading messages: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Start the conversation!'),
                    );
                  }

                  final admins = AppEnv.adminEmails;
                  final messages = snapshot.data!;

                  // Filter messages using visibility rules if needed
                  final visibleMessages = messages
                      .where((m) => VisibilityRules.canSeeMessage(
                          message: m, me: _currentUser, admins: admins))
                      .toList();

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: visibleMessages.length,
                    itemBuilder: (context, i) {
                      final m = visibleMessages[i];
                      final isMe =
                          (m['user_id'] ?? '') == (_currentUser?.id ?? '');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              // Avatar on left for others
                              _AvatarCircle(
                                userId: m['user_id'] as String?,
                                userName: m['user_name'] as String?,
                              ),
                              const SizedBox(width: 6),
                            ],
                            // Message bubble
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(
                                          0xFFE8DCC8) // Light brown for sent messages
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isMe ? 12 : 4),
                                    topRight: Radius.circular(isMe ? 4 : 12),
                                    bottomLeft: const Radius.circular(12),
                                    bottomRight: const Radius.circular(12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Text(
                                        m['user_name'] ?? 'User',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF8B4513),
                                        ),
                                      ),
                                    if (!isMe) const SizedBox(height: 2),
                                    Text(
                                      m['content'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              // Avatar on right for current user
                              _AvatarCircle(
                                userId: m['user_id'] as String?,
                                userName: m['user_name'] as String?,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) async {
                            final message = text.trim();
                            if (message.isEmpty || _currentUser == null) return;

                            _controller.clear();
                            // Keyboard automatically dismisses on submit
                            await _sendMessage(message);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, size: 18, color: Colors.white),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final text = _controller.text.trim();
                          if (text.isEmpty || _currentUser == null) return;

                          _controller.clear();
                          // Dismiss keyboard after sending message
                          FocusScope.of(context).unfocus();
                          await _sendMessage(text);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circle component for user profiles - reused from feed posts
class _AvatarCircle extends StatefulWidget {
  final String? userId;
  final String? userName;

  const _AvatarCircle({this.userId, this.userName});

  @override
  State<_AvatarCircle> createState() => _AvatarCircleState();
}

class _AvatarCircleState extends State<_AvatarCircle> {
  String? _avatarUrl;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      setState(() {
        _displayName = widget.userName ?? 'User';
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name, full_name, username, avatar_url')
          .eq('id', widget.userId!)
          .single();

      if (mounted) {
        setState(() {
          _displayName = response['full_name'] ??
              response['name'] ??
              response['username'] ??
              widget.userName ??
              'User';
          _avatarUrl = response['avatar_url'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayName = widget.userName ?? 'User';
        });
      }
    }
  }

  String get initial {
    if (_displayName == null || _displayName!.isEmpty) return '?';
    return _displayName!.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.userId != null && widget.userId!.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UnifiedProfilePage(
                userId: widget.userId!,
                userName: _displayName,
              ),
            ),
          );
        }
      },
      child: CircleAvatar(
        radius: 12, // 24px diameter (compact)
        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!)
            : null,
        backgroundColor: Colors.blue[300],
        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
            ? Text(initial,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))
            : null,
      ),
    );
  }
}

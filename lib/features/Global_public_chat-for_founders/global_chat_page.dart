import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/core/visibility.dart';
import 'package:foundervers/features/profile/public_profile_page.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/services/moderation_service.dart';

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final _controller = TextEditingController();
  final _supabase = Supabase.instance.client;

  // Get current user from Supabase
  User? get _currentUser => _supabase.auth.currentUser;

  // Stream messages from chat_messages table
  Stream<List<Map<String, dynamic>>> _streamMessages({int limit = 200}) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .limit(limit)
        .map((rows) =>
            rows.map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }

  // Send message to chat_messages table
  Future<void> _sendMessage(String content) async {
    if (_currentUser == null) return;

    try {
      // Check content moderation before sending
      final moderationService = ModerationService();
  final moderationResult = await moderationService.moderateText(content: content);
  final shouldBlock = moderationResult.blocked;

  if (shouldBlock) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message violates community guidelines. Please revise and try again.')),
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
        appBar: AppBar(
          title: const Text('Global Chat'),
          automaticallyImplyLeading: false, // Remove back button
        ),
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
                    padding: const EdgeInsets.all(8),
                    itemCount: visibleMessages.length,
                    itemBuilder: (context, i) {
                      final m = visibleMessages[i];
                      final isMe =
                          (m['user_id'] ?? '') == (_currentUser?.id ?? '');

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.deepPurple.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile header using feed post pattern
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _AvatarCircle(
                                    userId: m['user_id'] as String?,
                                    userName: m['user_name'] as String?,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m['user_name'] ?? 'User',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(m['content'] ?? ''),
                            ],
                          ),
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
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: 3,
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: AppIcons.send(size: 24),
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty || _currentUser == null) return;

                        _controller.clear();
                        // Dismiss keyboard after sending message
                        FocusScope.of(context).unfocus();
                        await _sendMessage(text);
                      },
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
              builder: (context) => PublicProfilePage(
                userId: widget.userId!,
                userName: _displayName,
              ),
            ),
          );
        }
      },
      child: CircleAvatar(
        radius: 16,
        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            ? NetworkImage(_avatarUrl!)
            : null,
        backgroundColor: Colors.blue[300],
        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
            ? Text(initial,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))
            : null,
      ),
    );
  }
}

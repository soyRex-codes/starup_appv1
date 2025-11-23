import 'package:flutter/material.dart';
import 'package:foundervers/services/user_blocking_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final _blockingService = UserBlockingService();
  List<Map<String, dynamic>>? _blockedProfiles;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _blockingService.getBlockedProfiles();
      if (mounted) {
        setState(() {
          _blockedProfiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blocked users: $e')),
        );
      }
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    try {
      await _blockingService.unblockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unblocked $userName')),
        );
        _loadBlockedUsers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unblocking user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedProfiles == null || _blockedProfiles!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _blockedProfiles!.length,
                  itemBuilder: (context, index) {
                    final profile = _blockedProfiles![index];
                    final userId = profile['id'] as String;
                    final name = profile['name'] as String? ?? 'Unknown';
                    final username = profile['username'] as String? ?? '';
                    final avatarUrl = profile['avatar_url'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl == null ? Text(name[0].toUpperCase()) : null,
                      ),
                      title: Text(name),
                      subtitle: username.isNotEmpty ? Text('@$username') : null,
                      trailing: TextButton(
                        onPressed: () => _unblockUser(userId, name),
                        child: const Text('Unblock'),
                      ),
                    );
                  },
                ),
    );
  }
}

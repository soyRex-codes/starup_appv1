import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await AdminService.getAllUsers(limit: 100);
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _suspendUser(String userId, String userName) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend $userName'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for suspension',
            hintText: 'Enter the reason...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Suspend', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await AdminService.suspendUser(userId, reason);
        _loadUsers(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User suspended successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error suspending user: $e')),
          );
        }
      }
    }
  }

  Future<void> _unsuspendUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsuspend $userName'),
        content: const Text('Are you sure you want to remove the suspension?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.unsuspendUser(userId);
        _loadUsers(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unsuspended successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error unsuspending user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          // Users list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchController.text.isEmpty) return _users;
    return _users.where((user) {
      final query = _searchController.text.toLowerCase();
      return (user['name'] ?? '').toLowerCase().contains(query) ||
             (user['email'] ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isSuspended = user['is_suspended'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and actions
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (user['name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['name'] ?? 'No name',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (isSuspended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SUSPENDED',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        user['email'] ?? 'No email',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'suspend':
                        _suspendUser(user['id'], user['name'] ?? 'User');
                        break;
                      case 'unsuspend':
                        _unsuspendUser(user['id'], user['name'] ?? 'User');
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isSuspended)
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Suspend', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    if (isSuspended)
                      const PopupMenuItem(
                        value: 'unsuspend',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Unsuspend', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // User details
            if (user['username'] != null)
              _buildDetailRow('Username', user['username']),
            if (user['full_name'] != null)
              _buildDetailRow('Full Name', user['full_name']),
            if (user['bio'] != null)
              _buildDetailRow('Bio', user['bio']),
            if (user['company'] != null)
              _buildDetailRow('Company', user['company']),
            if (user['location'] != null)
              _buildDetailRow('Location', user['location']),
            
            _buildDetailRow('Email Verified', user['email_verified'] == true ? 'Yes' : 'No'),
            _buildDetailRow('Member Since', _formatDate(user['created_at'])),
            if (user['last_login_at'] != null)
              _buildDetailRow('Last Login', _formatDate(user['last_login_at'])),

            // Suspension details
            if (isSuspended) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suspension Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user['suspension_reason'] != null)
                      Text('Reason: ${user['suspension_reason']}'),
                    if (user['suspended_at'] != null)
                      Text('Suspended: ${_formatDate(user['suspended_at'])}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
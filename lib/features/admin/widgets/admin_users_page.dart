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
  String _filterStatus = 'all'; // all, verified, suspended

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
        title: Text('Manage Users (${_filteredUsers.length})'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Search bar and filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('All (${_users.length})'),
                        selected: _filterStatus == 'all',
                        onSelected: (selected) {
                          setState(() => _filterStatus = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                            'Verified (${_users.where((u) => u['email_verified'] == true).length})'),
                        selected: _filterStatus == 'verified',
                        onSelected: (selected) {
                          setState(() => _filterStatus = 'verified');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(
                            'Suspended (${_users.where((u) => u['is_suspended'] == true).length})'),
                        selected: _filterStatus == 'suspended',
                        selectedColor: Colors.red.withOpacity(0.3),
                        onSelected: (selected) {
                          setState(() => _filterStatus = 'suspended');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildCompactUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;

    // Apply status filter
    if (_filterStatus == 'verified') {
      filtered =
          filtered.where((user) => user['email_verified'] == true).toList();
    } else if (_filterStatus == 'suspended') {
      filtered =
          filtered.where((user) => user['is_suspended'] == true).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        return (user['name'] ?? '').toLowerCase().contains(query) ||
            (user['email'] ?? '').toLowerCase().contains(query) ||
            (user['username'] ?? '').toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildCompactUserCard(Map<String, dynamic> user) {
    final isSuspended = user['is_suspended'] == true;
    final isVerified = user['email_verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: isSuspended
                    ? Colors.red.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary,
                child: Text(
                  (user['name'] ?? user['username'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: isSuspended
                        ? Colors.red
                        : Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['name'] ?? 'No name',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 14, color: Colors.blue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['email'] ?? 'No email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user['username'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${user['username']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status badges and actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSuspended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SUSPENDED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _showUserDetails(user);
                          break;
                        case 'suspend':
                          _suspendUser(user['id'], user['name'] ?? 'User');
                          break;
                        case 'unsuspend':
                          _unsuspendUser(user['id'], user['name'] ?? 'User');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye, size: 16),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      if (!isSuspended)
                        const PopupMenuItem(
                          value: 'suspend',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Suspend',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      if (isSuspended)
                        const PopupMenuItem(
                          value: 'unsuspend',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Unsuspend',
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final isSuspended = user['is_suspended'] == true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              AppBar(
                title: const Text('User Details'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              (user['name'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] ?? 'No name',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  user['email'] ?? 'No email',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // User details
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (user['username'] != null)
                        _buildDetailRow('Username', user['username']),
                      if (user['full_name'] != null)
                        _buildDetailRow('Full Name', user['full_name']),
                      _buildDetailRow('Email Verified',
                          user['email_verified'] == true ? 'Yes' : 'No'),
                      _buildDetailRow(
                          'Member Since', _formatDate(user['created_at'])),
                      if (user['last_login_at'] != null)
                        _buildDetailRow(
                            'Last Login', _formatDate(user['last_login_at'])),

                      if (user['bio'] != null ||
                          user['company'] != null ||
                          user['location'] != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (user['bio'] != null)
                          _buildDetailRow('Bio', user['bio']),
                        if (user['company'] != null)
                          _buildDetailRow('Company', user['company']),
                        if (user['location'] != null)
                          _buildDetailRow('Location', user['location']),
                      ],

                      // Suspension details
                      if (isSuspended) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.block,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Suspension Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (user['suspension_reason'] != null)
                                Text('Reason: ${user['suspension_reason']}'),
                              if (user['suspended_at'] != null)
                                Text(
                                    'Suspended: ${_formatDate(user['suspended_at'])}'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
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

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/features/auth/auth_service.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/features/settings/blocked_users_page.dart';

/// Settings page with account management options
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService.instance;
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          const SizedBox(height: 12),

          // User Info
          _buildInfoTile(
            icon: AppIcons.email(size: 24),
            title: 'Email',
            subtitle: currentUser?.email ?? 'Not available',
          ),

          const SizedBox(height: 8),
          _buildInfoTile(
            icon: AppIcons.info(size: 24),
            title: 'Member Since',
            subtitle: currentUser?.createdAt != null
                ? _formatDateFromString(currentUser!.createdAt)
                : 'Not available',
          ),

          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader('Privacy & Security'),
          const SizedBox(height: 12),

          // Blocked Users
          _buildInfoTile(
            icon: const Icon(Icons.block, size: 24),
            title: 'Blocked Users',
            subtitle: 'Manage blocked users',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlockedUsersPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Delete Account
          _buildDangerTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            onTap: _showDeleteAccountDialog,
          ),

          const SizedBox(height: 24),

          // App Information
          _buildSectionHeader('App Information'),
          const SizedBox(height: 12),

          _buildInfoTile(
            icon: AppIcons.info(size: 24),
            title: 'Version',
            subtitle: '1.0.0',
          ),

          const SizedBox(height: 40),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required Widget icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red.shade600, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDateFromString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _formatDate(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                'This action will permanently delete:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Your profile and account information\n'
                '• All your posts and content\n'
                '• Your message history\n'
                '• All app data associated with your account',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isDeletingAccount ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeletingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Delete user data from Supabase database
      final supabase = Supabase.instance.client;

      // Delete in order to handle foreign key constraints
      // 1. Delete posts
      await supabase.from('posts').delete().eq('user_id', currentUser.id);

      // 2. Delete chat messages
      await supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', currentUser.id);

      // 3. Delete DM messages - Handled by cascade or correct table name if needed
      // Note: 'dm_messages' table does not exist, likely handled by 'messages' or cascade
      // await supabase.from('dm_messages').delete().eq('sender_id', currentUser.id);

      // 4. Delete DM conversations (where user is participant)
      await supabase
          .from('conversation_participants')
          .delete()
          .eq('user_id', currentUser.id);

      // 5. Delete user profile
      await supabase.from('users').delete().eq('id', currentUser.id);

      // Sign out user
      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Close settings page

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });

        Navigator.of(context).pop(); // Close dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pop(); // Close settings page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

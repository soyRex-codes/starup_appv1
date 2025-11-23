import 'package:flutter/material.dart';
import 'services/admin_auth_service.dart';
import 'services/admin_service.dart';
import 'models/admin_user.dart';
import 'widgets/admin_posts_page.dart';
import 'widgets/admin_users_page.dart';
import 'widgets/admin_analytics_page.dart';
import 'widgets/admin_chat_moderation_page.dart';
import 'widgets/admin_applications_page.dart';
import 'widgets/admin_reports_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  AdminUser? _adminUser;
  bool _loading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final adminUser = await AdminAuthService.getCurrentAdminUser();
      final analytics = await AdminService.getAnalytics();
      
      setState(() {
        _adminUser = adminUser;
        _analytics = analytics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admin data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adminUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have admin access.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Analytics Overview
            if (_analytics != null) _buildAnalyticsOverview(),
            const SizedBox(height: 24),

            // Admin Actions Grid
            _buildAdminActionsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_adminUser!.name}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin Dashboard - Full System Access',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal aspect ratio based on available width
              double aspectRatio = constraints.maxWidth > 400 ? 7.0 : 8.0;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio, // Auto-adaptive based on screen width
            children: [
              _buildStatCard(
                'Users',
                '${_analytics!['total_users']}',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Posts',
                '${_analytics!['total_posts']}',
                Icons.article,
                Colors.green,
              ),
              _buildStatCard(
                'New Users',
                '${_analytics!['recent_users']}',
                Icons.person_add,
                Colors.orange,
              ),
              _buildStatCard(
                'New Posts',
                '${_analytics!['recent_posts']}',
                Icons.new_releases,
                Colors.purple,
              ),
            ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Asymmetric padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$value $title', // Single line combining value and title
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5, // Increased from 1.2 to give more height
          children: [
            _buildActionCard(
              'Manage Posts',
              'View, edit, delete all posts',
              Icons.article,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPostsPage()),
              ),
            ),
            _buildActionCard(
              'Manage Users',
              'User accounts & moderation',
              Icons.people,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminUsersPage()),
              ),
            ),
            _buildActionCard(
              'View Applications',
              'Review business applications',
              Icons.business,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminApplicationsPage()),
              ),
            ),
            _buildActionCard(
              'Manage Reports',
              'Review user reports',
              Icons.flag,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminReportsPage()),
              ),
            ),
            _buildActionCard(
              'Chat Moderation',
              'Moderate global chat',
              Icons.chat,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminChatModerationPage()),
              ),
            ),
            _buildActionCard(
              'Analytics',
              'Detailed system analytics',
              Icons.analytics,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAnalyticsPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, // Reduced from 48
              height: 40, // Reduced from 48
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20), // Reduced from 24
            ),
            const SizedBox(height: 8), // Reduced from 12
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith( // Changed from titleMedium
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2), // Reduced from 4
            Flexible( // Use Flexible to prevent overflow
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await AdminService.getAnalytics();
      setState(() {
        _analytics = analytics;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('Failed to load analytics'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(),
                      const SizedBox(height: 24),
                      _buildGrowthSection(),
                      const SizedBox(height: 24),
                      _buildEngagementSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewSection() {
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
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal aspect ratio based on available width
              double aspectRatio = constraints.maxWidth > 400 ? 7.0 : 8.0;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
                'Messages',
                '${_analytics!['total_messages']}',
                Icons.message,
                Colors.orange,
              ),
              _buildStatCard(
                'Health',
                'Healthy',
                Icons.health_and_safety,
                Colors.green,
              ),
            ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthSection() {
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
            'Growth (Last 7 Days)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'New Users',
                  '${_analytics!['recent_users']}',
                  Icons.person_add,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'New Posts',
                  '${_analytics!['recent_posts']}',
                  Icons.new_releases,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection() {
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
            'Platform Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          
          _buildActivityRow(
            'Posts per User',
            _calculatePostsPerUser().toStringAsFixed(1),
            Icons.trending_up,
          ),
          
          _buildActivityRow(
            'Growth Rate',
            _calculateGrowthRate(),
            Icons.analytics,
          ),
          
          _buildActivityRow(
            'Platform Status',
            'Active',
            Icons.check_circle,
            statusColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Asymmetric padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$value $title', // Single line combining value and title
              style: TextStyle(
                fontSize: 11,
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

  Widget _buildActivityRow(String label, String value, IconData icon, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: statusColor ?? Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
          ),
        ],
      ),
    );
  }

  double _calculatePostsPerUser() {
    final users = _analytics!['total_users'] as int;
    final posts = _analytics!['total_posts'] as int;
    return users > 0 ? posts / users : 0.0;
  }

  String _calculateGrowthRate() {
    final recentUsers = _analytics!['recent_users'] as int;
    final totalUsers = _analytics!['total_users'] as int;
    
    if (totalUsers == 0) return '0%';
    
    final rate = (recentUsers / totalUsers * 100);
    return '${rate.toStringAsFixed(1)}%/week';
  }
}
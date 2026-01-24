import 'package:flutter/material.dart';
import 'package:foundervers/services/post_report_service.dart';
import 'package:foundervers/services/user_report_service.dart';
import 'package:foundervers/features/admin/services/admin_service.dart';
import 'package:foundervers/features/admin/widgets/report_card.dart';

/// Admin page for reviewing reports (Posts & Users) and pending moderation
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Post Reports'),
              Tab(text: 'User Reports'),
              Tab(text: 'Pending Posts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PostReportsTab(),
            _UserReportsTab(),
            _PendingPostsTab(),
          ],
        ),
      ),
    );
  }
}


class _PostReportsTab extends StatefulWidget {
  const _PostReportsTab();

  @override
  State<_PostReportsTab> createState() => _PostReportsTabState();
}

class _PostReportsTabState extends State<_PostReportsTab> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final reports = await PostReportService.getPendingReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reports: $e')),
        );
      }
    }
  }

  Future<void> _removePost(int postId, String reportId) async {
    try {
      await AdminService.deletePost(postId, 'Reported: $reportId');
      await PostReportService.resolveReport(
        reportId: reportId,
        actionTaken: 'post_removed',
        adminNotes: 'Post removed by admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed successfully')),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove post: $e')),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      await PostReportService.dismissReport(
        reportId: reportId,
        adminNotes: 'Reviewed - no violation found',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No pending post reports!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        itemCount: _reports.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final report = _reports[index];
          final post = report['post'] as Map<String, dynamic>?;

          return ReportCard(
            report: report,
            contentLabel: 'Reported Post:',
            contentWidget: post != null
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post['title'] != null)
                          Text(
                            post['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        if (post['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            post['description'],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),
                  )
                : Text(
                    'Post has been deleted',
                    style: TextStyle(
                        color: Colors.orange[700], fontWeight: FontWeight.w600),
                  ),
            actions: [
              TextButton.icon(
                onPressed: () => _dismissReport(report['id']),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Dismiss'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              if (post != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove Post?'),
                        content: const Text(
                          'This will permanently delete the post. This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Remove Post'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _removePost(post['id'] as int, report['id']);
                    }
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Remove Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UserReportsTab extends StatefulWidget {
  const _UserReportsTab();

  @override
  State<_UserReportsTab> createState() => _UserReportsTabState();
}

class _UserReportsTabState extends State<_UserReportsTab> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final reports = await UserReportService.getPendingReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user reports: $e')),
        );
      }
    }
  }

  Future<void> _banUser(String userId, String reportId, String reason) async {
    try {
      await AdminService.suspendUser(userId, 'Reported: $reason');
      await UserReportService.resolveReport(
        reportId: reportId,
        actionTaken: 'user_banned',
        adminNotes: 'User banned by admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned successfully')),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ban user: $e')),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      await UserReportService.dismissReport(
        reportId: reportId,
        adminNotes: 'Reviewed - no violation found',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No pending user reports!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        itemCount: _reports.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final report = _reports[index];
          final reportedUser = report['reported_user'] as Map<String, dynamic>?;

          return ReportCard(
            report: report,
            contentLabel: 'Reported User:',
            contentWidget: reportedUser != null
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                              (reportedUser['name'] ?? 'U')[0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reportedUser['name'] ?? 'Unknown User',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                reportedUser['email'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    'User not found',
                    style: TextStyle(
                        color: Colors.orange[700], fontWeight: FontWeight.w600),
                  ),
            actions: [
              TextButton.icon(
                onPressed: () => _dismissReport(report['id']),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Dismiss'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              if (reportedUser != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Ban User?'),
                        content: const Text(
                          'This will suspend the user account. They will not be able to log in.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Ban User'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _banUser(reportedUser['id'], report['id'],
                          report['reason']);
                    }
                  },
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Ban User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// PENDING POSTS TAB - For approving/rejecting posts awaiting moderation
// ============================================================================

class _PendingPostsTab extends StatefulWidget {
  const _PendingPostsTab();

  @override
  State<_PendingPostsTab> createState() => _PendingPostsTabState();
}

class _PendingPostsTabState extends State<_PendingPostsTab> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPosts();
  }

  Future<void> _loadPendingPosts() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final posts = await AdminService.getPendingPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pending posts: $e')),
        );
      }
    }
  }

  Future<void> _approvePost(int postId) async {
    try {
      await AdminService.approvePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve post: $e')),
        );
      }
    }
  }

  Future<void> _rejectPost(int postId) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Post'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await AdminService.rejectPost(postId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadPendingPosts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No posts pending review!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadPendingPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final post = _posts[index];
          final user = post['user'] as Map<String, dynamic>? ?? {};
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Title
                  Text(
                    post['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Author info
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'by ${user['name'] ?? 'Unknown'} (${user['email'] ?? 'No email'})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Description preview
                  if (post['description'] != null && 
                      post['description'].toString().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post['description'].toString().length > 200
                            ? '${post['description'].toString().substring(0, 200)}...'
                            : post['description'].toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Created date
                  Text(
                    'Created: ${_formatDate(post['created_at'])}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _rejectPost(post['id'] as int),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _approvePost(post['id'] as int),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
}

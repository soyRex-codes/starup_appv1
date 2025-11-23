import 'package:flutter/material.dart';
import 'package:foundervers/services/post_report_service.dart';
import 'package:foundervers/core/utils/time_formatter.dart';
import 'package:foundervers/features/feed/feed_service.dart';
import 'package:foundervers/features/admin/services/admin_service.dart';

/// Admin page for reviewing post reports
class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String _filter = 'pending'; // 'pending', 'all', 'resolved', 'dismissed'

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
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
    // Delete the post
    try {
      // Use AdminService to delete post (logs action and handles media)
      await AdminService.deletePost(postId, 'Reported: $reportId');
      
      // Resolve the report
      await PostReportService.resolveReport(
        reportId: reportId,
        actionTaken: 'post_removed',
        adminNotes: 'Post removed by admin',
      );   
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed successfully')),
        );
        _loadReports(); // Refresh
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
        _loadReports(); // Refresh
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No pending reports!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('All caught up 🎉',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    itemCount: _reports.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      final post = report['post'] as Map<String, dynamic>?;
                      final reporter = report['reporter'] as Map<String, dynamic>?;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Report header
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color: _getReasonColor(report['reason']),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      PostReportService.reasonLabels[report['reason']] ?? report['reason'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    TimeFormatter.formatTimeAgo(
                                      DateTime.parse(report['created_at']),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Reporter info
                              if (reporter != null) Text(
                                'Reported by: ${reporter['name'] ?? reporter['email']}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              
                              // Report description
                              if (report['description'] != null && report['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    report['description'],
                                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                              
                              const Divider(height: 24),
                              
                              // Post info
                              if (post != null) ...[
                                const Text(
                                  'Reported Post:',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (post['title'] != null) Text(
                                        post['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (post['description'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          post['description'],
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '⚠️ Post has been deleted',
                                  style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _dismissReport(report['id']),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Dismiss'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (post != null) ElevatedButton.icon(
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
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'hate_speech':
      case 'violence':
        return Colors.red;
      case 'harassment':
      case 'inappropriate':
        return Colors.orange;
      case 'spam':
      case 'misleading':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

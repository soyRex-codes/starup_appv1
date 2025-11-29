import 'package:flutter/material.dart';
import 'package:foundervers/core/utils/time_formatter.dart';
import 'package:foundervers/services/post_report_service.dart';

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final Widget contentWidget;
  final List<Widget> actions;
  final String? contentLabel;

  const ReportCard({
    super.key,
    required this.report,
    required this.contentWidget,
    required this.actions,
    this.contentLabel,
  });

  @override
  Widget build(BuildContext context) {
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final reason = report['reason'] as String? ?? 'Unknown';
    final createdAt = DateTime.tryParse(report['created_at'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: _getReasonColor(reason),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PostReportService.reasonLabels[reason] ?? reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  TimeFormatter.formatTimeAgo(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (reporter != null)
              Text(
                'Reported by: ${reporter['name'] ?? reporter['email']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (report['description'] != null &&
                report['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report['description'],
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const Divider(height: 24),
            if (contentLabel != null) ...[
              Text(
                contentLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            contentWidget,
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
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

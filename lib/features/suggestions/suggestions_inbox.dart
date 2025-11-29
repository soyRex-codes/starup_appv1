import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../services/suggestion_service.dart';
import '../../app/app_icons.dart';

class SuggestionsInbox extends StatefulWidget {
  const SuggestionsInbox({super.key});

  @override
  State<SuggestionsInbox> createState() => _SuggestionsInboxState();
}

class _SuggestionsInboxState extends State<SuggestionsInbox> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final suggestions = await SuggestionService.getMySuggestions();
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSuggestions {
    switch (_filter) {
      case 'unread':
        return _suggestions.where((s) => s['is_read'] == false).toList();
      case 'read':
        return _suggestions.where((s) => s['is_read'] == true).toList();
      default:
        return _suggestions;
    }
  }

  String _formatSuggestionType(String type) {
    switch (type) {
      case 'feature':
        return 'Feature Request';
      case 'improvement':
        return 'Product Improvement';
      case 'concept':
        return 'Concept Enhancement';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'feature':
        return AppIcons.notification(size: 20);
      case 'improvement':
        return AppIcons.analytics(size: 20);
      case 'concept':
        return AppIcons.suggest(size: 20);
      case 'other':
        return AppIcons.chat(size: 20);
      default:
        return AppIcons.feedback(size: 20);
    }
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final createdAt = DateTime.parse(suggestion['created_at']);
    final post = suggestion['post'] as Map<String, dynamic>?;
    final postTitle = post?['title'] ?? post?['name'] ?? 'Unknown Post';
    final isRead = suggestion['is_read'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and read status
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: _getTypeIcon(suggestion['suggestion_type']),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatSuggestionType(suggestion['suggestion_type']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Read/Unread indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRead
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                        size: 10,
                        color: isRead ? Colors.grey[600] : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isRead ? 'READ' : 'UNREAD',
                        style: TextStyle(
                          fontSize: 10,
                          color: isRead ? Colors.grey[600] : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              suggestion['title'],
              style: TextStyle(
                fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                fontSize: 16,
                color: isRead ? Colors.grey[700] : Colors.black,
              ),
            ),
            const SizedBox(height: 4),

            // Post reference
            Text(
              'For: $postTitle',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),

            // Description preview
            Text(
              suggestion['description'],
              style: TextStyle(
                fontSize: 14,
                color: isRead ? Colors.grey[600] : Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Footer with user and date
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    suggestion['suggester_name']
                            ?.toString()
                            .substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From: ${suggestion['suggester_name']}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(createdAt),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleReadStatus(suggestion),
                      icon: Icon(
                        isRead
                            ? Icons.mark_email_unread
                            : Icons.mark_email_read,
                        size: 20,
                        color: Colors.blue,
                      ),
                      tooltip: isRead ? 'Mark as Unread' : 'Mark as Read',
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(suggestion),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReadStatus(Map<String, dynamic> suggestion) async {
    final isCurrentlyRead = suggestion['is_read'] == true;
    final suggestionId = suggestion['id'];

    try {
      if (isCurrentlyRead) {
        await SuggestionService.markAsUnread(suggestionId);
      } else {
        await SuggestionService.markAsRead(suggestionId);
      }

      _loadSuggestions(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isCurrentlyRead ? 'Marked as unread' : 'Marked as read'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Suggestion'),
        content: Text(
            'Are you sure you want to delete this suggestion?\n\n"${suggestion['title']}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSuggestion(suggestion['id']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSuggestion(String suggestionId) async {
    final success = await SuggestionService.deleteSuggestion(suggestionId);

    if (success) {
      _loadSuggestions(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete suggestion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions Inbox'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'unread', child: Text('Unread')),
              const PopupMenuItem(value: 'read', child: Text('Read')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_filter == 'all'
                      ? 'All'
                      : _filter == 'unread'
                          ? 'Unread'
                          : 'Read'),
                  Transform.rotate(
                      angle: 3.14159, child: AppIcons.backArrow(size: 20)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSuggestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcons.dms(size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'all'
                            ? 'No suggestions yet'
                            : _filter == 'unread'
                                ? 'No unread suggestions'
                                : 'No read suggestions',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filter == 'all'
                            ? 'Suggestions from users will appear here'
                            : _filter == 'unread'
                                ? 'New suggestions will appear here'
                                : 'Read suggestions will appear here',
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSuggestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionCard(_filteredSuggestions[index]);
                    },
                  ),
                ),
    );
  }
}

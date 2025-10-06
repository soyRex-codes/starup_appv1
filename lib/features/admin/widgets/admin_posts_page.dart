import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({super.key});

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await AdminService.getAllPosts(limit: 100);
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: $e')),
        );
      }
    }
  }

  Future<void> _deletePost(int postId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deletePost(postId, 'Deleted by admin');
        _loadPosts(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting post: $e')),
          );
        }
      }
    }
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final titleController = TextEditingController(text: post['title']);
    final descriptionController = TextEditingController(text: post['description'] ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text,
              'description': descriptionController.text,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await AdminService.updatePost(post['id'], result);
        _loadPosts(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Posts'),
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
                labelText: 'Search posts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Simple client-side filtering
                setState(() {});
              },
            ),
          ),
          // Posts list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? const Center(child: Text('No posts found'))
                    : ListView.builder(
                        itemCount: _filteredPosts.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          return _buildPostCard(post);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_searchController.text.isEmpty) return _posts;
    return _posts.where((post) {
      final query = _searchController.text.toLowerCase();
      return (post['title'] ?? '').toLowerCase().contains(query) ||
             (post['description'] ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final user = post['user'] ?? {};
    final mediaCount = (post['media'] as List?)?.length ?? 0;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title'] ?? 'No title',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'by ${user['name'] ?? 'Unknown'} (${user['email'] ?? 'No email'})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editPost(post);
                        break;
                      case 'delete':
                        _deletePost(post['id'], post['title'] ?? 'Untitled');
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Post content
            if (post['description'] != null && post['description'].isNotEmpty)
              Text(
                post['description'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            // Post metadata
            Wrap(
              spacing: 16,
              children: [
                if (post['category'] != null)
                  Chip(
                    label: Text(post['category']),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                if (mediaCount > 0)
                  Chip(
                    label: Text('$mediaCount media'),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                if (post['funding_goal'] != null)
                  Chip(
                    label: Text('\$${post['funding_goal']}'),
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Timestamps
            Text(
              'Created: ${_formatDate(post['created_at'])}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (post['updated_at'] != post['created_at'])
              Text(
                'Updated: ${_formatDate(post['updated_at'])}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
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
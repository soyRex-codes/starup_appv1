import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../core/storage_utils.dart';
import '../../../core/env.dart';
import '../../../widgets/video_player_widget.dart';
import '../../../app/widgets/filter_sheet.dart';
import '../../../models/post_age.dart';

class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({super.key});

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  // Filter state (reuse from feed)
  String? _categoryFilter;
  String? _goalFilter;
  PostAge _dateRangeFilter = PostAge.all;

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

  Future<void> _viewFullPost(Map<String, dynamic> post) async {
    final media = (post['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final user = post['user'] ?? {};

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              AppBar(
                title: const Text('Post Details'),
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
                      // Title
                      Text(
                        post['title'] ?? 'No title',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),

                      // Author
                      Text(
                        'by ${user['name'] ?? 'Unknown'} (${user['email'] ?? 'No email'})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (post['description'] != null &&
                          post['description'].isNotEmpty) ...[
                        Text(
                          post['description'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Media Gallery
                      if (media.isNotEmpty) ...[
                        Text(
                          'Media (${media.length})',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: media.length,
                          itemBuilder: (context, index) {
                            final item = media[index];
                            final filePath = item['file_path'] as String?;

                            if (filePath == null) {
                              return _buildThumbnailPlaceholder(item);
                            }

                            return _buildMediaThumbnail(
                                item, filePath, media.length);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Metadata
                      const Divider(),
                      _buildInfoRow('Category', post['category'] ?? 'None'),
                      _buildInfoRow('Post Goal', post['post_goal'] ?? 'None'),
                      if (post['funding_goal'] != null)
                        _buildInfoRow(
                            'Funding Goal', '\$${post['funding_goal']}'),
                      _buildInfoRow('Created', _formatDate(post['created_at'])),
                      if (post['updated_at'] != post['created_at'])
                        _buildInfoRow(
                            'Updated', _formatDate(post['updated_at'])),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final titleController = TextEditingController(text: post['title']);
    final descriptionController =
        TextEditingController(text: post['description'] ?? '');

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
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilterSheet,
            tooltip: 'Filter posts',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search posts...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
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
                // Simple client-side filtering
                setState(() {});
              },
            ),
          ),
          // Active filters display
          if (_hasActiveFilters()) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFilterSummary(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
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
    var filtered = _posts;

    // Apply category filter
    if (_categoryFilter != null) {
      filtered = filtered
          .where((post) => post['category'] == _categoryFilter)
          .toList();
    }

    // Apply goal filter
    if (_goalFilter != null) {
      filtered =
          filtered.where((post) => post['post_goal'] == _goalFilter).toList();
    }

    // Apply date range filter
    if (_dateRangeFilter != PostAge.all) {
      final now = DateTime.now();
      filtered = filtered.where((post) {
        final createdAt = DateTime.tryParse(post['created_at'] ?? '');
        if (createdAt == null) return false;
        final diff = now.difference(createdAt);

        switch (_dateRangeFilter) {
          case PostAge.today:
            return diff.inDays < 1;
          case PostAge.thisWeek:
            return diff.inDays < 7;
          case PostAge.thisMonth:
            return diff.inDays < 30;
          case PostAge.all:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((post) {
        return (post['title'] ?? '').toLowerCase().contains(query) ||
            (post['description'] ?? '').toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  bool _hasActiveFilters() {
    return _categoryFilter != null ||
        _goalFilter != null ||
        _dateRangeFilter != PostAge.all;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialCategories: _categoryFilter != null ? [_categoryFilter!] : [],
        initialGoals: _goalFilter != null ? [_goalFilter!] : [],
        initialDateRange: _dateRangeFilter,
      ),
    );

    if (result != null) {
      setState(() {
        // Convert list results back to single value for client-side filtering
        final categories = List<String>.from(result['categories'] ?? []);
        final goals = List<String>.from(result['goals'] ?? []);
        _categoryFilter = categories.isNotEmpty ? categories.first : null;
        _goalFilter = goals.isNotEmpty ? goals.first : null;
        _dateRangeFilter = PostAge.fromValue(result['dateRange'] ?? 'all');
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _categoryFilter = null;
      _goalFilter = null;
      _dateRangeFilter = PostAge.all;
    });
  }

  String _getFilterSummary() {
    final parts = <String>[];
    if (_categoryFilter != null) {
      parts.add(_formatCategoryLabel(_categoryFilter!));
    }
    if (_goalFilter != null) {
      parts.add(_formatGoalLabel(_goalFilter!));
    }
    if (_dateRangeFilter != PostAge.all) {
      parts.add(_dateRangeFilter.label);
    }
    return parts.join(' + ');
  }

  String _formatCategoryLabel(String category) {
    switch (category) {
      case 'technology':
        return 'Technology';
      case 'healthcare':
        return 'Healthcare';
      case 'finance':
        return 'Finance';
      case 'education':
        return 'Education';
      case 'entertainment':
        return 'Entertainment';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  String _formatGoalLabel(String goal) {
    switch (goal) {
      case 'funding':
        return 'Funding';
      case 'team':
        return 'Team';
      case 'skills':
        return 'Skills';
      case 'partnership':
        return 'Partnership';
      case 'mentorship':
        return 'Mentorship';
      case 'feedback':
        return 'Feedback';
      case 'other':
        return 'Other Goals';
      default:
        return goal;
    }
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final user = post['user'] ?? {};
    final media = (post['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final mediaCount = media.length;

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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      case 'view':
                        _viewFullPost(post);
                        break;
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
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye, size: 16),
                          SizedBox(width: 8),
                          Text('View Full Post'),
                        ],
                      ),
                    ),
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

            // Image thumbnails
            if (media.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: media.length > 4
                      ? 4
                      : media.length, // Show max 4 thumbnails
                  itemBuilder: (context, index) {
                    final item = media[index];
                    final filePath = item['file_path'] as String?;

                    if (filePath == null) {
                      return _buildThumbnailPlaceholder(item);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildMediaThumbnail(item, filePath, media.length),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Post metadata
            Wrap(
              spacing: 16,
              children: [
                if (post['category'] != null)
                  Chip(
                    label: Text(post['category']),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                if (mediaCount > 0)
                  Chip(
                    label: Text('$mediaCount media'),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  ),
                if (post['funding_goal'] != null)
                  Chip(
                    label: Text('\$${post['funding_goal']}'),
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
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

  Widget _buildMediaThumbnail(
      Map<String, dynamic> item, String filePath, int totalCount) {
    final type = item['type'] as String?;
    final isVideo = type == 'video';

    // Use existing StorageUtils to build the URL (same as feed)
    final imageUrl = StorageUtils.getMediaUrl(
      path: filePath,
      bucket: AppEnv.startupbuilderBucket,
    );

    return GestureDetector(
      onTap: isVideo
          ? () => _showFullscreenVideo(imageUrl)
          : () => _showFullscreenImage(imageUrl),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isVideo
                ? Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
          ),
          if (isVideo)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullscreenImage(String imageUrl) {
    // Reuse the same fullscreen image viewer as the feed
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // InteractiveViewer allows pinch-to-zoom and pan
            InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 60, color: Colors.white54),
                      SizedBox(height: 16),
                      Text(
                        'Image could not be loaded',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenVideo(String videoUrl) {
    // Reuse the existing video player widget
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center the video player
            Center(
              child: VideoPlayerWidget(
                videoUrl: videoUrl,
                width: double.infinity,
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(Map<String, dynamic> item) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, size: 40),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

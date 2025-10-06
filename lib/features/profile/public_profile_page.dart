import 'package:flutter/material.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/features/post_creation/post_detail_page.dart';
import 'package:foundervers/models/post.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dm/new_dm_repos.dart';
import '../dm/thread_view.dart';

/// Public profile page for viewing other users' profiles
class PublicProfilePage extends StatelessWidget {
  final String userId;
  final String? userName; // Optional display name for better UX

  const PublicProfilePage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName ?? 'User Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          final userProfile = snapshot.data;
          if (userProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'User not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This user may no longer exist',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return _buildProfileContent(context, userProfile);
        },
      ),
    );
  }

  /// Fetch user profile data
  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    try {
      final userService = UserService();
      return await userService.getPublicProfile(userId);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Build the main profile content
  Widget _buildProfileContent(
      BuildContext context, Map<String, dynamic> userProfile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(context, userProfile),

          const SizedBox(height: 24),

          // User Posts Section
          _buildPostsSection(context, userProfile),
        ],
      ),
    );
  }

  /// Start a direct message conversation with this user
  Future<void> _startDirectMessage(BuildContext context) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    // Store context references before async operations
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final threadRepo = ThreadRepository();
      final conversationId =
          await threadRepo.ensure1to1(currentUser.id, userId);

      // Close loading dialog
      navigator.pop();

      // Create a ThreadSummary to navigate to the conversation
      final thread = ThreadSummary.fromData(
        conversationId: conversationId,
        viewerId: currentUser.id,
        unread: 0,
        participantIds: [currentUser.id, userId],
        lastMessagePreview: 'Start your conversation...',
      );

      // Navigate directly to the thread view
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ThreadView(thread: thread),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (navigator.canPop()) {
        navigator.pop();
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Error starting conversation: $e')),
      );
    }
  }

  /// Build profile header with user info
  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> userProfile) {
    final name = userProfile['name'] as String? ?? 'Unknown User';
    final bio = userProfile['bio'] as String?;
    final company = userProfile['company'] as String?;
    final location = userProfile['location'] as String?;
    final createdAt = userProfile['created_at'] as String?;
    final avatarUrl = userProfile['avatar_url'] as String?;

    DateTime? joinDate;
    if (createdAt != null) {
      try {
        joinDate = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing join date: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and basic info
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Name and join date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (joinDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${DateFormat('MMM yyyy').format(joinDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bio
          if (bio != null && bio.isNotEmpty) ...[
            Text(
              bio,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
          ],

          // Company and Location
          if (company != null || location != null) ...[
            Row(
              children: [
                if (company != null && company.isNotEmpty) ...[
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    company,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(width: 16),
                  ],
                ],
                if (location != null && location.isNotEmpty) ...[
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _startDirectMessage(context),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build posts section
  Widget _buildPostsSection(
      BuildContext context, Map<String, dynamic> userProfile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Posts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Posts list
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUserPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading posts',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.post_add_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostItem(context, post);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Fetch posts for this user
  Future<List<Map<String, dynamic>>> _fetchUserPosts() async {
    try {
      final postService = PostService();
      return await postService.fetchUserPosts(userId: userId);
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  /// Build individual post item
  Widget _buildPostItem(BuildContext context, Map<String, dynamic> postData) {
    final title = postData['title'] as String? ?? 'Untitled';
    final category = postData['category'] as String?;
    final createdAt = postData['created_at'] as String?;

    DateTime? postDate;
    if (createdAt != null) {
      try {
        postDate = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing post date: $e');
      }
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
          if (postDate != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(postDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to post detail
        try {
          final post = PostModel.fromJson(postData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailPage(post: post),
            ),
          );
        } catch (e) {
          debugPrint('Error converting post data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error loading post details')),
          );
        }
      },
    );
  }
}

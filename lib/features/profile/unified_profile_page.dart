import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/features/profile/edit_profile_page.dart';
import 'package:foundervers/features/premium/premium_payment_page.dart';
import 'package:foundervers/models/post.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dm/new_dm_repos.dart';
import '../dm/thread_view.dart';
import 'package:foundervers/services/bookmark_service.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';
import 'package:foundervers/services/user_blocking_service.dart';

/// Unified profile page - works for both own profile and others' profiles
/// Intelligently shows/hides features based on ownership
class UnifiedProfilePage extends StatefulWidget {
  final String? userId; // null = current user, provided = view that user
  final String? userName; // Optional display name for better UX

  const UnifiedProfilePage({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<UnifiedProfilePage> createState() => _UnifiedProfilePageState();
}

class _UnifiedProfilePageState extends State<UnifiedProfilePage>
    with SingleTickerProviderStateMixin {
  int _refreshKey = 0;
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isUserBlocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    if (_targetUserId != null && !_isOwnProfile) {
      final isBlocked = await UserBlockingService().isUserBlocked(_targetUserId!);
      if (mounted) {
        setState(() {
          _isUserBlocked = isBlocked;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get the actual user ID to display
  /// If widget.userId is null, use current user's ID
  String? get _targetUserId {
    return widget.userId ?? _supabase.auth.currentUser?.id;
  }

  /// Check if viewing own profile
  bool get _isOwnProfile {
    final currentUserId = _supabase.auth.currentUser?.id;
    final targetId = _targetUserId;
    return currentUserId != null &&
        targetId != null &&
        currentUserId == targetId;
  }

  @override
  Widget build(BuildContext context) {
    if (_targetUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isOwnProfile ? 'My Profile' : (widget.userName ?? 'User Profile')),
        centerTitle: true,
        actions: [
          if (!_isOwnProfile)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block') {
                  await _confirmBlockUser(context);
                } else if (value == 'unblock') {
                  await _confirmUnblockUser(context);
                }
              },
              itemBuilder: (BuildContext context) {
                if (_isUserBlocked) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'unblock',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Unblock User'),
                        ],
                      ),
                    ),
                  ];
                }
                return [
                  const PopupMenuItem<String>(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Block User', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        key: ValueKey(_refreshKey),
        future: _fetchProfile(),
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

          final profile = snapshot.data;
          if (profile == null) {
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
                ],
              ),
            );
          }

          return _buildProfileContent(context, profile);
        },
      ),
    );
  }



  Future<void> _confirmBlockUser(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User?'),
        content: const Text(
            'They will not be able to message you or see your posts. You will not see their posts in your feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await UserBlockingService().blockUser(_targetUserId!);
        if (mounted) {
          setState(() {
            _isUserBlocked = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User blocked successfully')),
          );
          Navigator.pop(context); // Go back to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error blocking user: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmUnblockUser(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User?'),
        content: const Text(
            'They will be able to see your posts and message you again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await UserBlockingService().unblockUser(_targetUserId!);
        if (mounted) {
          setState(() {
            _isUserBlocked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unblocked successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error unblocking user: $e')),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    try {
      final userService = UserService();

      if (_isOwnProfile) {
        // For own profile, get full details including sensitive data
        return await userService.getById(_targetUserId!);
      } else {
        // For others, get public profile only (no email, etc.)
        return await userService.getPublicProfile(_targetUserId!);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Widget _buildProfileContent(
      BuildContext context, Map<String, dynamic> profile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(context, profile),
          const SizedBox(height: 8),
          // User Posts Section
          _buildPostsSection(context, profile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> profile) {
    final name =
        profile['name'] as String? ?? profile['full_name'] as String? ?? 'User';
    final username = profile['username'] as String?;
    final bio = profile['bio'] as String?;
    final company = profile['company'] as String?;
    final location = profile['location'] as String?;
    final createdAt = profile['created_at'] as String?;
    final avatarUrl = StorageUtils.resolvePublicUrl(
      profile['avatar_url'] as String?,
    );
    final emailVerified = profile['email_verified'] as bool? ?? false;
    final isPremium = profile['is_premium'] as bool? ?? false;
    final premiumExpiresAt = profile['premium_expires_at'] as String?;
    final email = _isOwnProfile
        ? (profile['email'] as String?)
        : null; // Only show email to self

    // Check if premium is still active
    bool hasActivePremium = isPremium;
    if (isPremium && premiumExpiresAt != null) {
      try {
        final expiryDate = DateTime.parse(premiumExpiresAt);
        hasActivePremium = expiryDate.isAfter(DateTime.now());
      } catch (e) {
        hasActivePremium = false;
      }
    }

    DateTime? joinDate;
    if (createdAt != null) {
      try {
        joinDate = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing join date: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                    : null,
              ),
              const SizedBox(width: 12),

              // Name and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name with verified badge (single row)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasActivePremium)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.workspace_premium,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                          )
                        else if (emailVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                      ],
                    ),

                    // Username
                    if (username != null && username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Email (only shown to self)
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Join date
                    if (joinDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Member since ${DateFormat('MMM yyyy').format(joinDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bio
          if (bio != null && bio.isNotEmpty) ...[
            Text(
              bio,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Company and Location
          if (company != null || location != null) ...[
            Row(
              children: [
                if (company != null && company.isNotEmpty) ...[
                  Icon(Icons.business, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      company,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(width: 12),
                  ],
                ],
                if (location != null && location.isNotEmpty) ...[
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Action button - different based on ownership
          SizedBox(
            width: double.infinity,
            child: _isOwnProfile
                ? ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                      if (result == true && mounted) {
                        setState(() => _refreshKey++);
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile',
                        style: TextStyle(fontSize: 14)),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _startDirectMessage(context),
                    icon: const Icon(Icons.message_outlined, size: 18),
                    label:
                        const Text('Message', style: TextStyle(fontSize: 14)),
                  ),
          ),

          // Expired premium banner (only for own profile)
          if (_isOwnProfile && isPremium && !hasActivePremium) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your premium subscription has expired',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (!Platform.isIOS)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PremiumPaymentPage(isAnnual: false),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          const Text('Renew', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Start a direct message conversation with this user
  Future<void> _startDirectMessage(BuildContext context) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    if (_targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final threadRepo = ThreadRepository();
      final conversationId =
          await threadRepo.ensure1to1(currentUser.id, _targetUserId!);

      navigator.pop(); // Close loading

      final thread = ThreadSummary.fromData(
        conversationId: conversationId,
        viewerId: currentUser.id,
        unread: 0,
        participantIds: [currentUser.id, _targetUserId!],
        lastMessagePreview: 'Start your conversation...',
      );

      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ThreadView(thread: thread),
        ),
      );
    } catch (e) {
      if (navigator.canPop()) {
        navigator.pop();
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Error starting conversation: $e')),
      );
    }
  }

  Widget _buildPostsSection(
      BuildContext context, Map<String, dynamic> profile) {
    // If viewing others' profile, show simple list
    if (!_isOwnProfile) {
      return _buildSimplePostsList(context);
    }

    // If viewing own profile, show tabs with My Posts and Saved
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'My Posts'),
              Tab(text: 'Saved'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 600, // Fixed height for TabBarView
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyPostsList(context),
                _buildSavedPostsList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple posts list for other users' profiles
  Widget _buildSimplePostsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Posts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<PostModel>>(
            future: _fetchUserPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Error loading posts',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
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

              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return EnhancedPostCard(
                    key: ValueKey('user_post_${post.id}'),
                    post: post,
                    meUid: _supabase.auth.currentUser?.id,
                    subtitle: _buildPostSubtitle(post),
                    goalLabel: _buildPostGoalLabel(post),
                    onEdited: () => setState(() => _refreshKey++),
                    onDeleted: () => setState(() => _refreshKey++),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // My Posts tab content
  Widget _buildMyPostsList(BuildContext context) {
    return FutureBuilder<List<PostModel>>(
      future: _fetchUserPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Error loading posts',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet. Create your first post!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return EnhancedPostCard(
              key: ValueKey('my_post_${post.id}'),
              post: post,
              meUid: _supabase.auth.currentUser?.id,
              subtitle: _buildPostSubtitle(post),
              goalLabel: _buildPostGoalLabel(post),
              onEdited: () => setState(() => _refreshKey++),
              onDeleted: () => setState(() => _refreshKey++),
            );
          },
        );
      },
    );
  }

  // Saved Posts tab content
  Widget _buildSavedPostsList(BuildContext context) {
    return FutureBuilder<List<PostModel>>(
      future: BookmarkService.instance.getBookmarkedPosts(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Error loading saved posts',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No saved posts yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark posts to save them here',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            // Use EnhancedPostCard to show full post with media
            return EnhancedPostCard(
              key: ValueKey('saved_post_${post.id}'),
              post: post,
              meUid: _supabase.auth.currentUser?.id,
              subtitle: _buildPostSubtitle(post),
              goalLabel: _buildPostGoalLabel(post),
              onEdited: () => setState(() => _refreshKey++),
              onDeleted: () => setState(() => _refreshKey++),
            );
          },
        );
      },
    );
  }

  Future<List<PostModel>> _fetchUserPosts() async {
    try {
      final postService = PostService();
      return await postService.fetchUserPosts(userId: _targetUserId!);
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  // Helper methods for EnhancedPostCard
  String _buildPostSubtitle(PostModel post) {
    final parts = <String>[];
    if (post.category != null && post.category!.isNotEmpty) {
      parts.add(post.category!);
    }
    if (post.status != null && post.status!.isNotEmpty) {
      parts.add(post.status!);
    }
    return parts.join(' • ');
  }

  String? _buildPostGoalLabel(PostModel post) {
    if (post.postGoal != null && post.postGoal!.isNotEmpty) {
      return 'Goal: ${post.postGoal}';
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/features/auth/user_service.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/features/profile/edit_profile_page.dart';
import 'package:foundervers/models/post.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dm/new_dm_repos.dart';
import '../dm/thread_view.dart';
import 'package:foundervers/services/bookmark_service.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';
import 'package:foundervers/services/user_blocking_service.dart';
import 'package:foundervers/services/moderation_service.dart';

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
      final isBlocked =
          await UserBlockingService().isUserBlocked(_targetUserId!);
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
                  await _confirmBlockUser();
                } else if (value == 'unblock') {
                  await _confirmUnblockUser();
                } else if (value == 'report') {
                  await _showReportUserDialog();
                }
              },
              itemBuilder: (BuildContext context) {
                if (_isUserBlocked) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'unblock',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 20),
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
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Report User'),
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

  Future<void> _confirmBlockUser() async {
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

  Future<void> _confirmUnblockUser() async {
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

  Future<void> _showReportUserDialog() async {
    final reasonController = TextEditingController();
    String selectedReason = 'Spam';
    final reasons = [
      'Spam',
      'Abusive Behavior',
      'Fake Account',
      'Inappropriate Content',
      'Scam / Fraud',
      'Other'
    ];

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this user?'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedReason = v);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Please provide more context...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      try {
        // Import ModerationService if not already imported, or use fully qualified name if needed.
        // Assuming ModerationService is available via import or singleton.
        // Based on previous files, it's in 'package:foundervers/services/moderation_service.dart'
        // We need to ensure it's imported at the top of the file.
        // For now, I'll use the class directly assuming import exists or I'll add it.
        // Wait, I need to check imports.
        // I'll assume I need to add the import if it's missing, but let's check imports first.
        // Actually, I can just use ModerationService() constructor.

        await ModerationService().reportUser(
          reportedUserId: _targetUserId!,
          reason: selectedReason,
          description: reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Report submitted. Thank you for helping keep our community safe.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting report: $e')),
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
    // Use NestedScrollView to enable scrolling between header and content
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: _buildProfileHeader(context, profile),
          ),
        ];
      },
      body: _buildPostsSection(context, profile),
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
    final email = _isOwnProfile
        ? (profile['email'] as String?)
        : null; // Only show email to self

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
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
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
                        if (emailVerified)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TabBar pinned at top
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
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
          ),
        ),
        const SizedBox(height: 8),
        // TabBarView content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyPostsList(context),
              _buildSavedPostsList(context),
            ],
          ),
        ),
      ],
    );
  }

  // Simple posts list for other users' profiles
  Widget _buildSimplePostsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
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
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<PostModel>>(
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final postCard = EnhancedPostCard(
                    key: ValueKey('user_post_${post.id}'),
                    post: post,
                    meUid: _supabase.auth.currentUser?.id,
                    subtitle: _buildPostSubtitle(post),
                    goalLabel: _buildPostGoalLabel(post),
                    onEdited: () => setState(() => _refreshKey++),
                    onDeleted: () => setState(() => _refreshKey++),
                  );
                  final isLargeScreen = MediaQuery.of(context).size.width > 600;
                  return isLargeScreen
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: postCard,
                          ),
                        )
                      : postCard;
                },
              );
            },
          ),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postCard = EnhancedPostCard(
              key: ValueKey('my_post_${post.id}'),
              post: post,
              meUid: _supabase.auth.currentUser?.id,
              subtitle: _buildPostSubtitle(post),
              goalLabel: _buildPostGoalLabel(post),
              onEdited: () => setState(() => _refreshKey++),
              onDeleted: () => setState(() => _refreshKey++),
            );
            final isLargeScreen = MediaQuery.of(context).size.width > 600;
            return isLargeScreen
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: postCard,
                    ),
                  )
                : postCard;
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            // Use EnhancedPostCard to show full post with media
            final postCard = EnhancedPostCard(
              key: ValueKey('saved_post_${post.id}'),
              post: post,
              meUid: _supabase.auth.currentUser?.id,
              subtitle: _buildPostSubtitle(post),
              goalLabel: _buildPostGoalLabel(post),
              onEdited: () => setState(() => _refreshKey++),
              onDeleted: () {
                setState(() => _refreshKey++);
              },
            );
            final isLargeScreen = MediaQuery.of(context).size.width > 600;
            return isLargeScreen
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: postCard,
                    ),
                  )
                : postCard;
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

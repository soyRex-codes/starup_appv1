import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/features/post_creation/post_creation_page.dart';
import 'package:foundervers/services/share_service.dart';
import 'package:foundervers/features/feed/single_post_feed_page.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/features/profile/unified_profile_page.dart';
import 'package:foundervers/features/feed/feed_service.dart';
import 'package:foundervers/features/dm/new_dm_repos.dart';
import 'package:foundervers/features/suggestions/suggestion_form.dart';
import 'package:foundervers/features/messaging/message_compose_sheet.dart';
import 'package:foundervers/widgets/video_player_widget.dart';
import 'package:foundervers/widgets/comments/comment_sheet.dart';
import 'package:foundervers/services/comment_service.dart';
import 'package:foundervers/core/utils/time_formatter.dart';
import 'package:foundervers/services/bookmark_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foundervers/widgets/report_post_dialog.dart';
import 'package:foundervers/services/view_analytics_service.dart';
import 'package:foundervers/services/post_counts_manager.dart';
import 'package:foundervers/services/post_like_service.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhancedPostCard extends StatefulWidget {
  const EnhancedPostCard({
    required this.post,
    required this.meUid,
    required this.subtitle,
    required this.goalLabel,
    required this.onEdited,
    required this.onDeleted,
    this.isDetailView = false,
    super.key,
  });

  final PostModel post;
  final String? meUid;
  final String subtitle;
  final String? goalLabel;
  final VoidCallback onEdited;
  final VoidCallback onDeleted;
  final bool isDetailView;

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard> {
  bool _isDescriptionExpanded = false;
  bool _isBookmarked = false;
  bool _isTogglingBookmark = false;
  late bool _isLiked;
  late int _likeCount;
  bool _isTogglingLike = false;
  final ThreadRepository _threadRepo = ThreadRepository();
  final MessageRepository _msgRepo = MessageRepository();
  final _me = Supabase.instance.client.auth.currentUser;
  final CommentService _commentService = CommentService();
  final GlobalKey _menuKey = GlobalKey();

  // View tracking state
  bool _hasViewBeenCounted = false;
  Timer? _viewTimer;

  // NEW: Replace local state with managed counts
  StreamSubscription<PostCounts>? _countsSubscription;
  PostCounts? _counts;

  @override
  void initState() {
    super.initState();

    _isLiked = widget.post.likedByMe;
    _likeCount = widget.post.likeCount;

    // Initialize counts from PostCountsManager OR use widget.post as fallback
    // This prevents showing 0 before manager is populated
    final managedCounts = PostCountsManager.instance.getCounts(widget.post.id);

    // If manager has no data yet, initialize it with widget.post values
    if (managedCounts.views == 0 && managedCounts.comments == 0) {
      // Seed the manager with current post data
      PostCountsManager.instance.updateCounts(
        widget.post.id,
        views: widget.post.views,
        comments: widget.post.commentCount,
      );
      _counts = PostCounts(
        views: widget.post.views,
        comments: widget.post.commentCount,
      );
    } else {
      _counts = managedCounts;
    }

    // Subscribe to count updates
    _countsSubscription =
        PostCountsManager.instance.watchCounts(widget.post.id).listen((counts) {
      if (mounted) {
        setState(() => _counts = counts);
      }
    });

    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _countsSubscription?.cancel();
    _viewTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _isLiked = widget.post.likedByMe;
      _likeCount = widget.post.likeCount;
      // Post changed, resubscribe to new post's counts
      _countsSubscription?.cancel();
      _counts = PostCountsManager.instance.getCounts(widget.post.id);
      _countsSubscription = PostCountsManager.instance
          .watchCounts(widget.post.id)
          .listen((counts) {
        if (mounted) {
          setState(() => _counts = counts);
        }
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    if (_me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like posts.')),
      );
      return;
    }

    final previousLiked = _isLiked;
    final previousCount = _likeCount;
    final nextLiked = !previousLiked;
    setState(() {
      _isTogglingLike = true;
      _isLiked = nextLiked;
      _likeCount = nextLiked
          ? previousCount + 1
          : (previousCount > 0 ? previousCount - 1 : 0);
    });

    try {
      await PostLikeService.instance.setLiked(
        postId: widget.post.id,
        liked: nextLiked,
      );
      if (mounted) setState(() => _isTogglingLike = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTogglingLike = false;
        _isLiked = previousLiked;
        _likeCount = previousCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Likes are not available yet. Please try again soon.'),
        ),
      );
    }
  }

  Future<void> _sharePost() async {
    try {
      await ShareService.sharePost(
        postId: widget.post.id,
        title: widget.post.title,
        description: widget.post.description,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share this post.')),
      );
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked =
        await BookmarkService.instance.isBookmarked(widget.post.id);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;

    setState(() {
      _isTogglingBookmark = true;
    });

    final newStatus =
        await BookmarkService.instance.toggleBookmark(widget.post.id);

    if (mounted) {
      setState(() {
        _isBookmarked = newStatus;
        _isTogglingBookmark = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Post saved' : 'Post removed from saved'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // View tracking logic
  void _handleVisibilityChanged(VisibilityInfo info) {
    // 1-Second Rule: Post must be 50% visible for 1 continuous second
    if (info.visibleFraction >= 0.5) {
      if (!_hasViewBeenCounted && _viewTimer == null) {
        // Start timer
        _viewTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _recordView();
          }
        });
      }
    } else {
      // If scrolled away before 1s, cancel timer
      _viewTimer?.cancel();
      _viewTimer = null;
    }
  }

  Future<void> _recordView() async {
    _hasViewBeenCounted = true;
    final counted =
        await ViewAnalyticsService().trackView(widget.post.id.toString());
    if (counted && mounted) {
      // Trigger rebuild to show updated count (Optimistic UI)
      setState(() {});
    }
  }

  // Truncate description to approximately 35-40 words (about 3-4 lines)
  String get _truncatedDescription {
    if (widget.isDetailView) return (widget.post.description ?? '').trim();

    final description = (widget.post.description ?? '').trim();
    if (description.isEmpty) return '';

    final words = description.split(' ');
    if (words.length <= 30) return description;

    return '${words.take(30).join(' ')}...';
  }

  bool get _shouldShowSeeMore {
    if (widget.isDetailView) return false;
    final description = (widget.post.description ?? '').trim();
    return description.split(' ').length > 30;
  }

  Future<void> _handleActionButton(String actionType) async {
    // Ensure any existing text inputs lose focus before opening a sheet
    FocusManager.instance.primaryFocus?.unfocus();

    if (_me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to take action')),
      );
      return;
    }

    if (_me.id == widget.post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself!")),
      );
      return;
    }

    // For invest and collab, open the reusable message compose form
    if (actionType.toLowerCase() == 'invest' ||
        actionType.toLowerCase() == 'collab') {
      await MessageComposeBottomSheet.show(
        context: context,
        post: widget.post,
        type: actionType.toLowerCase(),
      );
      return;
    }

    // For suggest, open the suggestion form
    if (actionType.toLowerCase() == 'suggest') {
      await _openSuggestionForm();
      return;
    }

    // For contact or other actions, keep the direct message flow
    try {
      final threadId = await _threadRepo.ensure1to1(_me.id, widget.post.userId);

      String messageContent;
      switch (actionType.toLowerCase()) {
        case 'contact':
          messageContent =
              'GENERAL INQUIRY\n\nHi! I saw your post about "${widget.post.title}" and would like to connect. Let\'s chat!';
          break;
        default:
          messageContent =
              'I\'m interested in your post about "${widget.post.title}". Let\'s connect!';
      }

      await _msgRepo.send(
        threadId: threadId,
        senderId: _me.id,
        body: messageContent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${actionType[0].toUpperCase()}${actionType.substring(1)} message sent! Check your inbox.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete action: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSuggestionForm() async {
    if (_me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a suggestion')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  offset: Offset(0, -4),
                  color: Color(0x1F000000),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SuggestionForm(
                postId: widget.post.id,
                postTitle: widget.post.title,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.post.media.isNotEmpty;

    return VisibilityDetector(
      key: Key('post_${widget.post.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: _PressScale(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Multi-Image Carousel Section
                if (hasImage)
                  _MediaCarousel(
                    key: ValueKey('carousel_${widget.post.id}'),
                    post: widget.post,
                    onTap: () async {
                      if (widget.isDetailView) return; // No-op in detail view
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) =>
                                SinglePostFeedPage(post: widget.post)),
                      );
                      if (changed == true) widget.onEdited();
                    },
                  )
                else
                  GestureDetector(
                    onTap: () async {
                      if (widget.isDetailView) return; // No-op in detail view
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) =>
                                SinglePostFeedPage(post: widget.post)),
                      );
                      if (changed == true) widget.onEdited();
                    },
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF6B2C).withValues(alpha: 0.1),
                            const Color(0xFFFF6B2C).withValues(alpha: 0.05),
                          ],
                        )),
                        child: Center(
                          child: Icon(Icons.lightbulb_outline,
                              size: 56,
                              color: const Color(0xFFFF6B2C)
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),

                // Content Section - Full width optimization
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Moderation banner (only if not approved and viewer is author/admin)
                        Builder(builder: (context) {
                          final mod =
                              widget.post.moderationStatus ?? 'approved';
                          final currentUser =
                              Supabase.instance.client.auth.currentUser;
                          final isAuthor =
                              currentUser?.id == widget.post.userId;
                          // Lightweight admin detection using AppEnv.adminEmails if available (safe fallback)
                          bool isAdmin = false;
                          try {
                            // ignore: avoid_dynamic_calls
                            isAdmin = (AppEnv.adminEmails)
                                .map((e) => e.toLowerCase())
                                .contains(currentUser?.email?.toLowerCase());
                          } catch (_) {}
                          if (mod == 'approved' || (!isAuthor && !isAdmin)) {
                            return const SizedBox.shrink();
                          }
                          Color bg;
                          Color fg;
                          IconData icon;
                          String label;
                          if (mod == 'pending') {
                            bg = const Color(0xFFFFF4E5);
                            fg = const Color(0xFF8A5800);
                            icon = Icons.hourglass_top_rounded;
                            label =
                                'This post is under review and only visible to you.';
                          } else if (mod == 'blocked') {
                            bg = const Color(0xFFFFE9E9);
                            fg = const Color(0xFF8A1A1A);
                            icon = Icons.block_rounded;
                            label =
                                'Blocked: Only you can see this. Edit or delete to resubmit.';
                          } else {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, size: 18, color: fg),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.25,
                                        color: fg,
                                        fontWeight: FontWeight.w500,
                                      )),
                                ),
                                if (mod == 'blocked')
                                  TextButton(
                                    onPressed: () async {
                                      // Quick edit shortcut
                                      final saved = await Navigator.of(context)
                                          .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => PostCreationPage(
                                              existing: widget.post),
                                        ),
                                      );
                                      if (saved == true) widget.onEdited();
                                    },
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8)),
                                    child: Text('Edit',
                                        style: TextStyle(
                                            color: fg,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ),
                              ],
                            ),
                          );
                        }),
                        // Header Row
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _AvatarCircle(
                                url: widget.post.author?.avatarUrl,
                                name: widget.post.author?.displayName,
                                userId: widget.post.author?.userId,
                                onTap: () {
                                  // Allow viewing anyone's profile, including your own
                                  if (widget.post.author?.userId != null &&
                                      widget.post.author!.userId.isNotEmpty) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UnifiedProfilePage(
                                          userId: widget.post.author!.userId,
                                          userName:
                                              widget.post.author?.displayName,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // User's full name as primary text (bold) - LinkedIn style with verification badge
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.post.author?.displayName ??
                                                'Unknown User',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Blue badge for verified users.
                                        if (widget.post.author?.emailVerified ==
                                            true)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.verified,
                                              size: 18,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Time posted - accurate from database
                                    if (widget.post.createdAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          TimeFormatter.formatTimeAgo(
                                              widget.post.createdAt!),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    // Removed username line for cleaner, more professional look
                                  ],
                                ),
                              ),
                              // Menu with Share + Edit/Delete options
                              // Menu with Share + Edit/Delete options
                              PopupMenuButton<String>(
                                key: _menuKey,
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) async {
                                  if (value == 'share') {
                                    final messenger =
                                        ScaffoldMessenger.of(context);

                                    // Get the position of the menu button for iOS share sheet positioning
                                    // Use the specific menu button key for accurate positioning
                                    Rect? sharePositionOrigin;

                                    try {
                                      final RenderBox? box = _menuKey
                                          .currentContext
                                          ?.findRenderObject() as RenderBox?;

                                      if (box != null && box.hasSize) {
                                        final offset =
                                            box.localToGlobal(Offset.zero);
                                        final size = box.size;
                                        sharePositionOrigin = offset & size;
                                      }

                                      await ShareService.sharePost(
                                        postId: widget.post.id,
                                        title: widget.post.title,
                                        description: widget.post.description,
                                        sharePositionOrigin:
                                            sharePositionOrigin,
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content: Text('Share failed: $e')),
                                      );
                                    }
                                  } else if (value == 'edit') {
                                    // Navigate to edit page
                                    final changed =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => PostCreationPage(
                                            existing: widget.post),
                                      ),
                                    );

                                    if (changed == true) {
                                      widget.onEdited();
                                    }
                                  } else if (value == 'delete') {
                                    // Confirm deletion
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Post?'),
                                        content: const Text(
                                            'Are you sure you want to delete this post? This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && context.mounted) {
                                      try {
                                        await FeedService()
                                            .deletePost(id: widget.post.id);
                                        widget.onDeleted();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Post deleted successfully')));
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Delete failed: $e')));
                                        }
                                      }
                                    }
                                  } else if (value == 'report') {
                                    if (context.mounted) {
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (context) => ReportPostDialog(
                                          postId: widget.post.id.toString(),
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          Icon(Icons.share_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Share'),
                                        ],
                                      )),
                                  // Show edit/delete only for own posts
                                  if (widget.meUid == widget.post.userId) ...[
                                    const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        )),
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        )),
                                  ],
                                  // Show report option for posts that aren't yours
                                  if (widget.meUid != widget.post.userId)
                                    const PopupMenuItem(
                                        value: 'report',
                                        child: Row(
                                          children: [
                                            Icon(Icons.flag_outlined,
                                                size: 18, color: Colors.orange),
                                            SizedBox(width: 8),
                                            Text('Report',
                                                style: TextStyle(
                                                    color: Colors.orange)),
                                          ],
                                        )),
                                ],
                              ),
                            ]),

                        // Post Title Section - Tighter spacing for better hierarchy
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            if (widget.isDetailView) {
                              return; // No-op in detail view
                            }
                            final changed =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SinglePostFeedPage(post: widget.post)),
                            );
                            if (changed == true) widget.onEdited();
                          },
                          child: RichText(
                            text: TextSpan(
                              children: [
                                // "Startup:" label with subtle styling
                                TextSpan(
                                  text: 'Startup: ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                // Startup with enhanced styling
                                TextSpan(
                                  text: widget.post.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(
                                        0xFFFF8C5A), // Keep orange for branding
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Combined Tags and Goals Row - keep chips on a single line and allow horizontal scroll on overflow
                        if (widget.subtitle.isNotEmpty ||
                            widget.goalLabel != null) ...[
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                if (widget.subtitle.isNotEmpty) ...[
                                  _CompactChip(
                                    text: widget.subtitle,
                                    color: const Color(0xFFF8FAFC), // Slate-50
                                    borderColor: Colors.white, // Slate-300
                                    textColor:
                                        const Color(0xFF475569), // Slate-600
                                  ),
                                  const SizedBox(width: 0),
                                ],
                                if (widget.goalLabel != null) ...[
                                  _CompactChip(
                                    text: widget.goalLabel!,
                                    color: const Color(
                                        0xFFF8FAFC), // Light blue-50
                                    borderColor: Colors.white, // Blue-200
                                    textColor:
                                        const Color(0xFF16A34A), // Blue-700
                                  ),
                                  const SizedBox(width: 0),
                                ],
                                if (widget.post.fundingGoal != null) ...[
                                  _CompactChip(
                                    text: 'Goal: \$${widget.post.fundingGoal}',
                                    color:
                                        const Color(0xFFF8FAFC), // Emerald-50
                                    borderColor: Colors.white, // Black border
                                    textColor:
                                        const Color(0xFFA16207), // Emerald-700
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 6),

                        // Expandable Description with Clickable Links
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Linkify(
                              text: _isDescriptionExpanded
                                  ? (widget.post.description ?? '').trim()
                                  : _truncatedDescription,
                              onOpen: (link) async {
                                final uri = Uri.parse(link.url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                              linkStyle: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: const Color(0xFFFF6B2C),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFFFF6B2C),
                              ),
                            ),
                            if (_shouldShowSeeMore ||
                                ((_counts?.views ?? widget.post.views) > 0 ||
                                    ViewAnalyticsService().getPendingViewCount(
                                            widget.post.id.toString()) >
                                        0)) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (_shouldShowSeeMore)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isDescriptionExpanded =
                                              !_isDescriptionExpanded;
                                        });
                                      },
                                      child: Text(
                                        _isDescriptionExpanded
                                            ? 'See less'
                                            : 'See more',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(
                                                  0xFFFF8C5A) // Orange for dark mode
                                              : const Color(
                                                  0xFFFF6B35), // Orange accent for light mode
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // View Counter - use managed counts + pending
                                  if ((_counts?.views ?? widget.post.views) >
                                          0 ||
                                      ViewAnalyticsService()
                                              .getPendingViewCount(
                                                  widget.post.id.toString()) >
                                          0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_outlined,
                                              size: 12,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(_counts?.views ?? widget.post.views) + ViewAnalyticsService().getPendingViewCount(widget.post.id.toString())}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),
                        Divider(color: Theme.of(context).dividerColor),
                        const SizedBox(height: 4),
                        Row(children: [
                          _PostAction(
                            icon: _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: _likeCount > 0 ? '$_likeCount' : 'Like',
                            color: _isLiked ? const Color(0xFFE5484D) : null,
                            busy: _isTogglingLike,
                            onTap: _toggleLike,
                          ),
                          _PostAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: (_counts?.comments ??
                                        widget.post.commentCount) >
                                    0
                                ? '${_counts?.comments ?? widget.post.commentCount}'
                                : 'Comment',
                            onTap: _openComments,
                          ),
                          _PostAction(
                            icon: Icons.send_outlined,
                            label: 'Share',
                            onTap: _sharePost,
                          ),
                          const Spacer(),
                          _PostAction(
                            icon: _isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            tooltip: _isBookmarked ? 'Saved' : 'Save',
                            busy: _isTogglingBookmark,
                            onTap: _toggleBookmark,
                          ),
                        ]),
                        if (widget.meUid != widget.post.userId) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleActionButton('collab'),
                                icon: const Icon(Icons.handshake_outlined,
                                    size: 18),
                                label: const Text('Collaborate'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () => _handleActionButton('suggest'),
                              child: const Text('Send suggestion'),
                            ),
                          ]),
                        ],
                      ]),
                ),
              ]),
        ),
      ),
    );
  }

  Future<void> _openComments() async {
    final initialCount = _counts?.comments ?? widget.post.commentCount;
    int? latestFromSheet;
    await CommentSheet.show(
      context,
      widget.post,
      onCountChanged: (count) {
        latestFromSheet = count;
        // Update manager instead of local state
        PostCountsManager.instance.updateCommentCount(widget.post.id, count);
      },
    );

    if (latestFromSheet == null) {
      try {
        final latestCount =
            await _commentService.getCommentCount(widget.post.id);
        // Update manager with latest from API
        PostCountsManager.instance
            .updateCommentCount(widget.post.id, latestCount);
        latestFromSheet = latestCount;
      } catch (_) {
        // Ignore failures silently; existing count will remain until next refresh.
      }
    }

    // If comment count changed, notify parent to refresh the post
    if (latestFromSheet != null && latestFromSheet != initialCount) {
      widget.onEdited(); // Triggers parent to reload posts with updated counts
    }
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
    this.color,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final String? tooltip;
  final Color? color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).textTheme.bodySmall?.color;
    return Tooltip(
      message: tooltip ?? label ?? '',
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (busy)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            else
              Icon(icon, size: 22, color: foreground),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// Supporting widgets - card press animation

class _PressScale extends StatefulWidget {
  final Widget child;
  const _PressScale({required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PostImageThumb extends StatefulWidget {
  final String? mediaPath;
  final String bucket;
  final String heroTag;
  final String? mediaType;
  const _PostImageThumb(
      {super.key,
      required this.mediaPath,
      required this.bucket,
      required this.heroTag,
      this.mediaType});

  @override
  State<_PostImageThumb> createState() => _PostImageThumbState();
}

class _PostImageThumbState extends State<_PostImageThumb> {
  String? _url;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void didUpdateWidget(_PostImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if mediaPath changed - if so, reload the URL
    if (oldWidget.mediaPath != widget.mediaPath) {
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    if (widget.mediaPath == null) {
      if (mounted) {
        setState(() {
          _url = null;
          _loading = false;
          _error = 'No media path';
        });
      }
      return;
    }

    final currentMediaPath = widget.mediaPath!;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final url = StorageUtils.getMediaUrl(
        path: currentMediaPath,
        bucket: widget.bucket,
      );

      // Only update state if the widget still has the same mediaPath
      // This prevents race conditions where async loading finishes for old media
      if (mounted && widget.mediaPath == currentMediaPath) {
        setState(() {
          _url = url;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && widget.mediaPath == currentMediaPath) {
        setState(() {
          _error = 'Failed to load image: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          width: double.infinity,
          color: Colors.grey[100],
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _url == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          width: double.infinity,
          color: Colors.grey[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('Media unavailable',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // Check if this is a video
    if (widget.mediaType == 'video') {
      return Hero(
        tag: widget.heroTag,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: VideoPlayerWidget(
              videoUrl: _url!,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ),
      );
    }

    // Default to image with better aspect ratio handling and tap-to-expand
    return GestureDetector(
      onTap: () {
        // Show full-screen image view (Instagram-like)
        showDialog(
          context: context,
          barrierColor: Colors.black87,
          builder: (context) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Image.network(
                    _url!,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Hero(
        tag: widget.heroTag,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: Image.network(
              _url!,
              width: double.infinity,
              fit: BoxFit.contain, // Shrinks image to fit without cropping
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Image unavailable',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.url,
    required this.name,
    required this.userId,
    required this.onTap,
  });

  final String? url;
  final String? name;
  final String? userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        backgroundImage: url != null
            ? CachedNetworkImageProvider(
                StorageUtils.resolvePublicUrl(
                      url!,
                    ) ??
                    '',
              )
            : null,
        child: url == null
            ? Text(
                (name ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({
    required this.text,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Multi-image carousel widget for posts with swipe navigation
class _MediaCarousel extends StatefulWidget {
  const _MediaCarousel({
    required this.post,
    required this.onTap,
    super.key,
  });

  final PostModel post;
  final VoidCallback onTap;

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.post.media;
    if (media.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: media.length,
            itemBuilder: (context, index) {
              final mediaItem = media[index];
              return _PostImageThumb(
                key: ValueKey(
                    '${widget.post.id}_${mediaItem.filePath ?? mediaItem.filename}_$index'),
                mediaPath: mediaItem.filePath ?? mediaItem.filename,
                bucket: AppEnv.startupbuilderBucket,
                heroTag:
                    'pimg_${widget.post.id}_${mediaItem.id ?? mediaItem.filename?.hashCode ?? 0}_$index',
                mediaType: mediaItem.type,
              );
            },
          ),
        ),

        // Page indicator (only show if multiple images)
        if (media.length > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1}/${media.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Navigation arrows (only show if multiple images)
        if (media.length > 1) ...[
          // Left arrow
          if (_currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Right arrow
          if (_currentIndex < media.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

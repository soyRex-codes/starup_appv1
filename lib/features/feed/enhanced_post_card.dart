import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/features/post_creation/post_creation_page.dart';
import 'package:foundervers/services/share_service.dart';
import 'package:foundervers/features/post_creation/post_detail_page.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/features/profile/public_profile_page.dart';
import 'package:foundervers/features/feed/feed_service.dart';
import 'package:foundervers/features/dm/new_dm_repos.dart';
import 'package:foundervers/features/suggestions/suggestion_form.dart';
import 'package:foundervers/features/messaging/message_compose_sheet.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/widgets/video_player_widget.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/widgets/comments/comment_sheet.dart';
import 'package:foundervers/services/comment_service.dart';

class EnhancedPostCard extends StatefulWidget {
  const EnhancedPostCard({
    required this.post,
    required this.meUid,
    required this.subtitle,
    required this.goalLabel,
    required this.onEdited,
    required this.onDeleted,
    super.key,
  });

  final PostModel post;
  final String? meUid;
  final String subtitle;
  final String? goalLabel;
  final VoidCallback onEdited;
  final VoidCallback onDeleted;

  @override
  State<EnhancedPostCard> createState() => _EnhancedPostCardState();
}

class _EnhancedPostCardState extends State<EnhancedPostCard> {
  bool _isDescriptionExpanded = false;
  final ThreadRepository _threadRepo = ThreadRepository();
  final MessageRepository _msgRepo = MessageRepository();
  final CommentService _commentService = CommentService();
  final _me = Supabase.instance.client.auth.currentUser;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCommentCount();
  }

  Future<void> _loadCommentCount() async {
    try {
      final count = await _commentService.getCommentCount(widget.post.id);
      if (mounted) {
        setState(() => _commentCount = count);
      }
    } catch (e) {
      // Silently fail - comment count is not critical
      print('Error loading comment count: $e');
    }
  }

  // Truncate description to approximately 10-15 words (about 2 lines)
  String get _truncatedDescription {
    final description = (widget.post.description ?? '').trim();
    if (description.isEmpty) return '';

    final words = description.split(' ');
    if (words.length <= 15) return description;

    return '${words.take(15).join(' ')}...';
  }

  bool get _shouldShowSeeMore {
    final description = (widget.post.description ?? '').trim();
    return description.split(' ').length > 15;
  }

  Future<void> _handleActionButton(String actionType) async {
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
              '📞 GENERAL INQUIRY\n\nHi! I saw your post about "${widget.post.title}" and would like to connect. Let\'s chat!';
          break;
        default:
          messageContent =
              '👋 I\'m interested in your post about "${widget.post.title}". Let\'s connect!';
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SuggestionForm(
            postId: widget.post.id, postTitle: widget.post.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.post.media.isNotEmpty;

    return _PressScale(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E5E5),
              width: 0.5,
            ),
          ),
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
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => PostDetailPage(post: widget.post)),
                    );
                    if (changed == true) widget.onEdited();
                  },
                )
              else
                GestureDetector(
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => PostDetailPage(post: widget.post)),
                    );
                    if (changed == true) widget.onEdited();
                  },
                  child: Container(
                    height: 200, // Consistent with new image sizing
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                      AppColors.primarySoft,
                      AppColors.subtleFill
                    ]) // Orange gradient
                        ),
                    child: const Center(
                        child: Icon(Icons.lightbulb_outline,
                            size: 48, color: Colors.white70)),
                  ),
                ),

              // Content Section - Full width optimization
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Moderation banner (only if not approved and viewer is author/admin)
                      Builder(builder: (context) {
                        final mod = widget.post.moderationStatus ?? 'approved';
                        final currentUser = Supabase.instance.client.auth.currentUser;
                        final isAuthor = currentUser?.id == widget.post.userId;
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
                          label = 'This post is under review and only visible to you.';
                        } else if (mod == 'blocked') {
                          bg = const Color(0xFFFFE9E9);
                          fg = const Color(0xFF8A1A1A);
                          icon = Icons.block_rounded;
                          label = 'Blocked: Only you can see this. Edit or delete to resubmit.';
                        } else {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                                      fontSize: 12.5,
                                      height: 1.25,
                                      color: fg,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                              if (mod == 'blocked')
                                TextButton(
                                  onPressed: () async {
                                    // Quick edit shortcut
                                    final saved = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => PostCreationPage(existing: widget.post),
                                      ),
                                    );
                                    if (saved == true) widget.onEdited();
                                  },
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  child: Text('Edit', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                if (widget.post.author?.userId != null &&
                                    widget.post.author!.userId.isNotEmpty &&
                                    widget.post.author!.userId !=
                                        Supabase.instance.client.auth
                                            .currentUser?.id) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfilePage(
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
                                children: [
                                  // User's full name as primary text (bold) - LinkedIn style
                                  Text(
                                    widget.post.author?.displayName ??
                                        'Unknown User',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  // Removed username line for cleaner, more professional look
                                ],
                              ),
                            ),
                            // Menu with Share + Edit/Delete options
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (val) async {
                                if (val == 'share') {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await ShareService.sharePost(
                                    postId: widget.post.id,
                                    title: widget.post.title,
                                    description: widget.post.description,
                                  );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Post shared successfully!')),
                                    );
                                  }
                                } else if (val == 'edit') {
                                  final saved =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                        builder: (_) => PostCreationPage(
                                            existing: widget.post)),
                                  );
                                  if (saved == true) widget.onEdited();
                                } else if (val == 'delete') {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Post?'),
                                      content:
                                          const Text('This cannot be undone.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel')),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    try {
                                      await FeedService()
                                          .deletePost(id: widget.post.id);
                                      widget.onDeleted();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text('Delete failed: $e')));
                                      }
                                    }
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
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      )),
                                ],
                              ],
                            ),
                          ]),

                      // Post Title Section - Tighter spacing for better hierarchy
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final changed =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) =>
                                    PostDetailPage(post: widget.post)),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                  height: 1.2,
                                ),
                              ),
                              // Startup name with enhanced styling
                              TextSpan(
                                text: widget.post.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Combined Tags and Goals Row - Optimized spacing
                      if (widget.subtitle.isNotEmpty ||
                          widget.goalLabel != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Hashtag as chip for consistency
                            if (widget.subtitle.isNotEmpty)
                              _CompactChip(
                                text: widget.subtitle,
                                color: Colors.grey[100]!,
                                borderColor: Colors.grey[300]!,
                              ),
                            // Goal label
                            if (widget.goalLabel != null)
                              _CompactChip(
                                text: widget.goalLabel!,
                                color: Colors.blue[50]!,
                                borderColor: Colors.blue[200]!,
                              ),
                            // Funding goal if present
                            if (widget.post.fundingGoal != null)
                              _CompactChip(
                                text: 'Goal: \$${widget.post.fundingGoal}',
                                color: Colors.green[50]!,
                                borderColor: Colors.green[200]!,
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Expandable Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDescriptionExpanded
                                ? (widget.post.description ?? '').trim()
                                : _truncatedDescription,
                            style:
                                const TextStyle(fontSize: 13.5, height: 1.35),
                          ),
                          if (_shouldShowSeeMore) ...[
                            const SizedBox(height: 4),
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
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Action Buttons Row - Always Visible
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Show Invest, Collab, Suggest only if not own post
                          if (widget.meUid != widget.post.userId) ...[
                            Expanded(
                              child: _ActionButton(
                                label: 'Invest',
                                icon: AppIcons.money(size: 14),
                                color:
                                    AppColors.primary, // Orange for investment
                                onPressed: () => _handleActionButton('invest'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                label: 'Collab',
                                icon: AppIcons.collab(size: 14),
                                color: AppColors
                                    .accent, // Golden yellow for collaboration
                                onPressed: () => _handleActionButton('collab'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                label: 'Suggest',
                                icon: AppIcons.suggest(size: 14),
                                color: AppColors
                                    .accentDark, // Deep orange for suggestions
                                onPressed: () => _handleActionButton('suggest'),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Comment Button - Always visible for everyone (icon only when has badge)
                          Expanded(
                            child: _ActionButton(
                              label: 'Comment',
                              icon: const Icon(Icons.comment_outlined, size: 14),
                              color: const Color(0xFF6B4EE6), // Purple for comments
                              badge: _commentCount > 0 ? _commentCount.toString() : null,
                              hideLabel: _commentCount > 0,
                              onPressed: _openComments,
                            ),
                          ),
                        ],
                      ),
                    ]),
              ),
            ]),
      ),
    );
  }

  Future<void> _openComments() async {
    await CommentSheet.show(context, widget.post);
    // Reload comment count after closing
    _loadCommentCount();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badge,
    this.hideLabel = false,
  });

  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onPressed;
  final String? badge;
  final bool hideLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14, height: 14, child: icon),
              if (!hideLabel) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              if (badge != null) ...[
                if (!hideLabel) const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Supporting widgets - copied from original feed_page.dart

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
      return Container(
        height: 200, // Slightly taller for better visual balance
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _url == null) {
      return Container(
        height: 200, // Consistent height with loading state
        color: Colors.grey[300],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.white70),
            SizedBox(height: 8),
            Text('Media unavailable',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
    }

    // Check if this is a video
    if (widget.mediaType == 'video') {
      return Hero(
        tag: widget.heroTag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 120,
            maxHeight: 400,
          ),
          child: VideoPlayerWidget(
            videoUrl: _url!,
            height: null, // Let it size naturally within constraints
            width: double.infinity,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 120, // Minimum height to ensure visibility
            maxHeight: 400, // Maximum height to prevent overly tall images
          ),
          child: Image.network(
            _url!,
            width: double.infinity,
            fit: BoxFit
                .contain, // Changed from cover to contain to show full image
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 170,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 170,
                color: Colors.grey[300],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.white70),
                    SizedBox(height: 8),
                    Text('Image unavailable',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? url;
  final String? name;
  final String? userId;
  final VoidCallback? onTap;

  const _AvatarCircle({this.url, this.name, this.userId, this.onTap});

  String get initial {
    if (name == null || name!.isEmpty) return '?';
    return name!.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 20,
        backgroundImage:
            (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
        backgroundColor: Colors.blue[300],
        child: (url == null || url!.isEmpty)
            ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w600))
            : null,
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;

  const _CompactChip({
    required this.text,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints:
          const BoxConstraints(maxWidth: 200), // Prevent overly long chips
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis, // Handle long text gracefully
      ),
    );
  }
}

/// Multi-image carousel widget for posts with swipe navigation
class _MediaCarousel extends StatefulWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _MediaCarousel({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.post.media;
    if (media.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Image carousel
          SizedBox(
            height: 300,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/features/post_creation/post_creation_page.dart';
import 'package:foundervers/features/suggestions/suggestion_form.dart';
import 'package:foundervers/features/messaging/message_compose_sheet.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/widgets/video_player_widget.dart';
import 'package:foundervers/services/share_service.dart';

import '../../services/supa.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});
  final PostModel post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.disabled = false});
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool disabled;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: disabled ? null : onTap,
      icon: icon,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PageController _pageController = PageController();
  late PostModel _post;
  final bool _sending = false;
  bool _loadingMedia = false;
  List<String?> _mediaUrls = const [];

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post.media.isNotEmpty) {
      _loadMediaUrls();
    }
  }

  Future<void> _loadMediaUrls() async {
    setState(() {
      _loadingMedia = true;
    });
    final client = Supa.client; // static accessor
    final bucket = AppEnv.startupbuilderBucket;
    final futures = <Future<String?>>[];
    for (final m in _post.media) {
      if ((m.type ?? 'image') != 'image') {
        futures.add(Future.value(null));
        continue;
      }
      final path = m.filePath ?? m.filename;
      if (path == null) {
        futures.add(Future.value(null));
        continue;
      }
      // Debug log
      // ignore: avoid_print
      print('[media] attempting load path=$path bucket=$bucket');
      // If legacy rows stored full public URL in file_path, just return it directly.
      if (path.startsWith('http://') || path.startsWith('https://')) {
        futures.add(Future.value(path));
        continue;
      }
      futures.add(() async {
        try {
          // Try a signed URL (6h). If bucket is public, fall back to public URL to avoid query params changing.
          final signed = await client.storage
              .from(bucket)
              .createSignedUrl(path, 60 * 60 * 6);
          if (signed.isNotEmpty) return signed;
        } catch (e) {
          // ignore and try public, but log for diagnostics
          // ignore: avoid_print
          print('[media] signed url failed for $path: $e');
        }
        try {
          final pub = client.storage.from(bucket).getPublicUrl(path);
          return pub;
        } catch (e) {
          // ignore: avoid_print
          print('[media] public url failed for $path: $e');
          return null;
        }
      }());
    }
    try {
      final results = await Future.wait(futures);
      if (mounted) {
        setState(() {
          _mediaUrls = results;
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar if needed
    } finally {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  Future<void> _openSuggestionForm() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit suggestions')),
      );
      return;
    }

    if (_post.userId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot suggest improvements to your own post')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SuggestionForm(
        postId: _post.id,
        postTitle: _post.title,
      ),
    );
  }

  Future<void> _openMessageCompose({required String type}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_post.userId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot message your own post.')));
      return;
    }

    await MessageComposeBottomSheet.show(
      context: context,
      post: _post,
      type: type,
    );
  }

  bool get _isOwner =>
      Supabase.instance.client.auth.currentUser?.id == _post.userId;

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PostService().deletePost(id: _post.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalLabel = AppConstants.goalLabel(_post.postGoal ?? 'other',
        customDescription: _post.postGoalDescription);
    final edited = _post.updatedAt != null &&
        _post.createdAt != null &&
        _post.updatedAt!.difference(_post.createdAt!).inMinutes >= 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(_post.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) async {
              if (val == 'share') {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  // Get the position of the button for iOS share sheet positioning
                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                  final Rect? sharePositionOrigin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
                  
                  await ShareService.sharePost(
                    postId: _post.id,
                    title: _post.title,
                    description: _post.description,
                    sharePositionOrigin: sharePositionOrigin,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Post shared successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to share post: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else if (val == 'edit') {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PostCreationPage(existing: _post),
                  ),
                );
                if (saved == true) {
                  // Reload the updated post from persistence
                  try {
                    final postData = await Supa.client
                        .from('posts')
                        .select('*')
                        .eq('id', _post.id)
                        .single();

                    final mediaData = await Supa.client
                        .from('post_media')
                        .select('*')
                        .eq('post_id', _post.id);

                    if (mounted) {
                      // Add media to post data for fromJson construction
                      postData['media'] = mediaData;
                      final updatedPost = PostModel.fromJson(postData);
                      setState(() {
                        _post = updatedPost;
                      });
                      // Reload media URLs if needed
                      if (_post.media.isNotEmpty) {
                        _loadMediaUrls();
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Failed to refresh post: ${e.toString()}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
              } else if (val == 'delete') {
                _confirmDelete();
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
                ),
              ),
              // Show edit/delete only for own posts
              if (_isOwner) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  if (_loadingMedia)
                    const Positioned.fill(
                        child: Center(child: CircularProgressIndicator()))
                  else
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _post.media.length,
                      itemBuilder: (context, i) {
                        final url =
                            (i < _mediaUrls.length) ? _mediaUrls[i] : null;
                        final media = _post.media[i];

                        if (url == null) {
                          return Container(
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: Text(media.filename ?? 'Media ${i + 1}'));
                        }

                        // Handle video media
                        if (media.type == 'video') {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: VideoPlayerWidget(
                              videoUrl: url,
                              height: 240,
                              width: double.infinity,
                            ),
                          );
                        }

                        // Handle image media
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (c, child, prog) => prog == null
                                ? child
                                : Container(
                                    color: Colors.black12,
                                    child: const Center(
                                        child: CircularProgressIndicator())),
                            errorBuilder: (c, err, stack) => Container(
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: AppIcons.warning(size: 20)),
                          ),
                        );
                      },
                    ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          final page = _pageController.hasClients &&
                                  _pageController.page != null
                              ? _pageController.page!.round()
                              : 0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                                _post.media.length,
                                (i) => Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i == page
                                              ? Colors.deepPurple
                                              : Colors.white,
                                          border: Border.all(
                                              color: Colors.deepPurple)),
                                    )),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: AppIcons.refresh(size: 18),
                      tooltip: 'Reload',
                      onPressed: _loadingMedia ? null : _loadMediaUrls,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if ((_post.category ?? '').isNotEmpty)
                Chip(
                  label: Text((_post.category ?? '').toUpperCase(),
                      style: const TextStyle(fontSize: 11)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              Chip(
                label: Text(goalLabel, style: const TextStyle(fontSize: 11)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              if (_post.fundingGoal != null)
                Chip(
                  label: Text('Goal: \$${_post.fundingGoal}',
                      style: const TextStyle(fontSize: 11)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
            ]),
            const SizedBox(height: 12),
            Text(_post.description ?? '', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final horizontal = maxW > 380;
                final buttons = [
                  _ActionBtn(
                      label: 'Invest',
                      icon: AppIcons.money(size: 18),
                      onTap: () => _openMessageCompose(type: 'invest'),
                      disabled: _sending),
                  _ActionBtn(
                      label: 'Collab',
                      icon: AppIcons.collab(size: 18),
                      onTap: () => _openMessageCompose(type: 'collab'),
                      disabled: _sending),
                  _ActionBtn(
                      label: 'Suggest',
                      icon: AppIcons.suggest(size: 18),
                      onTap: () => _openSuggestionForm(),
                      disabled: _sending),
                ];
                if (horizontal) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: buttons,
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: buttons,
                );
              },
            ),
            if (edited) ...[
              const SizedBox(height: 16),
              const Text('Edited',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}

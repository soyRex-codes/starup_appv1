import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'package:foundervers/core/env.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/services/moderation_service.dart';

// Post creation / editing page.
class PostCreationPage extends StatefulWidget {
  const PostCreationPage({super.key, this.existing});
  final PostModel? existing;
  bool get isEdit => existing != null;
  @override
  State<PostCreationPage> createState() => _PostCreationPageState();
}

class _PostCreationPageState extends State<PostCreationPage> {
  // Controllers & form state
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _fundingGoalCtrl = TextEditingController();
  final _goalOtherCtrl = TextEditingController();
  String? _category; // posts.category (nullable)
  String? _postGoal = 'funding'; // default matches DB default
  bool _saving = false;
  String? _error;

  final _svc = PostService();
  final List<PlatformFile> _files = [];

  Future<void> _pickMedia() async {
    if (_saving) return;
    try {
      setState(() => _error = null);

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.media,
        allowedExtensions: null,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final validFiles = <PlatformFile>[];
        final errors = <String>[];

        for (final file in result.files.take(6)) {
          // Check file type
          if (!StorageUtils.isSupportedFileType(file.name)) {
            errors.add('${file.name}: Unsupported file type');
            continue;
          }

          // Check file size
          if (file.size > 0 && !StorageUtils.isFileSizeValid(file.size)) {
            errors.add(
                '${file.name}: Too large (${StorageUtils.formatFileSize(file.size)}). Max 50MB.');
            continue;
          }

          validFiles.add(file);
        }

        if (errors.isNotEmpty) {
          setState(() => _error = errors.join('\n'));
        }

        if (validFiles.isNotEmpty) {
          // Check total size of all files
          final totalSize =
              validFiles.fold<int>(0, (sum, file) => sum + file.size);
          if (totalSize > 50 * 1024 * 1024) {
            setState(() => _error =
                'Total file size too large (${StorageUtils.formatFileSize(totalSize)}). Maximum 50MB total.');
            return;
          }

          setState(() {
            _files
              ..clear()
              ..addAll(validFiles);
            _error = null;
          });
        }
      }
    } catch (e) {
      setState(() => _error =
          'Media selection failed: Please try again or choose different files.');
    }
  }

  void _removeFile(int i) {
    if (_saving) return;
    setState(() => _files.removeAt(i));
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _description.text = existing.description ?? '';
      _category = existing.category;
      _postGoal = existing.postGoal ?? _postGoal;
      if (existing.fundingGoal != null) {
        _fundingGoalCtrl.text = existing.fundingGoal.toString();
      }
      if (existing.postGoal == 'other' &&
          (existing.postGoalDescription?.isNotEmpty ?? false)) {
        _goalOtherCtrl.text = existing.postGoalDescription!;
      }
    }
  }

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'You must be signed in.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    if (_postGoal == null) {
      setState(() => _error = 'Please select what you\'re looking for.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final authorName =
          (user.userMetadata?['name']?.toString().trim().isNotEmpty == true)
              ? user.userMetadata!['name']!.toString().trim()
              : ((user.email?.trim().isNotEmpty == true)
                  ? user.email!.trim()
                  : 'User');
      final fundingGoalNum =
          _postGoal == 'funding' && _fundingGoalCtrl.text.trim().isNotEmpty
              ? num.tryParse(_fundingGoalCtrl.text.trim())
              : null;
      final otherDesc = _postGoal == 'other'
          ? (_goalOtherCtrl.text.trim().isEmpty
              ? null
              : _goalOtherCtrl.text.trim())
          : null;

      int postId;
      final moderationService = ModerationService();

      // Always re-check on edit too (content might change to disallowed)
      final textModeration = await moderationService.moderatePost(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );

      if (textModeration.blocked) {
        setState(() => _error = 'Content blocked: ${textModeration.reasons.join(', ')}');
        return;
      }
      // Determine moderation status (pending posts already show banner in feed, no snackbar needed)
      final isPending = textModeration.pending;

      if (widget.isEdit) {
        postId = widget.existing!.id;
        await _svc.updatePost(
          id: postId,
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          category: _category,
          fundingGoal: fundingGoalNum,
          postGoal: _postGoal,
          postGoalDescription: otherDesc,
        );
      } else {
        postId = await _svc.createPost(
          userId: user.id,
          authorName: authorName,
          title: _title.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          category: _category,
          fundingGoal: fundingGoalNum,
          postGoal: _postGoal,
          postGoalDescription: otherDesc,
          email: user.email,
          moderationStatus: isPending ? 'pending' : 'approved',
        );
      }

      // Upload media
      if (_files.isNotEmpty) {
        final bucket = AppEnv.startupbuilderBucket;
        final mediaRows = <Map<String, dynamic>>[];

        // Progress tracking for better UX
        for (var i = 0; i < _files.length; i++) {
          final f = _files[i];
          try {
            // Check if file path is available
            if (f.path == null) {
              setState(() => _error =
                  'File "${f.name}" has no valid path. Please try selecting it again.');
              continue; // Skip this file and continue with others
            }

            final file = File(f.path!);
            final fileSize = await file.length();

            // Check file size before processing (50MB limit)
            if (fileSize > 50 * 1024 * 1024) {
              throw Exception(
                  'File "${f.name}" is too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum size is 50MB.');
            }

            final ext = (f.name.contains('.') ? f.name.split('.').last : 'jpg')
                .toLowerCase();
            final ts = DateTime.now().millisecondsSinceEpoch;
            final filename = '${user.id}_${ts}_$i.$ext';
            final storagePath = '${user.id}/$filename';

            // Determine content type more accurately
            final contentType = StorageUtils.getMimeType(f.name);

            // Use streaming upload for large files (>5MB) to prevent memory issues
            String storedPath;
            if (fileSize > 5 * 1024 * 1024) {
              // Stream upload for large files (videos, large images)
              storedPath = await _svc.uploadMediaFile(
                bucket: bucket,
                path: storagePath,
                file: file,
                contentType: contentType,
              );
            } else {
              // Binary upload for small files (backward compatibility)
              final bytes = await file.readAsBytes();
              storedPath = await _svc.uploadMediaBinary(
                bucket: bucket,
                path: storagePath,
                bytes: bytes,
                contentType: contentType,
              );
            }

            mediaRows.add({
              'post_id': postId,
              'type': contentType.startsWith('video/') ? 'video' : 'image',
              'filename': filename,
              'original_name': f.name,
              'file_path': storedPath,
              'file_size': fileSize,
            });
          } catch (uploadError) {
            // Continue with other uploads but track the error
            setState(() => _error =
                'Failed to upload "${f.name}": ${uploadError.toString()}');
            // Don't return here - continue with remaining uploads
          }
        }

        if (mediaRows.isNotEmpty) {
          // Check image moderation before saving media info
          final imageUrls = mediaRows.map((media) {
            final path = media['file_path'] as String;
            return 'https://${AppEnv.supabaseUrl.replaceFirst('https://', '')}/storage/v1/object/public/$bucket/$path';
          }).toList();
          
          // Image placeholder moderation (approximation)
          final imageModeration = await moderationService.moderatePost(
            title: _title.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            imageUrls: imageUrls,
          );

          if (imageModeration.blocked) {
            final pathsToDelete = mediaRows.map((m) => m['file_path'] as String).toList();
            try { await Supabase.instance.client.storage.from(bucket).remove(pathsToDelete); } catch (_) {}
            try { await _svc.deletePost(id: postId); } catch (_) {}
            setState(() => _error = 'Images blocked (${imageModeration.reasons.join(', ')}). Remove them and try again.');
            return;
          }
          
          try {
            await _svc.insertMediaRows(postId: postId, mediaList: mediaRows);
          } catch (mediaInsertError) {
            setState(() => _error =
                'Failed to save media info: ${mediaInsertError.toString()}');
          }
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickCategory() async {
    final sel = await _showPicker(
      title: 'Select Category',
      options: [null, ...AppConstants.industryCategories],
      display: (v) => v ?? 'No category',
      current: _category,
    );
    if (sel is String? && mounted) setState(() => _category = sel);
  }

  Future<void> _pickGoal() async {
    final sel = await _showPicker(
      title: 'Select Goal *',
      options: AppConstants.postGoals,
      display: (v) => AppConstants.goalLabel(v),
      current: _postGoal,
    );
    if (sel is String && mounted) setState(() => _postGoal = sel);
  }

  Future<dynamic> _showPicker<T>({
    required String title,
    required List<T> options,
    required String Function(T) display,
    required T? current,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (c, i) {
                    final opt = options[i];
                    final sel = opt == current;
                    return ListTile(
                      dense: true,
                      title: Text(display(opt)),
                      trailing: sel ? AppIcons.success(size: 20) : null,
                      onTap: () => Navigator.of(ctx).pop(opt),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name =
        (user?.userMetadata?['full_name']?.toString().trim().isNotEmpty ??
                false)
            ? user!.userMetadata!['full_name']!.toString().trim()
            : (user?.email ?? '');
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside form fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? 'Edit Post' : 'Share Your Business Idea'),
          actions: [
            if (!_saving)
              IconButton(
                tooltip: 'Cancel',
                icon: AppIcons.close(size: 24),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _Label('Your Name'),
              TextFormField(
                initialValue: name,
                readOnly: true,
                decoration: const InputDecoration(isDense: true),
              ),
              const SizedBox(height: 14),
              _Label('Business Category'),
              _PickerField(
                label: _category == null ? 'Select Category' : _category!,
                onTap: _pickCategory,
              ),
              const SizedBox(height: 14),
              _Label('Business Idea Title *'),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    hintText: 'Give your idea a catchy title'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),
              _Label('Description'),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                    hintText:
                        'Describe your business idea, what problem it solves, and your vision...'),
                maxLines: 5,
              ),
              const SizedBox(height: 14),
              _Label('What are you looking for? *'),
              _PickerField(
                label: _postGoal == null
                    ? 'Select your main goal'
                    : AppConstants.goalLabel(_postGoal!),
                onTap: _pickGoal,
              ),
              if (_postGoal == 'funding') ...[
                const SizedBox(height: 14),
                _Label('Funding Goal (USD) *'),
                TextFormField(
                  controller: _fundingGoalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'How much funding do you need?'),
                  validator: (v) {
                    if (_postGoal == 'funding') {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (num.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
              ],
              if (_postGoal == 'other') ...[
                const SizedBox(height: 14),
                _Label('Describe your goal'),
                TextFormField(
                  controller: _goalOtherCtrl,
                  maxLength: 80,
                  decoration:
                      const InputDecoration(hintText: 'Short description'),
                ),
              ],
              const SizedBox(height: 18),
              _Label('Upload Media (Photos/Videos)'),
              _MediaPickerBox(
                files: _files,
                onAdd: _pickMedia,
                onRemove: _removeFile,
                saving: _saving,
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      AppIcons.error(size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                const SizedBox(width: 8),
                                Text(widget.isEdit
                                    ? 'Saving...'
                                    : 'Publishing...'),
                              ],
                            )
                          : Text(widget.isEdit
                              ? 'Save Changes'
                              : 'Post Your Idea'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6FC),
          border: Border.all(color: const Color(0xFFE2D9F3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Transform.rotate(
                angle: 3.14159, child: AppIcons.backArrow(size: 20)),
          ],
        ),
      ),
    );
  }
}

class _MediaPickerBox extends StatelessWidget {
  const _MediaPickerBox(
      {required this.files,
      required this.onAdd,
      required this.onRemove,
      required this.saving});
  final List<PlatformFile> files;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final bool saving;

  bool _isVideo(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFE0CFF7),
              style: BorderStyle.solid,
              width: 1,
              strokeAlign: BorderSide.strokeAlignOutside),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcons.upload(size: 32),
            const SizedBox(height: 8),
            Text(
                files.isEmpty
                    ? 'Tap to add media'
                    : 'Tap to add / replace (${files.length}/6)',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            if (files.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < files.length; i++)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _isVideo(files[i].name)
                              ? Container(
                                  width: 88,
                                  height: 88,
                                  color: Colors.grey[800],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow,
                                          color: Colors.white, size: 24),
                                      SizedBox(height: 4),
                                      Text('Video',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10)),
                                    ],
                                  ),
                                )
                              : Image.file(
                                  File(files[i].path!),
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 88,
                                    height: 88,
                                    color: Colors.grey[300],
                                    child: AppIcons.warning(size: 24),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: GestureDetector(
                            onTap: saving ? null : () => onRemove(i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: AppIcons.close(size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
                files.isEmpty
                    ? 'Upload images, videos, or PDFs up to 50MB total'
                    : '${files.length} file${files.length == 1 ? '' : 's'} selected • Up to 50MB total',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

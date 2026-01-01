import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foundervers/core/storage_utils.dart';

import 'new_dm_repos.dart';
import 'dm_profile_cache.dart';
import 'dm_service.dart';
import '../../app/app_icons.dart';
import '../../app/theme.dart';
import '../../features/profile/unified_profile_page.dart';
import '../../services/media_compression_service.dart';

/// Public thread view for individual conversations
class ThreadView extends StatefulWidget {
  const ThreadView({required this.thread, super.key});
  final ThreadSummary thread;

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  final _msgRepo = MessageRepository();
  final _me = Supabase.instance.client.auth.currentUser;
  final _messages = <ChatMessage>[];
  bool _loading = true;
  bool _sending = false;
  final _input = TextEditingController();
  bool _atEnd = false; // reached oldest
  RealtimeChannel? _channel;
  bool _markingRead = false;

  // For displaying participant name
  ProfileModel? _otherParticipant;
  bool _loadingProfile = true;
  final _picker = ImagePicker();
  bool _uploading = false;
  
  // Staged media for preview before sending
  Uint8List? _stagedMediaBytes;
  String? _stagedFileName;
  String? _stagedFileExt;
  String? _stagedMessageType; // 'image' or 'file'
  int? _stagedFileSize;
  
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB

  @override
  void initState() {
    super.initState();
    _loadParticipantInfo();
    _loadPage();
    // LAZY LOAD: Only attach realtime when widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachRealtime();
    });
  }

  /// Load the other participant's profile information
  Future<void> _loadParticipantInfo() async {
    if (_me == null) return;

    try {
      // Find the other participant (not the current user)
      final otherParticipantId = widget.thread.participantIds
          .firstWhere((id) => id != _me.id, orElse: () => '');

      if (otherParticipantId.isNotEmpty) {
        final profile =
            await DMProfileCache.instance.getProfile(otherParticipantId);
        if (mounted) {
          setState(() {
            _otherParticipant = profile;
            _loadingProfile = false;
          });
        }
      } else {
        // Self-conversation case
        if (mounted) {
          setState(() {
            _loadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadPage({DateTime? before}) async {
    setState(() {
      _loading = _messages.isEmpty;
    });
    try {
      final page = await _msgRepo.pageMessages(
          threadId: widget.thread.threadId, before: before, limit: 40);
      if (page.isEmpty) {
        setState(() {
          _atEnd = true;
        });
      } else {
        setState(() {
          _messages.addAll(page);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });
      }
    } catch (e) {
      // ignore for now; could add error display
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    // Guard: Must have either media or text
    if (_stagedMediaBytes == null && text.isEmpty) return;
    if (_me == null) return;
    
    // Prevent multiple clicks
    if (_sending) return;

    setState(() {
      _sending = true;
    });

    try {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();

      // 1. Send Staged Media if present
      if (_stagedMediaBytes != null) {
        await _uploadAndSend(
          bytes: _stagedMediaBytes!,
          fileName: _stagedFileName!,
          fileExt: _stagedFileExt!,
          messageType: _stagedMessageType!,
          fileSize: _stagedFileSize!,
        );
        _clearStagedMedia();
      }

      // 2. Send Text if present
      if (text.isNotEmpty) {
        final optimistic = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: widget.thread.threadId,
          senderId: _me.id,
          content: text,
          createdAt: DateTime.now(),
          messageType: 'text',
        );
        setState(() {
          _messages.add(optimistic);
        });
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _input.clear();
        
        final persisted = await _msgRepo.send(
            threadId: widget.thread.threadId, senderId: _me.id, body: text);
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx != -1) _messages[idx] = persisted;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress to save data
      );
      
      if (image == null) return;

      // Compress image for staging
      final originalFile = File(image.path);
      final compressedFile = await MediaCompressionService.instance.compressImage(
        originalFile,
        quality: 70, // Balanced quality
      );
      
      final bytes = await compressedFile.readAsBytes();
      final fileExt = compressedFile.path.split('.').last;
      final fileSize = await compressedFile.length();
      
      if (mounted) {
        setState(() {
          _stagedMediaBytes = bytes;
          _stagedFileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          _stagedFileExt = fileExt;
          _stagedMessageType = 'image';
          _stagedFileSize = fileSize;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      
      if (file.size > _maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large (Max 10MB)')),
          );
        }
        return;
      }

      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final fileExt = file.extension ?? 'file';

      if (mounted) {
        setState(() {
          _stagedMediaBytes = bytes;
          _stagedFileName = file.name;
          _stagedFileExt = fileExt;
          _stagedMessageType = 'file';
          _stagedFileSize = file.size;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  void _clearStagedMedia() {
    setState(() {
      _stagedMediaBytes = null;
      _stagedFileName = null;
      _stagedFileExt = null;
      _stagedMessageType = null;
      _stagedFileSize = null;
    });
  }

  Future<void> _uploadAndSend({
    required Uint8List bytes,
    required String fileName,
    required String fileExt,
    required String messageType,
    required int fileSize,
  }) async {
    if (_me == null) return;

    // _uploading is already set to true by the caller
    // but we keep this for safety if called from elsewhere
    if (!_uploading) {
      setState(() {
        _uploading = true;
      });
    }

    try {
      // 1. Upload to Supabase Storage
      // Use a timestamp prefix for images to ensure uniqueness if not provided
      final storagePath = messageType == 'image' 
          ? '${_me.id}/$fileName' // fileName is already timestamped for images
          : '${_me.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName'; // Add timestamp for files

      await Supabase.instance.client.storage
          .from('chat-media')
          .uploadBinary(storagePath, bytes);

      // 2. Get Public URL
      final fileUrl = Supabase.instance.client.storage
          .from('chat-media')
          .getPublicUrl(storagePath);

      // 3. Prepare Metadata
      final metadata = {
        'url': fileUrl,
        'path': storagePath,
        'file_name': fileName,
        'file_size': fileSize,
        'extension': fileExt,
      };

      // 4. Send Message
      final content = messageType == 'image' ? '📷 Image' : '📎 $fileName';
      
      final optimistic = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.thread.threadId,
        senderId: _me.id,
        content: content,
        createdAt: DateTime.now(),
        messageType: messageType,
        metadata: metadata,
      );

      setState(() {
        _messages.add(optimistic);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

      final persisted = await _msgRepo.send(
        threadId: widget.thread.threadId,
        senderId: _me.id,
        body: content,
        messageType: messageType,
        metadata: metadata,
      );

      setState(() {
        final idx = _messages.indexWhere((m) => m.id == optimistic.id);
        if (idx != -1) _messages[idx] = persisted;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send attachment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: Text('Photo Gallery', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: Text('Document', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _attachRealtime() {
    // ⚠️ REAL-TIME STATUS: INACTIVE (Table doesn't exist)
    //
    // CONFUSION ALERT: This code references 'dm_messages' table which DOESN'T EXIST!
    //
    // Current database schema (per main_mobile_app_database_schema.sql line 45):
    // - 'dm_messages' table was DROPPED in migration
    // - Replaced by 'messages' table (with conversation_id foreign key)
    //
    // This is OLD/DEAD CODE from previous DM implementation.
    // Subscription will fail silently since table doesn't exist.
    //
    // App still works because:
    // - _loadMore() manually fetches messages from correct 'messages' table
    // - UI refreshes on _send() optimistic updates
    // - Real-time is bonus feature, not required
    //
    // Correct implementation would subscribe to 'messages' table (which IS enabled):
    // table: 'messages'  // ✅ This table exists and is in publications
    // filter: conversation_id = widget.thread.threadId
    //
    // Safe to leave as-is (no performance impact), but could be updated to use
    // correct table name if real-time thread updates are desired in future.
    final client = Supabase.instance.client;
    _channel = client.channel('thread_${widget.thread.threadId}');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages', // ✅ Correct table name
      // Filter for only messages in this thread
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id', // ✅ Correct column name
        value: widget.thread.threadId,
      ),
      callback: (payload) {
        try {
          final newRow = payload.newRecord;
          if (newRow.isEmpty) return;
          
          // Convert to ChatMessage
          // Note: newRow might be missing joined fields, but ChatMessage.fromJson handles basic fields
          final msg = ChatMessage.fromJson(newRow);
          
          if (_messages.any((m) => m.id == msg.id)) return;
          
          if (mounted) {
            setState(() {
              _messages.add(msg);
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            });
          }
          
          if (msg.senderId != _me?.id) {
            _markThreadRead();
          }
        } catch (e) {
          debugPrint('Error handling realtime message: $e');
        }
      },
    );
    
    _channel!.subscribe();
  }

  Future<void> _markThreadRead() async {
    if (_markingRead || _me == null) return;
    _markingRead = true;
    try {
      await ThreadRepository().markRead(widget.thread.threadId, _me.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to mark read: $e')));
      }
    } finally {
      _markingRead = false;
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await DMService.instance.deleteMessage(messageId, widget.thread.conversationId);
      setState(() {
        _messages.removeWhere((m) => m.id == messageId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  /// Get the display title for the conversation
  String get _conversationTitle {
    if (_loadingProfile) return 'Loading...';

    // Check if it's a self-conversation
    final iselfConversation = widget.thread.participantIds.length == 1 ||
        widget.thread.participantIds.every((id) => id == _me?.id);

    if (iselfConversation) {
      return 'You'; // or "Notes to Self", etc.
    }

    // Use the other participant's name
    if (_otherParticipant?.name?.isNotEmpty == true) {
      return _otherParticipant!.name!;
    }

    // Fallback
    return 'Conversation';
  }

  @override
  void dispose() {
    _input.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_conversationTitle)),
        body: Column(children: [
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (notif) {
                      if (notif.metrics.pixels <=
                              notif.metrics.minScrollExtent + 40 &&
                          !_atEnd &&
                          !_loading) {
                        final oldest = _messages.isNotEmpty
                            ? _messages.first.createdAt
                            : null;
                        if (oldest != null) _loadPage(before: oldest);
                      }
                      if (!_markingRead &&
                          notif.metrics.pixels >=
                              notif.metrics.maxScrollExtent - 40) {
                        _markThreadRead();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      reverse: false,
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final mine = m.senderId == _me?.id;
                        return _MessageBubble(
                          message: m,
                          mine: mine,
                          onDelete: mine ? () => _deleteMessage(m.id) : null,
                        );
                      },
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_stagedMediaBytes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      children: [
                        if (_stagedMessageType == 'image')
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_stagedMediaBytes!, width: 60, height: 60, fit: BoxFit.cover),
                          )
                        else
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description, color: Colors.blue, size: 30),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stagedFileName ?? 'File',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (_stagedFileSize != null)
                                Text(
                                  '${(_stagedFileSize! / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: _clearStagedMedia,
                        ),
                      ],
                    ),
                  ),
                Row(children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: _uploading 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_circle_outline, color: Colors.grey),
                        onPressed: _uploading ? null : _showAttachmentOptions,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onSubmitted: (text) {
                            if (!_sending) _send();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : AppIcons.send(size: 22),
                onPressed: _sending ? null : _send,
              )
            ]),
              ],
            ),
          )
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool mine;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.mine,
    this.onDelete,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  DmUserProfile? _sender;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final p = await DmProfileCache.instance.fetch(widget.message.senderId);
    if (mounted) setState(() => _sender = p);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bubble = GestureDetector(
      onLongPress: widget.onDelete != null
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Message?'),
                  content: const Text(
                      'This message will be removed for everyone in the chat.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete?.call();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.mine
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          if (!widget.mine)
            GestureDetector(
              onTap: () {
                if (widget.message.senderId.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UnifiedProfilePage(
                        userId: widget.message.senderId,
                        userName: _sender?.name,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                  (_sender?.name ?? widget.message.senderId).split('\n').first,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        AppColors.primary, // Use orange for clickable usernames
                    decoration: TextDecoration.underline,
                  )),
            ),
          if (!widget.mine) const SizedBox(height: 2),
          if (widget.message.messageType == 'image')
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      body: Center(
                          child: InteractiveViewer(
                            child: CachedNetworkImage(
                              // Request high-res but optimized image for full screen
                              imageUrl: StorageUtils.resolvePublicUrl(
                                widget.message.metadata['path'],
                                bucket: 'chat-media',
                              ) ?? widget.message.metadata['url'] ?? '',
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  // Request small thumbnail for bubble
                  imageUrl: StorageUtils.resolvePublicUrl(
                    widget.message.metadata['path'],
                    bucket: 'chat-media',
                  ) ?? widget.message.metadata['url'] ?? '',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            )
          else if (widget.message.messageType == 'file')
            GestureDetector(
              onTap: () async {
                final url = widget.message.metadata['url'];
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.mine ? Colors.white.withValues(alpha: 0.2) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.mine ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.metadata['file_name'] ?? 'Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: widget.mine ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            _formatFileSize(widget.message.metadata['file_size']),
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.mine ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              widget.message.content,
              style: TextStyle(
                fontSize: 15,
                color: isDark 
                    ? const Color(0xFFE0E0E0) // Light text for dark mode
                    : Colors.black87, // Dark text for light mode
              ),
            ),
        ],
    ),
      ),
    );
    return Align(
      alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: bubble,
      ),
    );
  }
  String _formatFileSize(dynamic size) {
    if (size == null) return '';
    final bytes = size is int ? size : int.tryParse(size.toString()) ?? 0;
    if (bytes <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double s = bytes.toDouble();
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(1)} ${suffixes[i]}';
  }
}

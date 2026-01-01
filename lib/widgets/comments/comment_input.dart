import 'package:flutter/material.dart';
import 'package:foundervers/models/comment.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/widgets/comments/category_selector.dart';

/// Input widget for composing new comments or replies
class CommentInput extends StatefulWidget {
  final int postId;
  final CommentModel? replyingTo;
  final Function(String content, CommentCategory? category) onSubmit;
  final VoidCallback? onCancelReply;

  const CommentInput({
    required this.postId,
    required this.onSubmit,
    this.replyingTo,
    this.onCancelReply,
    super.key,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  CommentCategory? _selectedCategory;
  bool _isSubmitting = false;

  bool get _isReply => widget.replyingTo != null;
  bool get _canSubmit =>
      _controller.text.trim().isNotEmpty &&
      (_isReply || _selectedCategory != null) &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    // Auto-focus when replying
    if (_isReply) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        _controller.text.trim(),
        _isReply ? null : _selectedCategory,
      );

      // Clear input after successful submission
      _controller.clear();
      if (!_isReply) {
        setState(() => _selectedCategory = null);
      }
      _focusNode.unfocus();
    } catch (e) {
      // Error handling is done in parent widget
      debugPrint('Error submitting comment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColorsDark.card : AppColors.card;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final bgColor = isDark ? AppColorsDark.bg : AppColors.bg;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category selector (only for root comments)
          if (!_isReply)
            CategorySelector(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),

          // Reply banner (when replying to a comment)
          if (_isReply) _buildReplyBanner(isDark),

          // Input field and submit button
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0
                  ? 12
                  : MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _isReply
                            ? 'Write a reply...'
                            : 'Add a comment... (Select category above)',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(fontSize: 14, color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Submit button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _canSubmit ? _handleSubmit : null,
                          icon: Icon(
                            Icons.send_rounded,
                            color: _canSubmit
                                ? primary
                                : textSecondary,
                          ),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            backgroundColor: _canSubmit
                                ? primary.withValues(alpha: 0.1)
                                : borderColor.withValues(alpha: 0.3),
                            shape: const CircleBorder(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner(bool isDark) {
    final primarySoft = isDark ? AppColorsDark.primarySoft : AppColors.primarySoft;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primarySoft,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply_rounded,
            size: 16,
            color: primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to ${widget.replyingTo?.author?.displayName ?? "comment"}',
              style: TextStyle(
                fontSize: 13,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: const Icon(Icons.close, size: 18),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              foregroundColor: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

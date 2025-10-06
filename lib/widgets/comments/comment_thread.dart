import 'package:flutter/material.dart';
import 'package:foundervers/models/comment.dart';
import 'package:foundervers/widgets/comments/comment_card.dart';

/// Widget to display a comment and its nested replies in a thread
class CommentThread extends StatelessWidget {
  final CommentModel comment;
  final Function(CommentModel) onReply;
  final Function(String) onDelete;

  const CommentThread({
    required this.comment,
    required this.onReply,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Parent comment
        CommentCard(
          comment: comment,
          onReply: () => onReply(comment),
          onDelete: () => onDelete(comment.id),
        ),

        // Nested replies
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => _buildReply(reply)),
      ],
    );
  }

  Widget _buildReply(CommentModel reply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommentCard(
          comment: reply,
          isReply: true,
          onReply: () => onReply(reply),
          onDelete: () => onDelete(reply.id),
        ),
        
        // Nested replies (recursive for multi-level threading)
        if (reply.replies.isNotEmpty)
          ...reply.replies.map((nestedReply) => _buildNestedReply(nestedReply)),
      ],
    );
  }

  Widget _buildNestedReply(CommentModel reply) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: CommentCard(
        comment: reply,
        isReply: true,
        onReply: () => onReply(reply),
        onDelete: () => onDelete(reply.id),
      ),
    );
  }
}

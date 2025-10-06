import 'package:flutter/material.dart';
import 'package:foundervers/models/comment.dart';
import 'package:foundervers/app/theme.dart';

/// Widget for selecting a comment category before posting
class CategorySelector extends StatelessWidget {
  final CommentCategory? selectedCategory;
  final ValueChanged<CommentCategory> onCategorySelected;

  const CategorySelector({
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: CommentCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = CommentCategory.values[index];
          final isSelected = category == selectedCategory;

          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CommentCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _getCategoryColor() : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _getCategoryColor()
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _getCategoryColor().withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.displayLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (category) {
      case CommentCategory.question:
        return const Color(0xFF2196F3); // Blue
      case CommentCategory.idea:
        return const Color(0xFFFFB300); // Amber
      case CommentCategory.critique:
        return const Color(0xFF8E24AA); // Purple
      case CommentCategory.resource:
        return const Color(0xFF43A047); // Green
      case CommentCategory.general:
        return AppColors.primary;
    }
  }
}

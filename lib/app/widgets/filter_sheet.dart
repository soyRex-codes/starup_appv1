import 'package:flutter/material.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/app/theme.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    this.initialCategory,
    this.initialGoal,
  });

  final String? initialCategory;
  final String? initialGoal;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedCategory;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedGoal = widget.initialGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clear filters button (only show when filters are active)
                    if (_hasActiveFilters())
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcons.close(
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_hasActiveFilters()) const SizedBox(width: 12),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: AppIcons.close(
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Content
          // Content
          Expanded(
            child: Row(
              children: [
                // Categories Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            AppIcons.business(
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Options List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _FilterOption(
                              label: 'All Categories',
                              isSelected: _selectedCategory == null,
                              isCompact: true,
                              onTap: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                            ),
                            const SizedBox(height: 6),
                            ...AppConstants.industryCategories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _FilterOption(
                                  label: _getCategoryDisplayName(category),
                                  isSelected: _selectedCategory == category,
                                  isCompact: true,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                ),

                // Right Side - Goals
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            AppIcons.business(
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Looking For',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Options List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _FilterOption(
                              label: 'All Goals',
                              isSelected: _selectedGoal == null,
                              isCompact: true,
                              onTap: () => setState(() => _selectedGoal = null),
                            ),
                            const SizedBox(height: 6),
                            ...AppConstants.postGoals.map(
                              (goal) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _FilterOption(
                                  label: _getShortGoalLabel(goal),
                                  isSelected: _selectedGoal == goal,
                                  isCompact: true,
                                  onTap: () =>
                                      setState(() => _selectedGoal = goal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Apply button takes full width when no filters, or most space when filters exist
                  Expanded(
                    flex: _hasActiveFilters() ? 3 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'category': _selectedCategory,
                          'goal': _selectedGoal,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getApplyButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortGoalLabel(String goal) {
    switch (goal) {
      case 'funding':
        return 'Funding';
      case 'team':
        return 'Team Members';
      case 'skills':
        return 'Skills';
      case 'partnership':
        return 'Partnership';
      case 'mentorship':
        return 'Mentorship';
      case 'feedback':
        return 'Feedback';
      case 'other':
        return 'Opportunities';
      default:
        return goal;
    }
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null || _selectedGoal != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedGoal = null;
    });
  }

  String _getApplyButtonText() {
    final filters = <String>[];
    if (_selectedCategory != null) filters.add('Category');
    if (_selectedGoal != null) filters.add('Goal');

    if (filters.isEmpty) return 'Show All Posts';
    return 'Apply ${filters.join(' + ')} Filter${filters.length > 1 ? 's' : ''}';
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return '💻 Technology';
      case 'healthcare':
        return '🏥 Healthcare';
      case 'finance':
        return '💰 Finance';
      case 'education':
        return '📚 Education';
      case 'entertainment':
        return '🎬 Entertainment';
      case 'other':
        return '🔧 Other';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              AppIcons.success(
                size: isCompact ? 16 : 18,
              )
            else
              AppIcons.circle(
                size: isCompact ? 16 : 18,
              ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

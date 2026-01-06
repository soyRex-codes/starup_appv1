import 'package:flutter/material.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/models/post_age.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    this.initialCategories,
    this.initialGoals,
    this.initialDateRange,
  });

  final List<String>? initialCategories;
  final List<String>? initialGoals;
  final PostAge? initialDateRange;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  Set<String> _selectedCategories = {};
  Set<String> _selectedGoals = {};
  PostAge _selectedDateRange = PostAge.all;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set<String>.from(widget.initialCategories ?? []);
    _selectedGoals = Set<String>.from(widget.initialGoals ?? []);
    _selectedDateRange = widget.initialDateRange ?? PostAge.all;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final sectionHeaderFontSize = isSmallScreen ? 12.0 : 14.0;
    final optionFontSize = isSmallScreen ? 12.0 : 13.0;
    final dateLabelFontSize = isSmallScreen ? 12.0 : 13.0;
    final dateChipFontSize = isSmallScreen ? 12.0 : 14.0;

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
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 360 ? 16 : 20,
              vertical: isSmallScreen ? 12 : 16,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Posts',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900], // Always dark for white background
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
                              horizontal: 8, vertical: 4),
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
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_hasActiveFilters()) const SizedBox(width: 8),
                    // Close button (X icon)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Date Range Row
          _buildDateRangeRow(
              isSmallScreen, screenWidth, dateLabelFontSize, dateChipFontSize),

          // Filter Content
          Expanded(
            child: Row(
              children: [
                // Categories Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header with count
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth < 360 ? 16 : 20,
                          isSmallScreen ? 10 : 16,
                          screenWidth < 360 ? 16 : 20,
                          isSmallScreen ? 8 : 12,
                        ),
                        child: Row(
                          children: [
                            AppIcons.business(
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: sectionHeaderFontSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (_selectedCategories.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_selectedCategories.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Select All / Clear button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedCategories.length ==
                                      AppConstants.industryCategories.length) {
                                    _selectedCategories.clear();
                                  } else {
                                    _selectedCategories = Set<String>.from(
                                        AppConstants.industryCategories);
                                  }
                                });
                              },
                              child: Text(
                                _selectedCategories.length ==
                                        AppConstants.industryCategories.length
                                    ? 'Clear'
                                    : 'All',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Options List
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 360 ? 12 : 16,
                          ),
                          children: [
                            ...AppConstants.industryCategories.map((category) {
                              final isSelected =
                                  _selectedCategories.contains(category);
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isSmallScreen ? 4 : 6,
                                ),
                                child: _MultiSelectOption(
                                  label: _getCategoryDisplayName(category),
                                  isSelected: isSelected,
                                  isCompact: true,
                                  fontSize: optionFontSize,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedCategories.remove(category);
                                      } else {
                                        _selectedCategories.add(category);
                                      }
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
                  margin: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 16,
                  ),
                ),

                // Right Side - Goals
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header with count
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth < 360 ? 16 : 20,
                          isSmallScreen ? 10 : 16,
                          screenWidth < 360 ? 16 : 20,
                          isSmallScreen ? 8 : 12,
                        ),
                        child: Row(
                          children: [
                            AppIcons.business(
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Looking For',
                              style: TextStyle(
                                fontSize: sectionHeaderFontSize,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (_selectedGoals.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_selectedGoals.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Select All / Clear button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedGoals.length ==
                                      AppConstants.postGoals.length) {
                                    _selectedGoals.clear();
                                  } else {
                                    _selectedGoals = Set<String>.from(
                                        AppConstants.postGoals);
                                  }
                                });
                              },
                              child: Text(
                                _selectedGoals.length ==
                                        AppConstants.postGoals.length
                                    ? 'Clear'
                                    : 'All',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Options List
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 360 ? 12 : 16,
                          ),
                          children: [
                            ...AppConstants.postGoals.map((goal) {
                              final isSelected = _selectedGoals.contains(goal);
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isSmallScreen ? 4 : 6,
                                ),
                                child: _MultiSelectOption(
                                  label: _getShortGoalLabel(goal),
                                  isSelected: isSelected,
                                  isCompact: true,
                                  fontSize: optionFontSize,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedGoals.remove(goal);
                                      } else {
                                        _selectedGoals.add(goal);
                                      }
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
              ],
            ),
          ),

          // Bottom Actions
          Container(
            padding: EdgeInsets.fromLTRB(
              screenWidth < 360 ? 16 : 20,
              isSmallScreen ? 12 : 16,
              screenWidth < 360 ? 16 : 20,
              isSmallScreen ? 14 : 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: _hasActiveFilters() ? 3 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'categories': _selectedCategories.toList(),
                          'goals': _selectedGoals.toList(),
                          'dateRange': _selectedDateRange.value,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getApplyButtonText(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 13 : 15,
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

  Widget _buildDateRangeRow(bool isSmallScreen, double screenWidth,
      double dateLabelFontSize, double dateChipFontSize) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth < 360 ? 16 : 20,
        isSmallScreen ? 10 : 16,
        screenWidth < 360 ? 16 : 20,
        isSmallScreen ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with icon
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: dateLabelFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),

          // Segmented chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PostAge.values.asMap().entries.map((entry) {
                final age = entry.value;
                final isSelected = _selectedDateRange == age;
                final isLast = entry.key == PostAge.values.length - 1;

                return Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDateRange = age),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        age.label,
                        style: TextStyle(
                          fontSize: dateChipFontSize,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
    return _selectedCategories.isNotEmpty ||
        _selectedGoals.isNotEmpty ||
        _selectedDateRange != PostAge.all;
  }

  void _clearFilters() {
    // Clear filters and immediately apply (close sheet)
    Navigator.pop(context, {
      'categories': <String>[],
      'goals': <String>[],
      'dateRange': PostAge.all.value,
    });
  }

  String _getApplyButtonText() {
    final filters = <String>[];
    if (_selectedCategories.isNotEmpty) {
      filters.add(_selectedCategories.length == 1
          ? 'Category'
          : 'Categories (${_selectedCategories.length})');
    }
    if (_selectedGoals.isNotEmpty) {
      filters.add(_selectedGoals.length == 1
          ? 'Goal'
          : 'Goals (${_selectedGoals.length})');
    }
    if (_selectedDateRange != PostAge.all) filters.add('Date');

    if (filters.isEmpty) return 'Show All Posts';
    return 'Apply ${filters.join(' + ')}';
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

/// Multi-select option widget with checkbox-style UI
class _MultiSelectOption extends StatelessWidget {
  const _MultiSelectOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
    this.fontSize = 13,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 16,
          vertical: isCompact ? 8 : 14,
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
            // Checkbox icon
            Container(
              width: isCompact ? 18 : 22,
              height: isCompact ? 18 : 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: isCompact ? 12 : 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
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

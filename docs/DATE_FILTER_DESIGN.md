# Date Range Filter Implementation - Design Recommendations

## Current Setup Analysis

Your feed currently has:
- ✅ Category filter (Technology, Healthcare, Finance, etc.)
- ✅ Goal filter (Funding, Team, Skills, Partnership, etc.)
- ✅ Search functionality
- ✅ Two-column filter sheet UI
- ✅ Smart cache system with adaptive TTL

---

## 🎯 Recommended Date Range Options

After analyzing similar apps (LinkedIn, Twitter, Product Hunt), here are **user-friendly** time ranges:

### Option A: Simple & Intuitive (RECOMMENDED)
```dart
enum PostAge {
  today,        // "Today" - Last 24 hours
  thisWeek,     // "This Week" - Last 7 days
  thisMonth,    // "This Month" - Last 30 days
  all,          // "All Time" - No date filter (default)
}
```

**Why this is best:**
- ✅ Clear, non-technical language
- ✅ Covers all common use cases
- ✅ Reduces cognitive load (users don't think in hours)
- ✅ Aligns with how people think about time
- ✅ Only 4 options = not overwhelming

### Option B: Detailed (More Granular)
```dart
enum PostAge {
  lastHour,     // "Last Hour"
  last12Hours,  // "Last 12 Hours"
  today,        // "Today" (24h)
  last3Days,    // "Last 3 Days"
  thisWeek,     // "This Week" (7d)
  thisMonth,    // "This Month" (30d)
  all,          // "All Time"
}
```

**Pros:** More control for power users
**Cons:** Too many options, analysis paralysis

### Option C: Trending Focus
```dart
enum PostAge {
  trending,     // "Trending Now" - Last 6 hours + engagement score
  today,        // "Today"
  thisWeek,     // "This Week"
  all,          // "All Time"
}
```

**Pros:** Gamified, discovery-focused
**Cons:** Requires engagement metrics, more complex

---

## 🎨 UI/UX Design Recommendations

### 1. **Add Third Column to Filter Sheet** (RECOMMENDED)

Your current filter sheet has 2 columns (Category + Goal). Add a 3rd for Date Range:

```
┌─────────────────────────────────────────┐
│  Filter Posts              Clear    ✕   │
├─────────────┬─────────────┬─────────────┤
│  Category   │   Goal      │  Date Range │
│  📁 Icon    │   🎯 Icon   │  📅 Icon    │
├─────────────┼─────────────┼─────────────┤
│ ○ All       │ ○ All       │ ● All Time  │
│ ○ Tech      │ ○ Funding   │ ○ This Week │
│ ○ Health    │ ○ Team      │ ○ Today     │
│ ○ Finance   │ ○ Skills    │ ○ This Month│
│ ...         │ ...         │             │
└─────────────┴─────────────┴─────────────┘
```

**Code Structure:**
```dart
class FilterSheet extends StatefulWidget {
  final String? initialCategory;
  final String? initialGoal;
  final PostAge? initialDateRange; // NEW

  // Returns: {category, goal, dateRange}
}
```

### 2. **Alternative: Horizontal Chips Below Search** (Quick Access)

Add quick-access date chips below the search bar:

```
┌──────────────────────────────────────────┐
│  🔍 Search...            🔽 ⚙️  🔔  👤   │
├──────────────────────────────────────────┤
│  [📅 Today] [This Week] [This Month]     │
└──────────────────────────────────────────┘
```

**Pros:**
- ✅ Instant access (no sheet opening)
- ✅ Common filters readily available
- ✅ Less cognitive load

**Cons:**
- ❌ Takes up header space
- ❌ Less organized than sheet

### 3. **Hybrid Approach** (BEST UX)

- **Quick Chips:** Today, This Week (most common)
- **Full Sheet:** All options including "This Month", "All Time"

---

## 🔧 Technical Implementation

### Step 1: Update Data Models

```dart
// lib/core/constants.dart or create new file
enum PostAge {
  all('all', 'All Time'),
  today('today', 'Today'),
  thisWeek('week', 'This Week'),
  thisMonth('month', 'This Month');

  const PostAge(this.value, this.label);
  final String value;
  final String label;
}
```

### Step 2: Update Filter Sheet

```dart
// lib/app/widgets/filter_sheet.dart

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    this.initialCategory,
    this.initialGoal,
    this.initialDateRange, // NEW
  });

  final String? initialCategory;
  final String? initialGoal;
  final PostAge? initialDateRange; // NEW
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedCategory;
  String? _selectedGoal;
  PostAge _selectedDateRange = PostAge.all; // NEW

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedGoal = widget.initialGoal;
    _selectedDateRange = widget.initialDateRange ?? PostAge.all; // NEW
  }

  // Add third column in Row
  Widget build(BuildContext context) {
    return Container(
      // ... existing code
      child: Row(
        children: [
          // Existing Category column
          Expanded(child: _buildCategoryColumn()),
          
          // Existing Goal column
          Expanded(child: _buildGoalColumn()),
          
          // NEW: Date Range column
          Expanded(child: _buildDateRangeColumn()),
        ],
      ),
    );
  }

  Widget _buildDateRangeColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        // Options
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: PostAge.values.map((age) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FilterOption(
                  label: age.label,
                  isSelected: _selectedDateRange == age,
                  onTap: () => setState(() => _selectedDateRange = age),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Update return value
  void _applyFilters() {
    Navigator.pop(context, {
      'category': _selectedCategory,
      'goal': _selectedGoal,
      'dateRange': _selectedDateRange.value, // NEW
    });
  }
}
```

### Step 3: Update Feed Service

```dart
// lib/features/feed/feed_service.dart

Future<List<PostModel>> fetchPosts({
  String? category,
  String? goal,
  String? search,
  String? dateRange, // NEW: 'today', 'week', 'month', 'all'
  int limit = 20,
  int offset = 0,
  bool forceRefresh = false,
}) async {
  // Check cache (include dateRange in cache key)
  if (!forceRefresh) {
    final cached = _cache.get(
      category: category,
      goal: goal,
      search: search,
      dateRange: dateRange, // NEW
      offset: offset,
    );
    if (cached != null) return cached;
  }

  var q = _s.from('posts').select('...');

  // Apply existing filters
  if (category != null && category.isNotEmpty) {
    q = q.eq('category', category);
  }
  if (goal != null && goal.isNotEmpty) {
    q = q.eq('post_goal', goal);
  }
  if (search != null && search.trim().isNotEmpty) {
    q = q.or('...');
  }

  // NEW: Apply date range filter
  if (dateRange != null && dateRange != 'all') {
    final cutoffDate = _getDateRangeCutoff(dateRange);
    q = q.gte('created_at', cutoffDate.toIso8601String());
  }

  final data = await q
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);

  // ... rest of existing code

  // Cache with dateRange
  _cache.put(
    category: category,
    goal: goal,
    search: search,
    dateRange: dateRange, // NEW
    offset: offset,
    posts: posts,
  );

  return posts;
}

// Helper method
DateTime _getDateRangeCutoff(String dateRange) {
  final now = DateTime.now();
  switch (dateRange) {
    case 'today':
      return now.subtract(const Duration(hours: 24));
    case 'week':
      return now.subtract(const Duration(days: 7));
    case 'month':
      return now.subtract(const Duration(days: 30));
    default:
      return DateTime(2020); // Far past = all posts
  }
}
```

### Step 4: Update Feed Cache

```dart
// lib/core/cache/feed_cache.dart

String _generateKey({
  String? category,
  String? goal,
  String? search,
  String? dateRange, // NEW
  int offset = 0,
}) {
  final parts = <String>[];
  if (category != null) parts.add('cat:$category');
  if (goal != null) parts.add('goal:$goal');
  if (search != null && search.isNotEmpty) {
    parts.add('search:${search.toLowerCase()}');
  }
  if (dateRange != null && dateRange != 'all') { // NEW
    parts.add('date:$dateRange');
  }
  parts.add('offset:$offset');
  return parts.join('|');
}

// Update get() and put() methods to include dateRange parameter
List<PostModel>? get({
  String? category,
  String? goal,
  String? search,
  String? dateRange, // NEW
  int offset = 0,
}) {
  final key = _generateKey(
    category: category,
    goal: goal,
    search: search,
    dateRange: dateRange, // NEW
    offset: offset,
  );
  // ... rest of existing logic
}

void put({
  String? category,
  String? goal,
  String? search,
  String? dateRange, // NEW
  int offset = 0,
  required List<PostModel> posts,
}) {
  final key = _generateKey(
    category: category,
    goal: goal,
    search: search,
    dateRange: dateRange, // NEW
    offset: offset,
  );
  // ... rest of existing logic
}
```

### Step 5: Update Feed Page

```dart
// lib/features/feed/feed_page.dart

class FeedPageState extends State<FeedPage> {
  String? _categoryFilter;
  String? _goalFilter;
  PostAge _dateRangeFilter = PostAge.all; // NEW
  
  Future<void> _load({bool reset = false}) async {
    // ... existing code
    
    final data = await _svc.fetchPosts(
      category: _categoryFilter,
      goal: _goalFilter,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
      dateRange: _dateRangeFilter.value, // NEW
      limit: _limit,
      offset: _offset,
    );
    
    // ... rest
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => FilterSheet(
        initialCategory: _categoryFilter,
        initialGoal: _goalFilter,
        initialDateRange: _dateRangeFilter, // NEW
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _categoryFilter = result['category'];
        _goalFilter = result['goal'];
        _dateRangeFilter = PostAge.values.firstWhere(
          (age) => age.value == result['dateRange'],
          orElse: () => PostAge.all,
        ); // NEW
      });
      _load(reset: true);
    }
  }

  // Update filter summary
  String _getFilterSummary() {
    final parts = <String>[];
    if (_categoryFilter != null) {
      parts.add(_formatCategoryLabel(_categoryFilter!));
    }
    if (_goalFilter != null) {
      parts.add(_formatGoalLabel(_goalFilter!));
    }
    if (_dateRangeFilter != PostAge.all) { // NEW
      parts.add(_dateRangeFilter.label);
    }
    return parts.join(' + ');
  }
}
```

---

## 📊 Database Optimization Considerations

### Index for Performance

Add database index for efficient date range queries:

```sql
-- Create index on created_at for faster date filtering
CREATE INDEX IF NOT EXISTS idx_posts_created_at 
ON posts(created_at DESC);

-- Composite index for common filter combinations
CREATE INDEX IF NOT EXISTS idx_posts_category_date 
ON posts(category, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_posts_goal_date 
ON posts(post_goal, created_at DESC);
```

**Impact:**
- Without index: Full table scan (slow as posts grow)
- With index: Fast binary search (consistent performance)

---

## 🎯 Quick Access Chips (Optional Enhancement)

Add chips below search for most common filters:

```dart
// lib/app/widgets/app_header.dart

Widget _buildQuickDateChips() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickDateChip(
            label: 'Today',
            isSelected: _selectedDateRange == PostAge.today,
            onTap: () => _onDateRangeChanged(PostAge.today),
          ),
          const SizedBox(width: 8),
          _QuickDateChip(
            label: 'This Week',
            isSelected: _selectedDateRange == PostAge.thisWeek,
            onTap: () => _onDateRangeChanged(PostAge.thisWeek),
          ),
          const SizedBox(width: 8),
          _QuickDateChip(
            label: 'All Time',
            isSelected: _selectedDateRange == PostAge.all,
            onTap: () => _onDateRangeChanged(PostAge.all),
          ),
        ],
      ),
    ),
  );
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
```

---

## 🎨 UX Enhancements

### 1. **Show Post Age in Cards**

Display relative time on each post:
```dart
// In enhanced_post_card.dart
Text(
  TimeFormatter.format(post.createdAt), // "2h ago", "3d ago"
  style: TextStyle(color: Colors.grey[600], fontSize: 12),
)
```

### 2. **Empty State for Filtered Views**

```dart
if (displayPosts.isEmpty && _dateRangeFilter != PostAge.all) {
  return EmptyState(
    icon: Icons.calendar_today,
    title: 'No posts in ${_dateRangeFilter.label}',
    subtitle: 'Try a different time range or remove filters',
    action: TextButton(
      onPressed: () {
        setState(() => _dateRangeFilter = PostAge.all);
        _load(reset: true);
      },
      child: Text('Show All Posts'),
    ),
  );
}
```

### 3. **Smart Default Based on Activity**

```dart
// If user has been inactive for days, default to "This Week" or "This Month"
PostAge _getSmartDefaultDateRange() {
  final lastVisit = _prefs.getLastVisitTime();
  final daysSinceVisit = DateTime.now().difference(lastVisit).inDays;
  
  if (daysSinceVisit > 7) return PostAge.thisMonth;
  if (daysSinceVisit > 2) return PostAge.thisWeek;
  return PostAge.all; // Active user sees everything
}
```

---

## 📈 Analytics Tracking

Track which filters users prefer:

```dart
void _trackFilterUsage() {
  analytics.logEvent('feed_filter_applied', parameters: {
    'category': _categoryFilter ?? 'none',
    'goal': _goalFilter ?? 'none',
    'date_range': _dateRangeFilter.value,
    'has_search': _search.isNotEmpty,
  });
}
```

---

## ✅ Final Recommendation: Implementation Priority

### Phase 1: Core Functionality (Do This First)
1. ✅ Add `PostAge` enum with 4 options (Today, This Week, This Month, All)
2. ✅ Add third column to FilterSheet
3. ✅ Update FeedService with date filtering
4. ✅ Update cache key generation
5. ✅ Add database index for `created_at`

### Phase 2: UX Polish (After Testing)
6. ✅ Add quick-access chips below search
7. ✅ Empty state for filtered views
8. ✅ Filter summary in header

### Phase 3: Advanced (Optional)
9. ⚡ Smart default based on last visit
10. ⚡ "Trending Now" algorithm (engagement-based)
11. ⚡ Custom date picker for power users

---

## 🎯 Why This Approach is Best

1. **User-Friendly:** Simple language (Today, This Week) instead of technical (12h, 3d)
2. **Performance:** Efficient database queries with indexes
3. **Scalable:** Easy to add more time ranges later
4. **Consistent:** Matches existing filter UI pattern
5. **Cache-Friendly:** Integrates with existing cache system
6. **Mobile-Optimized:** Doesn't add UI clutter

---

## 📝 Summary

**Best Option:** Add third column to FilterSheet with:
- All Time (default)
- Today
- This Week  
- This Month

**Quick Win:** Add horizontal chips below search for Today/This Week

**Database:** Add index on `created_at` column

**Timeline:** ~2-3 hours for core implementation

Would you like me to implement this now, starting with Phase 1?

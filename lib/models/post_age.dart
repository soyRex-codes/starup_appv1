/// Enum for post age/date range filtering options
enum PostAge {
  all('all', 'All Time'),
  today('today', 'Today'),
  thisWeek('week', 'This Week'),
  thisMonth('month', 'This Month');

  const PostAge(this.value, this.label);
  
  /// Backend filter value
  final String value;
  
  /// Display label for UI
  final String label;

  /// Get PostAge from string value
  static PostAge fromValue(String value) {
    return PostAge.values.firstWhere(
      (age) => age.value == value,
      orElse: () => PostAge.all,
    );
  }

  /// Check if this is the default (no filter applied)
  bool get isDefault => this == PostAge.all;
}

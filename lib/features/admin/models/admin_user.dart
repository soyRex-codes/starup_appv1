class AdminUser {
  final String id;
  final String email;
  final String name;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isAdmin,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? json['full_name'] ?? 'Unknown',
      isAdmin: json['is_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      lastLoginAt: DateTime.parse(json['last_login_at'] ?? json['created_at']),
    );
  }
}

enum AdminAction {
  viewPosts,
  editPosts,
  deletePosts,
  manageUsers,
  viewAnalytics,
  moderateContent,
}
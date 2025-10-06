import 'package:flutter/material.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/app/auth_gate.dart';
import 'package:foundervers/features/auth/auth_service.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/features/post_creation/post_detail_page.dart';
import 'package:foundervers/models/post.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use AuthService to access current user via Firebase under the hood
    final u = AuthService.instance.currentUser;
    final svc = PostService();
    final dateFmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u?.userMetadata?['name'] ?? u?.email ?? 'Me',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (u != null)
              FutureBuilder<DateTime?>(
                future: svc.fetchUserCreatedAt(u.id),
                builder: (context, snap) {
                  final created = snap.data;
                  final since = (created != null)
                      ? 'Member since ${dateFmt.format(created)}'
                      : '';
                  return Text(
                      since.isEmpty ? 'UID: ${u.id}' : '$since\nUID: ${u.id}',
                      style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            const SizedBox(height: 16),
            Expanded(
              child: u == null
                  ? const Center(child: Text('Sign in to view your posts'))
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      future: svc.fetchMyPosts(userId: u.id, limit: 50),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        final items = snapshot.data ?? const [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.post_add_outlined),
                                    const SizedBox(width: 8),
                                    Text('Posts: ${items.length}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            FutureBuilder<Map<String, int>>(
                              future: svc.fetchGoalDistribution(userId: u.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: LinearProgressIndicator(),
                                  );
                                }
                                final dist = snapshot.data ?? const {};
                                if (dist.isEmpty) {
                                  return const SizedBox();
                                }
                                final total =
                                    dist.values.fold<int>(0, (a, b) => a + b);
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Goal Distribution',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 8),
                                        ...dist.entries.map((e) {
                                          final pct = total == 0
                                              ? 0
                                              : (e.value / total * 100)
                                                  .toStringAsFixed(1);
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            child: Row(
                                              children: [
                                                Expanded(child: Text(e.key)),
                                                Text('${e.value}  ($pct%)'),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: items.isEmpty
                                  ? const Center(child: Text('No posts yet'))
                                  : ListView.separated(
                                      itemCount: items.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final p = items[i];
                                        final title =
                                            (p['title'] ?? '').toString();
                                        final cat =
                                            (p['category'] ?? '').toString();
                                        final created = DateTime.tryParse(
                                            p['created_at']?.toString() ?? '');

                                        return ListTile(
                                          title: Text(
                                            title.isEmpty ? 'Untitled' : title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text([
                                            if (cat.isNotEmpty) '#$cat',
                                            if (created != null)
                                              DateFormat.MMMd().format(created),
                                          ].join(' · ')),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                          ),
                                          onTap: () {
                                            // Convert raw data to PostModel and navigate to detail page
                                            try {
                                              final postModel =
                                                  PostModel.fromJson(p);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PostDetailPage(
                                                          post: postModel),
                                                ),
                                              );
                                            } catch (e) {
                                              // Show error if conversion fails
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error opening post: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // ignore: use_build_context_synchronously
                  _performSignOut(context);
                }
              },
              icon: AppIcons.logout(size: 22),
              label: const Text('Sign out'),
            )
          ],
        ),
      ),
    );
  }

  static Future<void> _performSignOut(BuildContext context) async {
    // Store context references before any async operations
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await AuthService.instance.signOut();

      // Navigate back to auth gate (which will show sign in page)
      navigator.pop(); // Dismiss loading dialog
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      // Dismiss loading dialog on error
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

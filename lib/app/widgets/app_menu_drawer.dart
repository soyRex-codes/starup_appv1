import 'package:flutter/material.dart';
import 'package:foundervers/features/ecosystem/my_applications_page.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:foundervers/features/profile/unified_profile_page.dart';
import 'package:foundervers/features/about/about_us_page.dart';
import 'package:foundervers/features/settings/settings_page.dart';
import 'package:foundervers/features/help_support/help_support_page.dart';
import 'package:foundervers/features/admin/admin_dashboard.dart';
import 'package:foundervers/features/admin/services/admin_auth_service.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/features/premium/premium_payment_page.dart';
import 'package:foundervers/services/premium_subscription_service.dart';

/// Main menu drawer - slides in from right side
/// Provides navigation to all major app sections
class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _MenuAction(
                    icon: AppIcons.profile(size: 22),
                    label: 'Profile & Account',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UnifiedProfilePage(),
                        ),
                      );
                    },
                  ),

                  _MenuAction(
                    icon: const Icon(Icons.business_center_outlined, size: 22),
                    label: 'My Business Applications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyApplicationsPage(),
                        ),
                      );
                    },
                  ),

                  // Premium Subscription (Hidden on iOS, visible on Web and Android)
                  if (kIsWeb || !Platform.isIOS)
                    FutureBuilder<bool>(
                      future: PremiumSubscriptionService().checkPremiumStatus(),
                      builder: (context, snapshot) {
                        final isPremium = snapshot.data ?? false;
                        return _MenuAction(
                          icon: Icon(
                            Icons.workspace_premium,
                            size: 22,
                            color: isPremium
                                ? Colors.amber.shade700
                                : const Color(0xFF8B4513),
                          ),
                          label: isPremium
                              ? 'Premium Member ✓'
                              : 'Upgrade to Premium',
                          labelColor: isPremium ? Colors.amber.shade700 : null,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PremiumPaymentPage(isAnnual: true),
                              ),
                            );
                          },
                        );
                      },
                    ),

                  const Divider(height: 1),

                  // Admin Dashboard - only for admins
                  FutureBuilder<bool>(
                    future: AdminAuthService.isCurrentUserAdmin(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Column(
                          children: [
                            const Divider(height: 1),
                            _MenuAction(
                              icon: const Icon(
                                Icons.admin_panel_settings,
                                size: 22,
                                color: Color(0xFFFF5722),
                              ),
                              label: 'Admin Dashboard',
                              labelColor: const Color(0xFFFF5722),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AdminDashboard(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _MenuAction(
                    icon: AppIcons.about(size: 22),
                    label: 'About FounderVers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AboutUsPage(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  _MenuAction(
                    icon: AppIcons.settings(size: 22),
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  _MenuAction(
                    icon: AppIcons.help(size: 22),
                    label: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer with version info
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'FounderVers v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual menu item widget
class _MenuAction extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

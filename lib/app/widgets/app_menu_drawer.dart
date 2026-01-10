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
import 'package:foundervers/app/theme.dart';

/// Main menu drawer - slides in from right side
/// Provides navigation to all major app sections
class AppMenuDrawer extends StatefulWidget {
  const AppMenuDrawer({super.key});

  @override
  State<AppMenuDrawer> createState() => _AppMenuDrawerState();
}

class _AppMenuDrawerState extends State<AppMenuDrawer> {
  late Future<bool> _premiumFuture;
  late Future<bool> _adminFuture;

  @override
  void initState() {
    super.initState();
    _premiumFuture = PremiumSubscriptionService().checkPremiumStatus();
    _adminFuture = AdminAuthService.isCurrentUserAdmin();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.bg : AppColors.bg;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final iconColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    
    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _MenuAction(
                    icon: AppIcons.profile(size: 22, color: iconColor),
                    label: 'Profile & Account',
                    isDark: isDark,
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
                    icon: Icon(Icons.business_center_outlined, size: 22, color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary),
                    label: 'My Business Applications',
                    isDark: isDark,
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
                      future: _premiumFuture,
                      builder: (context, snapshot) {
                        final isPremium = snapshot.data ?? false;
                        return _MenuAction(
                          icon: Icon(
                            Icons.workspace_premium,
                            size: 22,
                            color: isPremium
                                ? Colors.amber.shade700
                                : (isDark ? AppColorsDark.textSecondary : const Color(0xFF8B4513)),
                          ),
                          label: isPremium
                              ? 'Premium Member ✓'
                              : 'Upgrade to Premium',
                          labelColor: isPremium ? Colors.amber.shade700 : null,
                          isDark: isDark,
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

                  Divider(height: 1, color: borderColor),

                  // Admin Dashboard - only for admins
                  FutureBuilder<bool>(
                    future: _adminFuture,
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Column(
                          children: [
                            Divider(height: 1, color: borderColor),
                            _MenuAction(
                              icon: const Icon(
                                Icons.admin_panel_settings,
                                size: 22,
                                color: Color(0xFFFF5722),
                              ),
                              label: 'Admin Dashboard',
                              labelColor: const Color(0xFFFF5722),
                              isDark: isDark,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AdminDashboard(),
                                  ),
                                );
                              },
                            ),
                            Divider(height: 1, color: borderColor),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _MenuAction(
                    icon: AppIcons.about(size: 22, color: iconColor),
                    label: 'About FounderVers',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AboutUsPage(),
                        ),
                      );
                    },
                  ),

                  Divider(height: 1, color: borderColor),

                  _MenuAction(
                    icon: AppIcons.settings(size: 22, color: iconColor),
                    label: 'Settings',
                    isDark: isDark,
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
                    icon: AppIcons.help(size: 22, color: iconColor),
                    label: 'Help & Support',
                    isDark: isDark,
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
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'FounderVers v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
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
  final bool isDark;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    
    return ListTile(
      leading: icon,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: labelColor ?? textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

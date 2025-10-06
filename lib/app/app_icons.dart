import 'package:flutter/widgets.dart';

// Centralized access to raster icon assets. Keep names semantic.
class AppIcons {
  AppIcons._();

  static const String _path = 'lib/icons';

  static Image asset(String fileName, {double? size, Color? color}) =>
      Image.asset(
        '$_path/$fileName',
        width: size,
        height: size,
        color: color,
        filterQuality: FilterQuality.medium,
      );

  // Commonly used icons as helpers
  static Image feed({double? size}) => asset('home.png', size: size);
  static Image appLogo({double? size}) =>
      asset('foundrVers_logo.png', size: size);
  static Image chat({double? size}) => asset('chat.png', size: size);
  // Global community chat icon (bottom nav)
  static Image globalChat({double? size}) =>
      asset('Global_chat.png', size: size);
  static Image dms({double? size}) => asset('icon_inbox.png', size: size);
  static Image profile({double? size}) => asset('profile.png', size: size);
  static Image search({double? size}) => asset('search.png', size: size);
  static Image filter({double? size}) => asset('filter.png', size: size);
  // Post creation icon
  static Image post({double? size}) => asset('post.png', size: size);
  @Deprecated('Use AppIcons.post instead for clarity')
  static Image add({double? size}) => post(size: size); // backwards compat
  static Image delete({double? size}) => asset('delete.png', size: size);
  static Image edit({double? size}) => asset('edit.png', size: size);
  static Image money({double? size}) => asset('invest_icon.png', size: size);
  static Image collab({double? size}) => asset('collab_icon.png', size: size);
  static Image contact({double? size}) => asset('contact_icon.png', size: size);
  static Image refresh({double? size}) =>
      asset('dashboard.png', size: size); // placeholder
  static Image send({double? size}) =>
      asset('submit.png', size: size); // Using submit as send icon
  static Image logout({double? size}) => asset('logout.png', size: size);
  static Image warning({double? size}) => asset('warning.png', size: size);
  static Image upload({double? size}) => asset('upload.png', size: size);
  static Image menu({double? size}) => asset('Menu.png', size: size);
  static Image settings({double? size}) => asset('settings.png', size: size);
  static Image backArrow({double? size}) => asset('back-arrow.png', size: size);
  static Image analytics({double? size}) => asset('analytics.png', size: size);
  static Image apply({double? size}) => asset('apply.png', size: size);
  static Image business({double? size}) => asset('business.png', size: size);
  static Image document({double? size}) => asset('document.png', size: size);
  static Image email({double? size}) => asset('email.png', size: size);
  static Image error({double? size}) => asset('error.png', size: size);
  static Image feedback({double? size}) => asset('feedback.png', size: size);
  static Image google({double? size}) => asset('google.png', size: size);
  static Image info({double? size}) => asset('info.png', size: size);
  static Image invest({double? size}) => asset('invest_icon.png', size: size);
  static Image investHistory({double? size}) =>
      asset('investment history.png', size: size);
  static Image login({double? size}) => asset('login.png', size: size);
  static Image moderation({double? size}) =>
      asset('moderation.png', size: size);
  static Image notification({double? size}) =>
      asset('notification.png', size: size);
  static Image scrollUp({double? size}) => asset('scroll-up.png', size: size);
  static Image security({double? size}) => asset('security.png', size: size);
  static Image startupNest({double? size}) =>
      asset('startupNest.png', size: size);
  static Image submit({double? size}) => asset('submit.png', size: size);
  static Image success({double? size}) =>
      asset('success.png', size: size, color: null);
  static Image suggest({double? size}) => asset('suggest.png', size: size);
  static Image close({double? size}) => asset('delete.png', size: size);
  static Image circle({double? size}) => asset('info.png', size: size);
  static Image about({double? size}) => asset('about.png', size: size);
  static Image help({double? size}) => asset('feedback.png', size: size);
}

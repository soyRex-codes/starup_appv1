import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const primary = Color(0xFF1F4D3A);
  static const primarySoft = Color(0xFFDCE7DF);
  static const bg = Color(0xFFF7F4ED);
  static const card = Color(0xFFFFFFFF);
  static const accent = Color(0xFFD96B4B);
  static const accentDark = Color(0xFFA84730);
  static const danger = Color(0xFFBA3F3F);
  static const textPrimary = Color(0xFF18201D);
  static const textSecondary = Color(0xFF66736C);
  static const border = Color(0xFFDDE3DD);
  static const subtleFill = Color(0xFFEEF3EF);
}

class AppColorsDark {
  AppColorsDark._();
  static const primary = Color(0xFF78B89B);
  static const primarySoft = Color(0xFF203A30);
  static const bg = Color(0xFF0E1714);
  static const card = Color(0xFF17211D);
  static const accent = Color(0xFFE68A70);
  static const accentDark = Color(0xFFD96B4B);
  static const danger = Color(0xFFFF8179);
  static const textPrimary = Color(0xFFF2F5F1);
  static const textSecondary = Color(0xFFAAB8B0);
  static const border = Color(0xFF2A3A33);
  static const subtleFill = Color(0xFF1D2B25);
}

class TeraiBreakpoints {
  TeraiBreakpoints._();
  static const double mobile = 700;
  static const double desktop = 1060;
}

ThemeData buildAppTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final primary = dark ? AppColorsDark.primary : AppColors.primary;
  final background = dark ? AppColorsDark.bg : AppColors.bg;
  final surface = dark ? AppColorsDark.card : AppColors.card;
  final text = dark ? AppColorsDark.textPrimary : AppColors.textPrimary;
  final muted = dark ? AppColorsDark.textSecondary : AppColors.textSecondary;
  final border = dark ? AppColorsDark.border : AppColors.border;
  final subtle = dark ? AppColorsDark.subtleFill : AppColors.subtleFill;
  final accent = dark ? AppColorsDark.accent : AppColors.accent;
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    surface: surface,
    error: dark ? AppColorsDark.danger : AppColors.danger,
  ).copyWith(
    primary: primary,
    onPrimary: dark ? const Color(0xFF10251D) : Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: text,
    outline: border,
    outlineVariant: border,
  );
  final base = ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
  );
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    scaffoldBackgroundColor: background,
    cardColor: surface,
    dividerColor: border,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: TextStyle(
          color: text,
          fontSize: 36,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1),
      headlineMedium: TextStyle(
          color: text,
          fontSize: 28,
          height: 1.16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7),
      titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35),
      titleMedium: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15),
      bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.45),
      bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.4),
      labelLarge: const TextStyle(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: inputBorder(border),
      enabledBorder: inputBorder(border),
      focusedBorder: inputBorder(primary, 1.6),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 1.6),
      hintStyle: TextStyle(color: muted, fontSize: 14),
      labelStyle: TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: muted,
        hoverColor: primary.withValues(alpha: 0.08),
        highlightColor: primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      side: BorderSide(color: border),
      backgroundColor: subtle,
      selectedColor: primary.withValues(alpha: 0.13),
      labelStyle:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primary.withValues(alpha: 0.13),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.13),
      selectedIconTheme: IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle:
          TextStyle(color: primary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle:
          TextStyle(color: muted, fontWeight: FontWeight.w500),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: primary,
      unselectedLabelColor: muted,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      indicator: BoxDecoration(
          color: primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
    popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: TextStyle(color: background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: dark ? const Color(0xFF10251D) : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
        thumbColor: WidgetStatePropertyAll(muted.withValues(alpha: 0.35))),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

class AnimatedShimmer extends StatefulWidget {
  const AnimatedShimmer(
      {super.key, required this.height, this.width, this.radius = 12});
  final double height;
  final double? width;
  final double radius;

  @override
  State<AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final position = _controller.value * 2 - 1;
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              colors: dark
                  ? const [
                      Color(0xFF1D2B25),
                      Color(0xFF30433A),
                      Color(0xFF1D2B25)
                    ]
                  : const [
                      Color(0xFFEEF3EF),
                      Color(0xFFDDE7DF),
                      Color(0xFFEEF3EF)
                    ],
              stops: [0, (position + 1) / 2, 1],
            ),
          ),
        );
      },
    );
  }
}

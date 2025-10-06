import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  // Logo-inspired orange/yellow color scheme
  static const Color primary = Color(0xFFFF6B35); // vibrant orange from logo
  static const Color primarySoft = Color(0xFFFFF4F0); // very light orange tint
  static const Color bg = Color(0xFFFFFAF7); // warm white background
  static const Color card = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFFFA726); // golden yellow from logo
  static const Color accentDark = Color(0xFFE65100); // deep orange for emphasis
  static const Color danger = Color(0xFFE53935);
  static const Color textPrimary = Color(0xFF1E1E24);
  static const Color textSecondary =
      Color(0xFF8B4513); // warm brown for secondary text
  static const Color border = Color(0xFFFFDDD4); // soft orange-tinted border
  static const Color subtleFill = Color(0xFFFFF7F3); // subtle orange fill
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary, surface: AppColors.bg),
    useMaterial3: true,
    fontFamily: null,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary),
      foregroundColor: AppColors.textPrimary,
    ),
    chipTheme: base.chipTheme.copyWith(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      side: const BorderSide(color: AppColors.border),
      backgroundColor: AppColors.subtleFill,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textTheme: base.textTheme.copyWith(
      bodyMedium: base.textTheme.bodyMedium
          ?.copyWith(color: AppColors.textPrimary, height: 1.35),
      bodySmall:
          base.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: AppColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    ),
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
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final gradientPosition = _c.value * 2 - 1; // -1 to 1
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1, -0.3),
              end: Alignment(1, 0.3),
              colors: const [
                Color(0xFFF2EDF9),
                Color(0xFFE3DCF3),
                Color(0xFFF2EDF9)
              ],
              stops: [0, (gradientPosition + 1) / 2, 1],
            ),
          ),
        );
      },
    );
  }
}

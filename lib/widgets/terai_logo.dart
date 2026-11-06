import 'package:flutter/material.dart';

/// Terai logo widget for consistent usage throughout the app.
class TeraiLogo extends StatelessWidget {
  const TeraiLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.fitWidth,
  });

  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/icons/Terai.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 24,
          width: width ?? 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: Colors.white,
            size: 16,
          ),
        );
      },
    );
  }
}

/// Terai logo specifically for app bars.
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeraiLogo(
      height: 40,
      width: 96,
    );
  }
}

/// Terai logo for splash screens and large displays.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeraiLogo(
      height: 135,
      width: 300,
    );
  }
}

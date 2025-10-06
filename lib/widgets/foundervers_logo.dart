import 'package:flutter/material.dart';

/// FounderVers logo widget for consistent usage throughout the app
class FounderVersLogo extends StatelessWidget {
  const FounderVersLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/icons/foundervers.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image fails to load
        return Container(
          height: height ?? 24,
          width: width ?? 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business,
            color: Colors.white,
            size: 16,
          ),
        );
      },
    );
  }
}

/// FounderVers logo specifically for app bars
class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const FounderVersLogo(
      height: 32,
      width: 32,
    );
  }
}

/// FounderVers logo for splash screens or large displays
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const FounderVersLogo(
      height: 120,
      width: 120,
    );
  }
}
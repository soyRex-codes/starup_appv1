import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Full screen image viewer with pinch-to-zoom
/// Used for viewing profile pictures and other images at full size
class FullImageViewer extends StatelessWidget {
  const FullImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.userName,
  });

  final String imageUrl;
  final String? heroTag;
  final String? userName;

  /// Show the full image viewer as a modal
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    String? userName,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullImageViewer(
            imageUrl: imageUrl,
            heroTag: heroTag,
            userName: userName,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: userName != null
            ? Text(
                userName!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: heroTag != null
              ? Hero(
                  tag: heroTag!,
                  child: _buildPhotoView(context),
                )
              : _buildPhotoView(context),
        ),
      ),
    );
  }

  Widget _buildPhotoView(BuildContext context) {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(imageUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      initialScale: PhotoViewComputedScale.contained,
      backgroundDecoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }
}

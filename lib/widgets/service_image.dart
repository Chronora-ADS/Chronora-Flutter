import 'package:chronora/core/utils/service_image_resolver.dart';
import 'package:flutter/material.dart';

class ServiceImage extends StatelessWidget {
  final String? imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final Color iconColor;

  const ServiceImage({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = const Color(0xFFD9DED4),
    this.iconColor = Colors.black45,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = ServiceImageResolver.tryDecodeBytes(imageSource);
    final networkUrl = ServiceImageResolver.resolveNetworkUrl(imageSource);

    Widget child;
    if (imageBytes != null) {
      child = Image.memory(
        imageBytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.broken_image),
      );
    } else if (networkUrl != null) {
      child = Image.network(
        networkUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(Icons.broken_image),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes == null
                    ? null
                    : loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!,
              ),
            ),
          );
        },
      );
    } else {
      child = _buildPlaceholder(Icons.image_outlined);
    }

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 40,
        color: iconColor,
      ),
    );
  }
}

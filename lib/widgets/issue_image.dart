import 'package:flutter/material.dart';
import '../services/local_image_service.dart';
import '../theme.dart';

class IssueImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const IssueImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(Icons.image_not_supported_outlined);
    }

    if (imageUrl.startsWith('local://')) {
      final bytes = LocalImageService.getImage(imageUrl);
      if (bytes == null) {
        return _buildPlaceholder(Icons.image_not_supported_outlined, subtitle: 'Local cache cleared');
      }
      return Image.memory(
        bytes,
        height: height,
        width: width,
        fit: fit,
      );
    }

    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoading();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(Icons.broken_image_outlined);
      },
    );
  }

  Widget _buildPlaceholder(IconData icon, {String? subtitle}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textLight, size: 32),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppTheme.textLight, fontSize: 8)),
          ]
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: height,
      width: width,
      color: AppTheme.backgroundLight,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

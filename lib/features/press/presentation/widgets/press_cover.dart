import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';

class PressCover extends StatelessWidget {
  const PressCover({
    super.key,
    required this.title,
    this.imageUrl,
    this.width,
    this.height,
    this.iconSize = 22,
    this.showTitle = false,
    this.borderRadius,
  });

  final String title;
  final String? imageUrl;
  final double? width;
  final double? height;
  final double iconSize;
  final bool showTitle;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(FhcRadius.md);
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: FhcColors.press,
        child: SizedBox(
          width: width,
          height: height,
          child: url.isEmpty
              ? _placeholder()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: FhcColors.press,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, color: FhcColors.white, size: iconSize),
          if (showTitle && title.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FhcColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

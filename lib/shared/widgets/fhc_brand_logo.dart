import 'package:flutter/material.dart';

import '../../core/design_system/fhc_tokens.dart';

/// Circular Family House of God mark used on splash, sign-in, and onboarding.
class FhcBrandLogo extends StatelessWidget {
  const FhcBrandLogo({
    super.key,
    this.size = 96,
    this.hero = false,
  });

  final double size;
  final bool hero;

  static const asset = 'assets/images/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/app_logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _LogoFallback(size: size),
      ),
    );

    return Semantics(
      image: true,
      label: "The Family House of God Int'l",
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: hero
                ? [
                    BoxShadow(
                      color: FhcColors.gold.withValues(alpha: 0.28),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: ClipOval(child: mark),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: FhcColors.navy,
      ),
      child: Icon(
        Icons.church_outlined,
        color: FhcColors.gold,
        size: size * 0.46,
      ),
    );
  }
}

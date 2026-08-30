import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../onboarding_actions.dart';

class OnboardingMultiplyScreen extends StatelessWidget {
  const OnboardingMultiplyScreen({super.key});

  static const _photoAsset = 'assets/images/multiply_home.png';

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          const SizedBox(height: 22),
          Text(
            fhcT(context, 'mobile.multiply', fallback: 'MULTIPLY'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: FhcColors.greenDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              fhcT(
                context,
                'onboarding.startChurchInHome',
                fallback: 'Start a Church\nin Your Home',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                height: 1.12,
                fontWeight: FontWeight.w700,
                color: FhcColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              fhcT(
                context,
                'onboarding.multiplyCopy',
                fallback:
                    'You can begin gathering people in the name of '
                    'Jesus Christ right where you are. We will guide, support '
                    'and equip you every step of the way.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: FhcColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _LivingRoomPhoto(asset: _photoAsset),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x66000000),
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                const Center(child: FhcBrandLogo(size: 92, hero: true)),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => fhcCompleteOnboarding(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: FhcColors.green,
                        foregroundColor: FhcColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FhcRadius.button),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          fhcT(
                            context,
                            'onboarding.getStarted',
                            fallback: 'GET STARTED',
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                            color: FhcColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: _MultiplyFooter(),
          ),
        ],
      ),
    );
  }
}

class _LivingRoomPhoto extends StatelessWidget {
  const _LivingRoomPhoto({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.12),
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF4A3428)),
    );
  }
}

class _MultiplyFooter extends StatelessWidget {
  const _MultiplyFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          TextButton(
            onPressed: () => fhcCompleteOnboarding(context),
            child: Text(
              fhcT(context, 'common.skip', fallback: 'Skip'),
              style: const TextStyle(
                color: FhcColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            Container(
              width: i == 2 ? 9 : 7,
              height: i == 2 ? 9 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              decoration: BoxDecoration(
                color: i == 2 ? FhcColors.green : FhcColors.border,
                shape: BoxShape.circle,
              ),
            ),
          const Spacer(),
          IconButton.filled(
            onPressed: () => fhcCompleteOnboarding(context),
            tooltip: fhcT(context, 'common.next', fallback: 'Next'),
            style: IconButton.styleFrom(
              backgroundColor: FhcColors.green,
              foregroundColor: FhcColors.white,
              minimumSize: const Size(52, 52),
              maximumSize: const Size(52, 52),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_forward, size: 22),
          ),
        ],
      ),
    );
  }
}

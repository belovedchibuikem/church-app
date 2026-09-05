import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';
import '../onboarding_actions.dart';

class OnboardingConnectScreen extends StatelessWidget {
  const OnboardingConnectScreen({super.key, this.embedded = false});

  final bool embedded;

  static const _copy =
      'Build meaningful relationships,\ngrow in faith, receive prayer\nand serve your community.';

  static const _rows = <(String, String)>[
    ('onboarding.joinChurch', 'Join a Church / Home Church'),
    ('onboarding.prayerSupport', 'Prayer & Support'),
    ('onboarding.discipleshipMentorship', 'Discipleship & Mentorship'),
    ('onboarding.communityFellowship', 'Community & Fellowship'),
  ];

  @override
  Widget build(BuildContext context) {
    final page = LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final compact = h < 760;
        final photoH = (h * 0.236).clamp(148.0, 198.0);
        final gap = compact ? 8.0 : 12.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 12 : 20, 20, 8),
          child: Column(
            children: [
              Text(
                fhcT(context, 'mobile.connect', fallback: 'CONNECT'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: FhcColors.greenDark,
                  ),
                ),
                SizedBox(height: gap * 0.7),
                Text(
                  fhcT(
                    context,
                    'onboarding.growServe',
                    fallback: 'Serve. Grow.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FhcColors.ink,
                  ),
                ),
                Text(
                  fhcT(
                    context,
                    'onboarding.makeAnImpact',
                    fallback: 'Make an Impact.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FhcColors.ink,
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  fhcT(context, 'onboarding.connectCopy', fallback: _copy),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: FhcColors.muted,
                  ),
                ),
                SizedBox(height: gap + 2),
                SizedBox(
                  height: photoH,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/connect_people.png',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const ColoredBox(
                            color: FhcColors.mint,
                            child: Center(child: FhcBrandLogo(size: 120)),
                          ),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final row in _rows)
                        _ConnectRow(labelKey: row.$1, fallback: row.$2),
                    ],
                  ),
                ),
                if (!embedded) const _ConnectFooter(),
              ],
            ),
          );
        },
      );
    if (embedded) return page;
    return FhcDevicePage(child: page);
  }
}

class _ConnectRow extends StatelessWidget {
  const _ConnectRow({required this.labelKey, required this.fallback});

  final String labelKey;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FhcColors.mint,
              shape: BoxShape.circle,
              border: Border.all(color: FhcColors.green, width: 1.25),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 18,
              color: FhcColors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              fhcT(context, labelKey, fallback: fallback),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectFooter extends StatelessWidget {
  const _ConnectFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          TextButton(
            onPressed: () => fhcCompleteOnboarding(context),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.muted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(context, 'common.skip', fallback: 'Skip'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: FhcColors.muted,
              ),
            ),
          ),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            Container(
              width: i == 1 ? 9 : 7,
              height: i == 1 ? 9 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              decoration: BoxDecoration(
                color: i == 1 ? FhcColors.green : FhcColors.border,
                shape: BoxShape.circle,
              ),
            ),
          const Spacer(),
          IconButton.filled(
            onPressed: () => fhcGo(context, '/onboarding/multiply'),
            tooltip: fhcT(context, 'common.next', fallback: 'Next'),
            style: IconButton.styleFrom(
              backgroundColor: FhcColors.green,
              foregroundColor: FhcColors.white,
              minimumSize: const Size(52, 52),
              maximumSize: const Size(52, 52),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_forward, size: 22),
          ),
        ],
      ),
    );
  }
}

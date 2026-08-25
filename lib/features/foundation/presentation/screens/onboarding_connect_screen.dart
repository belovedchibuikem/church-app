import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class OnboardingConnectScreen extends StatelessWidget {
  const OnboardingConnectScreen({super.key});

  static const _copy =
      'Build meaningful relationships,\ngrow in faith, receive prayer\nand serve your community.';

  static const _rows = <String>[
    'Join a Church / Home Church',
    'Prayer & Support',
    'Discipleship & Mentorship',
    'Community & Fellowship',
  ];

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 760;
          final photoH = (h * 0.236).clamp(148.0, 198.0);
          final gap = compact ? 8.0 : 12.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 12 : 20, 20, 8),
            child: Column(
              children: [
                const Text(
                  'CONNECT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: FhcColors.greenDark,
                  ),
                ),
                SizedBox(height: gap * 0.7),
                const Text(
                  'Grow. Serve.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FhcColors.ink,
                  ),
                ),
                const Text(
                  'Make an Impact.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: FhcColors.ink,
                  ),
                ),
                SizedBox(height: gap),
                const Text(
                  _copy,
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                          (context, error, stackTrace) =>
                              const ColoredBox(color: FhcColors.mint),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final label in _rows) _ConnectRow(label: label),
                    ],
                  ),
                ),
                const _ConnectFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectRow extends StatelessWidget {
  const _ConnectRow({required this.label});

  final String label;

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
              label,
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
            onPressed: () => fhcGo(context, '/language'),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.muted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: FhcColors.muted,
              ),
            ),
          ),
          const Spacer(),
          for (var i = 0; i < 4; i++)
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
            tooltip: 'Next',
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

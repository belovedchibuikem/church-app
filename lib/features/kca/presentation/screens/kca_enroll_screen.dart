import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaEnrollScreen extends StatelessWidget {
  const KcaEnrollScreen({super.key});

  void _pop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bullets = <(IconData, String)>[
      (
        Icons.menu_book_outlined,
        fhcT(
          context,
          'member.kca.twelveModules',
          fallback: '12 Powerful Modules',
        ),
      ),
      (
        Icons.groups_outlined,
        fhcT(
          context,
          'member.kca.mentorshipAccountability',
          fallback: 'Mentorship & Accountability',
        ),
      ),
      (
        Icons.assignment_turned_in_outlined,
        fhcT(
          context,
          'member.kca.assignmentsEvidence',
          fallback: 'Assignments & Evidence',
        ),
      ),
      (
        Icons.school_outlined,
        fhcT(
          context,
          'member.kca.practicalMinistry',
          fallback: 'Practical Ministry Experience',
        ),
      ),
      (
        Icons.public,
        fhcT(
          context,
          'member.kca.globalCertification',
          fallback: 'Global Certification',
        ),
      ),
    ];

    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(
            title: '',
            onBack: () => _pop(context),
            trailing: IconButton(
              onPressed: () => _pop(context),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, size: 22),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'common.close', fallback: 'Close'),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 620;
                final shieldH = compact ? 96.0 : 132.0;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(28, compact ? 4 : 8, 28, 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 16,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 4 : 12),
                        SizedBox(
                          height: shieldH,
                          width: shieldH + 16,
                          child: Image.asset(
                            'assets/images/kca_shield.png',
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stackTrace) => Image.asset(
                                  'assets/images/security_shield.png',
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.shield,
                                        size: shieldH * 0.72,
                                        color: FhcColors.green,
                                      ),
                                ),
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        Text(
                          fhcT(
                            context,
                            'member.kca.kingdomChangeAgents',
                            fallback: 'KINGDOM CHANGE AGENTS',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: 0.6,
                            color: FhcColors.greenDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fhcT(
                            context,
                            'member.kca.discipleshipJourney',
                            fallback: 'A discipleship journey. Not just a course.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: FhcColors.muted,
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 24),
                        for (final bullet in bullets)
                          _BulletLine(icon: bullet.$1, text: bullet.$2),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: FhcPrimaryButton(
              label: fhcT(
                context,
                'member.kca.enrollNow',
                fallback: 'Enroll Now',
              ),
              onPressed: () => fhcGo(context, '/kca/enrollment/1'),
            ),
          ),
          TextButton(
            onPressed: () => fhcPush(context, FhcRoutes.kcaModules),
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              minimumSize: const Size(88, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              fhcT(context, 'member.kca.learnMore', fallback: 'Learn More'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: FhcColors.green, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: FhcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

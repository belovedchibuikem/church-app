import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaDashboardScreen extends StatelessWidget {
  const KcaDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      darkStatusBar: true,
      statusBarColor: FhcColors.greenDeep,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _KcaHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  sliver: SliverList.list(
                    children: [
                      const _ProgressCard(),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _KcaMetric(
                              icon: Icons.menu_book_outlined,
                              title: 'Modules',
                              value: '8 / 12 Complete',
                              onTap:
                                  () => fhcPush(context, FhcRoutes.kcaModules),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KcaMetric(
                              icon: Icons.assignment_outlined,
                              title: 'Assignments',
                              value: '2 Pending',
                              onTap:
                                  () => fhcPush(
                                    context,
                                    FhcRoutes.kcaAssignments,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: _KcaMetric(
                              icon: Icons.event_available_outlined,
                              title: 'Attendance',
                              value: '10 / 12 Sessions',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KcaMetric(
                              icon: Icons.school_outlined,
                              title: 'Mentor',
                              value: 'Pastor John',
                              action: 'Message',
                              onAction:
                                  () => fhcPush(context, FhcRoutes.kcaMentor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Continue Learning',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _ContinueLesson(
                        onTap: () => fhcPush(context, FhcRoutes.kcaModule),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 1,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _KcaHeader extends StatelessWidget {
  const _KcaHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FhcColors.greenDeep,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'KCA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _NotificationBell(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/member_avatar.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => const Icon(
                          Icons.person,
                          color: FhcColors.greenDeep,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chibuikem Beloved',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'KCA ID: KCA-2025-0893',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none, color: Colors.white, size: 22),
          Positioned(
            right: 2,
            top: 4,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: FhcColors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Overall Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '68%',
                style: TextStyle(
                  fontSize: 26,
                  color: FhcColors.greenDark,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.68,
              minHeight: 8,
              backgroundColor: FhcColors.border,
              valueColor: AlwaysStoppedAnimation(FhcColors.green),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Module 8 of 12',
              style: TextStyle(
                fontSize: 10,
                color: FhcColors.muted,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KcaMetric extends StatelessWidget {
  const _KcaMetric({
    required this.icon,
    required this.title,
    required this.value,
    this.action,
    this.onTap,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? action;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: FhcColors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: FhcColors.ink,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FhcColors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        action!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueLesson extends StatelessWidget {
  const _ContinueLesson({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 48,
                decoration: BoxDecoration(
                  color: FhcColors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leadership & Influence',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '•  Module 8',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: FhcColors.muted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/kca_lesson_book.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => Image.asset(
                      'assets/images/lesson_book.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.menu_book_outlined,
                            color: FhcColors.green,
                            size: 36,
                          ),
                    ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: FhcColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

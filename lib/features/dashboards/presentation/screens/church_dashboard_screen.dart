import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchDashboardScreen extends StatelessWidget {
  const ChurchDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              children: [
                const _ChurchHeader(),
                const SizedBox(height: 14),
                const _JoinLiveCard(),
                const SizedBox(height: 18),
                const Text(
                  'Ministry Overview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Members',
                        value: '1,248',
                        note: '+36 this week',
                        noteColor: FhcColors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: 'Small Groups',
                        value: '24',
                        note: 'Active',
                        noteColor: FhcColors.muted,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        label: 'First Timers',
                        value: '18',
                        note: 'New',
                        noteColor: FhcColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Upcoming Activities',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                FhcSurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _ActivityRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Prayer Meeting',
                        subtitle: 'May 20, 2025 • 6:00 PM',
                        onTap: () => fhcPush(context, FhcRoutes.prayer),
                      ),
                      const Divider(height: 1, color: FhcColors.border),
                      _ActivityRow(
                        icon: Icons.music_note_outlined,
                        title: 'Choir Practice',
                        subtitle: 'May 27, 2025 • 5:00 PM',
                        onTap: () => fhcPush(context, FhcRoutes.events),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 0,
            onSelected: (i) => fhcTab(context, i),
          ),
        ],
      ),
    );
  }
}

class _ChurchHeader extends StatelessWidget {
  const _ChurchHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'CHURCH',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FhcColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const _HeaderAvatar(),
            const SizedBox(width: 4),
            _NotificationBell(
              onTap: () => fhcPush(context, FhcRoutes.notifications),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Good morning, Chibukem',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FhcColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => fhcPush(context, FhcRoutes.churchDetail),
          borderRadius: BorderRadius.circular(4),
          child: const Row(
            children: [
              Flexible(
                child: Text(
                  'Family House Church, Ikeja',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FhcColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: FhcColors.ink,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: FhcColors.mint,
      child: ClipOval(
        child: Image.asset(
          'assets/images/member_avatar.png',
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => const Icon(
                Icons.person,
                color: FhcColors.green,
                size: 18,
              ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: 'Notifications',
      icon: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              color: FhcColors.ink,
              size: 22,
            ),
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
                  '2',
                  style: TextStyle(
                    color: FhcColors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinLiveCard extends StatelessWidget {
  const _JoinLiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: FhcColors.white,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
        boxShadow: FhcElevation.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 168,
            child: _LivePhoto(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 132, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Live Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sunday Worship',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const Text(
                  'Today • 9:00 AM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 30,
                  child: FilledButton(
                    onPressed: () => fhcPush(context, FhcRoutes.live),
                    style: FilledButton.styleFrom(
                      backgroundColor: FhcColors.green,
                      foregroundColor: FhcColors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FhcRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Join Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePhoto extends StatelessWidget {
  const _LivePhoto();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000)],
          stops: [0.0, 0.28, 1.0],
        ).createShader(bounds);
      },
      child: Image.asset(
        'assets/images/live_worship.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder:
            (_, __, ___) => Image.asset(
              'assets/images/church_live.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder:
                  (_, __, ___) => const ColoredBox(color: FhcColors.mint),
            ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.note,
    required this.noteColor,
  });

  final String label;
  final String value;
  final String note;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              color: noteColor,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: FhcColors.mint,
                borderRadius: BorderRadius.circular(FhcRadius.sm),
              ),
              child: Icon(icon, color: FhcColors.green, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: FhcColors.muted),
          ],
        ),
      ),
    );
  }
}

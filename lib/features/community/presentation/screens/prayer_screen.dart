import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  int _tab = 0;

  static const _tabs = <String>['Personal', 'Church', 'Global'];

  static const _requests = <List<_PrayerRequest>>[
    [
      _PrayerRequest(
        title: 'Healing for my mother',
        detail: 'May 20, 2025 • 120 Praying',
        icon: Icons.people_outline,
      ),
      _PrayerRequest(
        title: 'Financial breakthrough',
        detail: 'May 19, 2025 • 98 Praying',
        icon: Icons.people_outline,
      ),
      _PrayerRequest(
        title: 'Wisdom for a decision',
        detail: 'May 18, 2025 • 76 Praying',
        icon: Icons.balance,
      ),
    ],
    [
      _PrayerRequest(
        title: 'Restoration of our youth',
        detail: 'May 12, 2025 • 56 Praying',
        icon: Icons.groups_outlined,
      ),
      _PrayerRequest(
        title: 'Provision for the church building',
        detail: 'May 8, 2025 • 41 Praying',
        icon: Icons.church_outlined,
      ),
      _PrayerRequest(
        title: 'First timers this Sunday',
        detail: 'May 6, 2025 • 19 Praying',
        icon: Icons.volunteer_activism_outlined,
      ),
    ],
    [
      _PrayerRequest(
        title: 'Peace in the nations',
        detail: 'May 14, 2025 • 312 Praying',
        icon: Icons.public,
      ),
      _PrayerRequest(
        title: 'Revival across Europe',
        detail: 'May 11, 2025 • 148 Praying',
        icon: Icons.volunteer_activism_outlined,
      ),
      _PrayerRequest(
        title: 'Open doors in China',
        detail: 'May 9, 2025 • 89 Praying',
        icon: Icons.public,
      ),
    ],
  ];

  static const _answered = <List<_AnsweredPrayer>>[
    [
      _AnsweredPrayer(
        title: 'Job opportunity',
        detail: 'Answered on May 10, 2025',
      ),
    ],
    [
      _AnsweredPrayer(
        title: 'Building project funded',
        detail: 'Answered on May 4, 2025',
      ),
    ],
    [
      _AnsweredPrayer(
        title: 'Peace over the crusade',
        detail: 'Answered on May 2, 2025',
      ),
    ],
  ];

  static const _sectionTitles = <String>[
    'Your Prayer Requests',
    'Church Prayer Requests',
    'Global Prayer Requests',
  ];

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _newRequest() => fhcPush(context, FhcRoutes.prayerNew);

  @override
  Widget build(BuildContext context) {
    final requests = _requests[_tab];
    final answered = _answered[_tab];

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'PRAYER', onBack: _goBack),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _PrayerTab(
                      label: _tabs[i],
                      active: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _PrayerHero(onNewRequest: _newRequest),
                const SizedBox(height: 18),
                Text(
                  _sectionTitles[_tab],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < requests.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: FhcColors.border),
                  _RequestRow(request: requests[i]),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Answered Prayers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < answered.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: FhcColors.border),
                  _AnsweredRow(item: answered[i]),
                ],
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 0),
        ],
      ),
    );
  }
}

class _PrayerTab extends StatelessWidget {
  const _PrayerTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? FhcColors.green : FhcColors.border,
                width: active ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: active ? FhcColors.green : FhcColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerHero extends StatelessWidget {
  const _PrayerHero({required this.onNewRequest});

  final VoidCallback onNewRequest;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.card),
      child: SizedBox(
        height: 148,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: FhcColors.greenDeep),
            Image.asset(
              'assets/images/prayer_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder:
                  (context, error, stackTrace) =>
                      const ColoredBox(color: FhcColors.greenDeep),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99003D2D), Color(0xCC003D2D)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How can we pray for you?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FhcColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Expanded(
                    child: Text(
                      'Cast all your anxiety on Him because He cares for you. — 1 Peter 5:7',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FhcColors.white,
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: onNewRequest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FhcColors.white,
                          side: const BorderSide(
                            color: FhcColors.white,
                            width: 1.2,
                          ),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'New Prayer Request',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: FhcColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRequest {
  const _PrayerRequest({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final _PrayerRequest request;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            FhcCircleIcon(icon: request.icon, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: FhcColors.hint,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnsweredPrayer {
  const _AnsweredPrayer({required this.title, required this.detail});

  final String title;
  final String detail;
}

class _AnsweredRow extends StatelessWidget {
  const _AnsweredRow({required this.item});

  final _AnsweredPrayer item;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const _AnsweredAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _ChurchThumb(),
          ],
        ),
      ),
    );
  }
}

class _AnsweredAvatar extends StatelessWidget {
  const _AnsweredAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/prayer_answered_avatar.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Image.asset(
                    'assets/images/prayer_avatar.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const FhcCircleIcon(
                          icon: Icons.person_outline,
                          size: 40,
                        ),
                  ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FhcColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: FhcColors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.check,
                size: 10,
                color: FhcColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchThumb extends StatelessWidget {
  const _ChurchThumb();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 48,
        height: 36,
        child: Image.asset(
          'assets/images/prayer_answered_church.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder:
              (context, error, stackTrace) => const ColoredBox(
                color: FhcColors.mint,
                child: Icon(
                  Icons.church_outlined,
                  size: 18,
                  color: FhcColors.green,
                ),
              ),
        ),
      ),
    );
  }
}

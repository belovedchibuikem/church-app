import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _tab = 0;

  static const _tabs = <String>['Upcoming', 'My Events', 'Past Events'];

  static const _upcoming = <_EventItem>[
    _EventItem(
      title: 'KCA Training - Module 5',
      detail: 'May 31, 2025 • Online',
      asset: 'assets/images/event_kca_training.png',
      fallback: 'assets/images/event_kca_graduation.png',
      extraFallback: 'assets/images/event_graduation_thumb.png',
      icon: Icons.school_outlined,
    ),
    _EventItem(
      title: 'Youth & Young Adults Summit',
      detail: 'Jul 10 – 12, 2025 • Port Harcourt',
      asset: 'assets/images/event_youth_thumb.png',
      fallback: 'assets/images/event_youth_summit.png',
      extraFallback: 'assets/images/event_kca_graduation.png',
      icon: Icons.groups_outlined,
    ),
    _EventItem(
      title: 'Global Prayer Conference',
      detail: 'Aug 1 – 3, 2025 • Online',
      asset: 'assets/images/event_prayer_thumb.png',
      fallback: 'assets/images/event_prayer_conference.png',
      extraFallback: 'assets/images/event_kca_graduation.png',
      icon: Icons.volunteer_activism_outlined,
    ),
  ];

  static const _mine = <_EventItem>[
    _EventItem(
      title: 'Annual Convention 2025',
      detail: 'May 24 – 26, 2025 • Lagos, Nigeria',
      asset: 'assets/images/convention_crowd.png',
      fallback: 'assets/images/event_convention.png',
      extraFallback: 'assets/images/convention_2025.png',
      icon: Icons.event_outlined,
      registered: true,
    ),
  ];

  static const _past = <_EventItem>[
    _EventItem(
      title: 'Youth Summit',
      detail: 'Mar 8 – 9, 2025 • Ikeja',
      asset: 'assets/images/event_youth_thumb.png',
      fallback: 'assets/images/event_youth_summit.png',
      extraFallback: 'assets/images/event_kca_graduation.png',
      icon: Icons.groups_outlined,
    ),
  ];

  List<_EventItem> get _items => switch (_tab) {
    1 => _mine,
    2 => _past,
    _ => _upcoming,
  };

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _openDetail() => fhcPush(context, FhcRoutes.eventDetail);

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          ColoredBox(
            color: FhcColors.white,
            child: Column(
              children: [
                FhcTopBar(title: 'EVENTS', onBack: _goBack),
                Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _EventsTab(
                          label: _tabs[i],
                          active: i == _tab,
                          onTap: () => setState(() => _tab = i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                if (_tab == 0) ...[
                  _FeaturedConvention(onOpen: _openDetail),
                  const SizedBox(height: 12),
                ],
                if (items.isEmpty)
                  const _EmptyEvents()
                else
                  FhcSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: FhcColors.border),
                          _EventRow(item: items[i], onTap: _openDetail),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
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

class _FeaturedConvention extends StatelessWidget {
  const _FeaturedConvention({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              child: const _ConventionBanner(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annual Convention 2025',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'May 24 – 26, 2025 • Lagos, Nigeria',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 14,
                            color: FhcColors.muted,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '2.5K Registered',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FhcColors.muted,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: FhcColors.green,
                      foregroundColor: FhcColors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FhcRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
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

class _ConventionBanner extends StatelessWidget {
  const _ConventionBanner();

  static const _assets = <String>[
    'assets/images/convention_crowd.png',
    'assets/images/convention_hero.png',
    'assets/images/event_convention.png',
    'assets/images/convention_2025.png',
  ];

  static const _fallback = ColoredBox(
    color: FhcColors.greenDeep,
    child: Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'ANNUAL CONVENTION 2025',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FhcColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ONE HOUSE, MANY NATIONS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FhcColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    ),
  );

  static Widget _chain(List<String> paths) {
    if (paths.isEmpty) return _fallback;
    final first = paths.first;
    final rest = paths.skip(1).toList();
    return Image.asset(
      first,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      semanticLabel: 'Annual Convention 2025',
      errorBuilder: (context, error, stackTrace) => _chain(rest),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      width: double.infinity,
      child: _chain(_assets),
    );
  }
}

class _EventItem {
  const _EventItem({
    required this.title,
    required this.detail,
    required this.asset,
    required this.fallback,
    required this.extraFallback,
    required this.icon,
    this.registered = false,
  });

  final String title;
  final String detail;
  final String asset;
  final String fallback;
  final String extraFallback;
  final IconData icon;
  final bool registered;
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.item, required this.onTap});

  final _EventItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _EventThumb(
                  asset: item.asset,
                  fallback: item.fallback,
                  extraFallback: item.extraFallback,
                  icon: item.icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                if (item.registered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: FhcColors.mint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Registered',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.green,
                        height: 1.1,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: FhcColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventThumb extends StatelessWidget {
  const _EventThumb({
    required this.asset,
    required this.fallback,
    required this.extraFallback,
    required this.icon,
  });

  final String asset;
  final String fallback;
  final String extraFallback;
  final IconData icon;

  static const _size = 48.0;

  Widget _leaf() {
    return ColoredBox(
      color: FhcColors.mint,
      child: Icon(icon, size: 22, color: FhcColors.green),
    );
  }

  Widget _chain(List<String> paths) {
    if (paths.isEmpty) return _leaf();
    final first = paths.first;
    final rest = paths.skip(1).toList();
    return Image.asset(
      first,
      width: _size,
      height: _size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _chain(rest),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paths = <String>[asset, fallback, extraFallback];
    return ClipRRect(
      borderRadius: BorderRadius.circular(FhcRadius.sm),
      child: SizedBox(
        width: _size,
        height: _size,
        child: _chain(paths),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          FhcCircleIcon(icon: Icons.event_busy_outlined, size: 48),
          SizedBox(height: 12),
          Text(
            'No events yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

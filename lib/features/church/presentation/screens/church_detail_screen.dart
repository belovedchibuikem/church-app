import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchDetailScreen extends StatefulWidget {
  const ChurchDetailScreen({super.key});

  @override
  State<ChurchDetailScreen> createState() => _ChurchDetailScreenState();
}

class _ChurchDetailScreenState extends State<ChurchDetailScreen> {
  static const _isLive = true;

  bool _following = false;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.discover);
    }
  }

  void _toggleFollow() => setState(() => _following = !_following);

  void _joinLive() => fhcPush(context, FhcRoutes.live);

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _HeroHeader(onBack: _goBack, onShare: () {}),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleFollowRow(
                        following: _following,
                        onFollow: _toggleFollow,
                      ),
                      const SizedBox(height: 14),
                      const _StatsCard(),
                      const SizedBox(height: 18),
                      const Text(
                        'About Us',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'We are a Bible-believing church committed to raising disciples and transforming lives.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: FhcColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Service Times',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _ServiceTimeRow(
                        label: 'Sunday Service',
                        time: '9:00 AM',
                      ),
                      const SizedBox(height: 8),
                      const _ServiceTimeRow(
                        label: 'Bible Study (Wed)',
                        time: '6:00 PM',
                      ),
                      const SizedBox(height: 8),
                      const _ServiceTimeRow(
                        label: 'Prayer Meeting (Fri)',
                        time: '6:00 PM',
                      ),
                      const SizedBox(height: 16),
                      const _ActionRow(),
                      if (_isLive) ...[
                        const SizedBox(height: 12),
                        FhcPrimaryButton(
                          label: 'Join Live',
                          onPressed: _joinLive,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          FhcBottomNavigation(
            selected: 2,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onBack, required this.onShare});

  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 176,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(FhcRadius.lg)),
              child: _HeroPhoto(),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: _RoundIconButton(
                icon: Icons.chevron_left,
                tooltip: 'Back',
                onTap: onBack,
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: _RoundIconButton(
                icon: Icons.ios_share,
                tooltip: 'Share',
                onTap: onShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  static const _fallback = ColoredBox(
    color: FhcColors.mint,
    child: Center(
      child: Icon(Icons.church_outlined, size: 64, color: FhcColors.green),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/church_grace_hero.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/church_hero.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/church_building.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _fallback,
            );
          },
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: FhcColors.white.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: FhcSizes.minTap,
            height: FhcSizes.minTap,
            child: Icon(icon, size: 22, color: FhcColors.ink),
          ),
        ),
      ),
    );
  }
}

class _TitleFollowRow extends StatelessWidget {
  const _TitleFollowRow({required this.following, required this.onFollow});

  final bool following;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grace Home Church',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: FhcColors.ink,
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: FhcColors.muted),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Ikeja, Lagos, Nigeria',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: FhcColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _FollowButton(following: following, onPressed: onFollow),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onPressed});

  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = following ? 'Following' : 'Follow';
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 36,
        child: following
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FhcColors.green,
                  side: const BorderSide(color: FhcColors.green, width: 1.4),
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FhcRadius.button),
                  ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              )
            : FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: FhcColors.green,
                  foregroundColor: FhcColors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FhcRadius.button),
                  ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: FhcColors.white,
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: const Row(
        children: [
          Expanded(
            child: _StatCell(value: '1.2K', label: 'Members'),
          ),
          _StatDivider(),
          Expanded(
            child: _StatCell(value: '24', label: 'Ministries'),
          ),
          _StatDivider(),
          Expanded(
            child: _StatCell(value: '4.8', label: 'Rating', showStar: true),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 1,
        height: 36,
        child: ColoredBox(color: FhcColors.border),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.showStar = false,
  });

  final String value;
  final String label;
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: FhcColors.ink,
                ),
              ),
            ),
            if (showStar) ...[
              const SizedBox(width: 3),
              const Icon(Icons.star_rounded, size: 14, color: FhcColors.gold),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            height: 1.2,
            color: FhcColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ServiceTimeRow extends StatelessWidget {
  const _ServiceTimeRow({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: FhcColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            height: 1.2,
            color: FhcColors.muted,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  static const _actions = <(IconData, String)>[
    (Icons.call_outlined, 'Call'),
    (Icons.directions_outlined, 'Directions'),
    (Icons.language_outlined, 'Website'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _OutlinedAction(
              icon: _actions[i].$1,
              label: _actions[i].$2,
            ),
          ),
        ],
      ],
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 40,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: FhcColors.ink,
            side: const BorderSide(color: FhcColors.border),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FhcRadius.button),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: FhcColors.ink),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: FhcColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

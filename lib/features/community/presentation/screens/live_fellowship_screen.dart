import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class LiveFellowshipScreen extends StatelessWidget {
  const LiveFellowshipScreen({super.key});

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.church);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: 'LIVE SERVICE',
            onBack: () => _onBack(context),
            trailing: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.cast, size: 22),
              color: FhcColors.ink,
              tooltip: 'Cast',
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final tight = h < 540;
                final videoH = (h * (tight ? 0.30 : 0.34)).clamp(
                  148.0,
                  tight ? 176.0 : 220.0,
                );
                final showMeta = h >= 500;

                return Column(
                  children: [
                    SizedBox(
                      height: videoH,
                      width: double.infinity,
                      child: const _VideoStage(),
                    ),
                    if (showMeta) const _ServiceMeta(),
                    const Expanded(child: _LiveChat()),
                    const _MessageComposer(),
                    const _LiveActions(),
                  ],
                );
              },
            ),
          ),
          const FhcBottomNavigation(selected: 0),
        ],
      ),
    );
  }
}

class _VideoStage extends StatelessWidget {
  const _VideoStage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FhcColors.midnight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _LivePhoto(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66001823),
                  Color(0x14001823),
                  Color(0xCC001823),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          const Positioned(
            left: 12,
            top: 10,
            child: Row(
              children: [
                _LiveBadge(),
                SizedBox(width: 8),
                _ViewerCount(),
              ],
            ),
          ),
          const Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _VideoTitles(),
          ),
        ],
      ),
    );
  }
}

class _LivePhoto extends StatelessWidget {
  const _LivePhoto();

  static const _paths = <String>[
    'assets/images/live_pastor.png',
    'assets/images/live_worship.png',
    'assets/images/live_fellowship.png',
    'assets/images/church_live.png',
  ];

  Widget _chain(List<String> paths) {
    if (paths.isEmpty) {
      return const ColoredBox(color: FhcColors.midnight);
    }
    final first = paths.first;
    final rest = paths.skip(1).toList();
    return Image.asset(
      first,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      semanticLabel: 'Live Sunday service',
      errorBuilder: (context, error, stackTrace) => _chain(rest),
    );
  }

  @override
  Widget build(BuildContext context) => _chain(_paths);
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FhcColors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: FhcColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          height: 1.1,
        ),
      ),
    );
  }
}

class _ViewerCount extends StatelessWidget {
  const _ViewerCount();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 13, color: FhcColors.white),
          SizedBox(width: 4),
          Text(
            '1.2K',
            style: TextStyle(
              color: FhcColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTitles extends StatelessWidget {
  const _VideoTitles();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Grace Home Church',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FhcColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Sunday Service',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FhcColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person_outline, size: 13, color: FhcColors.white),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Pastor John David',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FhcColors.white,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceMeta extends StatelessWidget {
  const _ServiceMeta();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sunday Worship',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Family House Church, Ikeja',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FhcTypography.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, size: 20, color: FhcColors.ink),
        ],
      ),
    );
  }
}

class _LiveChat extends StatelessWidget {
  const _LiveChat();

  static const _messages = <_ChatItem>[
    _ChatItem(
      name: 'Sarah M.',
      text: 'Amen! 🙏',
      time: '9:05 AM',
      asset: 'assets/images/prayer_avatar.png',
    ),
    _ChatItem(
      name: 'David O.',
      text: 'God is so good!',
      time: '9:05 AM',
      asset: 'assets/images/member_avatar.png',
    ),
    _ChatItem(
      name: 'Blessing U.',
      text: 'This is powerful 🔥',
      time: '9:05 AM',
      asset: 'assets/images/profile_chibuikem.png',
    ),
    _ChatItem(
      name: 'Peter A.',
      text: 'Glory to God!',
      time: '9:05 AM',
      asset: 'assets/images/kca_avatar.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FhcColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Text(
              'Live Chat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: _messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ChatMessage(item: _messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  const _ChatItem({
    required this.name,
    required this.text,
    required this.time,
    required this.asset,
  });

  final String name;
  final String text;
  final String time;
  final String asset;
}

class _ChatMessage extends StatelessWidget {
  const _ChatMessage({required this.item});

  final _ChatItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChatAvatar(name: item.name, asset: item.asset),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
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
                  const SizedBox(width: 8),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: FhcColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                item.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: FhcColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.name, required this.asset});

  final String name;
  final String asset;

  static const _size = 32.0;
  static const _fallbacks = <String>[
    'assets/images/member_avatar.png',
    'assets/images/prayer_avatar.png',
    'assets/images/profile_chibuikem.png',
  ];

  Widget _leaf() {
    return ColoredBox(
      color: FhcColors.mint,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0],
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FhcColors.green,
          ),
        ),
      ),
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
    final paths = <String>[asset];
    for (final path in _fallbacks) {
      if (!paths.contains(path)) paths.add(path);
    }
    return ClipOval(
      child: SizedBox(width: _size, height: _size, child: _chain(paths)),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: FhcTypography.body,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: FhcTypography.hint,
                filled: true,
                fillColor: FhcColors.canvas,
                isDense: true,
                suffixIcon: const Icon(
                  Icons.sentiment_satisfied_alt_outlined,
                  size: 20,
                  color: FhcColors.hint,
                ),
                contentPadding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: FhcColors.border),
                  borderRadius: radius,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FhcColors.border),
                  borderRadius: radius,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: FhcColors.green,
                    width: 1.5,
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _HeartCount(),
        ],
      ),
    );
  }
}

class _HeartCount extends StatelessWidget {
  const _HeartCount();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '266 hearts',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: FhcColors.canvas,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 18, color: FhcColors.red),
            SizedBox(width: 4),
            Text(
              '266',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveActions extends StatelessWidget {
  const _LiveActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(top: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionItem(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () {},
            ),
          ),
          Expanded(
            child: _ActionItem(
              icon: Icons.favorite_border,
              label: 'Give',
              onTap: () => fhcPush(context, FhcRoutes.give),
            ),
          ),
          Expanded(
            child: _ActionItem(
              icon: Icons.volunteer_activism_outlined,
              label: 'Prayer',
              onTap: () => fhcPush(context, FhcRoutes.prayer),
            ),
          ),
          Expanded(
            child: _ActionItem(
              icon: Icons.more_horiz,
              label: 'More',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: FhcColors.ink),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FhcColors.ink,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

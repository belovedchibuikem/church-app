import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int _tab = 0;

  static const _tabs = <String>['All Groups', 'My Groups'];

  static const _all = <_GroupItem>[
    _GroupItem(
      name: 'Young Adults Fellowship',
      description: 'A community for young believers to grow together.',
      members: 24,
      asset: 'assets/images/group_avatar_young_adults.png',
      fallback: 'assets/images/member_avatar.png',
    ),
    _GroupItem(
      name: 'Women of Grace',
      description: 'Empowering women to fulfill their purpose.',
      members: 38,
      asset: 'assets/images/group_avatar_women_of_grace.png',
      fallback: 'assets/images/profile_chibuikem.png',
    ),
    _GroupItem(
      name: 'Men of Valor',
      description: 'Raising godly men of integrity and purpose.',
      members: 38,
      asset: 'assets/images/group_avatar_men_of_valor.png',
      fallback: 'assets/images/kca_avatar.png',
    ),
    _GroupItem(
      name: 'Bible Study Group',
      description: 'Weekly Bible study and discussions.',
      members: 18,
      asset: 'assets/images/member_avatar.png',
      fallback: 'assets/images/kca_avatar.png',
    ),
  ];

  static const _mine = <_GroupItem>[
    _GroupItem(
      name: 'Young Adults Fellowship',
      description: 'A community for young believers to grow together.',
      members: 24,
      asset: 'assets/images/group_avatar_young_adults.png',
      fallback: 'assets/images/member_avatar.png',
      joined: true,
    ),
  ];

  List<_GroupItem> get _items => _tab == 1 ? _mine : _all;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  void _join() => fhcPush(context, FhcRoutes.messages);

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'Groups', onBack: _goBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FhcColors.canvas,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: _GroupsTab(
                          label: _tabs[i],
                          active: i == _tab,
                          onTap: () => setState(() => _tab = i),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child:
                items.isEmpty
                    ? const _EmptyGroups()
                    : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _GroupRow(
                          item: item,
                          onJoin: item.joined ? null : _join,
                        );
                      },
                    ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _GroupItem {
  const _GroupItem({
    required this.name,
    required this.description,
    required this.members,
    required this.asset,
    required this.fallback,
    this.joined = false,
  });

  final String name;
  final String description;
  final int members;
  final String asset;
  final String fallback;
  final bool joined;
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 36,
          decoration: BoxDecoration(
            color: active ? FhcColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                height: 1.1,
                color: active ? FhcColors.white : FhcColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.item, required this.onJoin});

  final _GroupItem item;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _GroupAvatar(asset: item.asset, fallback: item.fallback),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: FhcColors.muted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.members} Members',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: FhcColors.hint,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (item.joined)
            const _JoinedLabel()
          else
            _JoinButton(onPressed: onJoin),
        ],
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.asset, required this.fallback});

  final String asset;
  final String fallback;

  static const _size = 48.0;
  static const _fallbacks = <String>[
    'assets/images/member_avatar.png',
    'assets/images/profile_chibuikem.png',
    'assets/images/kca_avatar.png',
  ];

  Widget _leaf() {
    return const ColoredBox(
      color: FhcColors.mint,
      child: Icon(Icons.groups_outlined, size: 22, color: FhcColors.green),
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
    final paths = <String>[asset, fallback];
    for (final path in _fallbacks) {
      if (!paths.contains(path)) paths.add(path);
    }
    return ClipOval(
      child: SizedBox(width: _size, height: _size, child: _chain(paths)),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: FhcColors.green,
          backgroundColor: FhcColors.white,
          side: const BorderSide(color: FhcColors.green),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FhcRadius.button),
          ),
        ),
        child: const Text(
          'Join',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _JoinedLabel extends StatelessWidget {
  const _JoinedLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FhcColors.mint,
        borderRadius: BorderRadius.circular(FhcRadius.button),
      ),
      child: const Text(
        'Joined',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: FhcColors.green,
          height: 1.1,
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          FhcCircleIcon(icon: Icons.groups_outlined, size: 48),
          SizedBox(height: 12),
          Text(
            'No groups yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

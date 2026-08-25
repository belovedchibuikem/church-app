import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  int _tab = 0;
  String _query = '';

  static const _tabs = <(String, String)>[
    ('All', '1,248'),
    ('Leaders', '45'),
    ('New', '18'),
  ];

  static const _members = <_MemberSpec>[
    _MemberSpec(
      name: 'John David',
      role: 'Leader',
      joined: 'Jan 2023',
      asset: 'assets/images/member_avatar.png',
      leader: true,
    ),
    _MemberSpec(
      name: 'Sarah Okafor',
      role: 'Member',
      joined: 'Mar 2023',
      asset: 'assets/images/profile_chibuikem.png',
    ),
    _MemberSpec(
      name: 'Michael Johnson',
      role: 'Member',
      joined: 'Apr 2023',
      asset: 'assets/images/kca_avatar.png',
    ),
    _MemberSpec(
      name: 'Blessing Uche',
      role: 'Member',
      joined: 'May 2023',
      asset: 'assets/images/prayer_avatar.png',
    ),
    _MemberSpec(
      name: 'Emeka Onyema',
      role: 'Member',
      joined: 'May 2023',
      asset: 'assets/images/member_avatar.png',
    ),
    _MemberSpec(
      name: 'Chibuikem Beloved',
      role: 'Member',
      joined: 'Nov 2024',
      asset: 'assets/images/profile_chibuikem.png',
      isNew: true,
    ),
    _MemberSpec(
      name: 'Pastor Tunde',
      role: 'Pastor',
      joined: 'Jan 2020',
      asset: 'assets/images/kca_avatar.png',
      leader: true,
    ),
    _MemberSpec(
      name: 'Mary Okafor',
      role: 'Leader',
      joined: 'Feb 2025',
      asset: 'assets/images/prayer_avatar.png',
      leader: true,
      isNew: true,
    ),
  ];

  List<_MemberSpec> get _visible {
    final q = _query.trim().toLowerCase();
    return _members.where((member) {
      final matchesTab = switch (_tab) {
        1 => member.leader,
        2 => member.isNew,
        _ => true,
      };
      if (!matchesTab) return false;
      if (q.isEmpty) return true;
      return member.name.toLowerCase().contains(q) ||
          member.role.toLowerCase().contains(q);
    }).toList();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    fhcGo(context, FhcRoutes.churchHome);
  }

  void _openMessages() => fhcPush(context, FhcRoutes.messages);

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: 'Members',
            onBack: _goBack,
            trailing: const _SearchFilterTrailing(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _SearchFilterRow(
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(
                      label: '${_tabs[i].$1} (${_tabs[i].$2})',
                      selected: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child:
                visible.isEmpty
                    ? const Center(child: _EmptyMembers())
                    : ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: visible.length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(height: 1, color: FhcColors.border),
                      itemBuilder: (context, index) {
                        return _MemberRow(
                          member: visible[index],
                          onMessage: _openMessages,
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: FhcPrimaryButton(label: '+ Add Member', onPressed: () {}),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _MemberSpec {
  const _MemberSpec({
    required this.name,
    required this.role,
    required this.joined,
    required this.asset,
    this.leader = false,
    this.isNew = false,
  });

  final String name;
  final String role;
  final String joined;
  final String asset;
  final bool leader;
  final bool isNew;
}

class _SearchFilterTrailing extends StatelessWidget {
  const _SearchFilterTrailing();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
          icon: const Icon(Icons.search, size: 22),
          color: FhcColors.ink,
          tooltip: 'Search',
        ),
        IconButton(
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
          icon: const Icon(Icons.tune, size: 22),
          color: FhcColors.ink,
          tooltip: 'Filter',
        ),
      ],
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              style: FhcTypography.body,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search members...',
                hintStyle: FhcTypography.hint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: FhcColors.muted,
                ),
                isDense: true,
                filled: true,
                fillColor: FhcColors.canvas,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: radius,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
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
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Filter',
          child: Container(
            width: FhcSizes.minTap,
            height: FhcSizes.minTap,
            decoration: BoxDecoration(
              color: FhcColors.canvas,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tune, size: 20, color: FhcColors.ink),
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? FhcColors.green : const Color(0xFFEEF0EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? FhcColors.white : FhcColors.ink,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onMessage});

  final _MemberSpec member;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _MemberAvatar(asset: member.asset, name: member.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
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
                    '${member.role} • Joined ${member.joined}',
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
            _CircleAction(
              icon: Icons.phone,
              tooltip: 'Call ${member.name}',
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            _CircleAction(
              icon: Icons.chat_bubble_outline,
              tooltip: 'Message ${member.name}',
              onPressed: onMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: FhcSizes.minTap,
        minHeight: FhcSizes.minTap,
      ),
      tooltip: tooltip,
      icon: FhcCircleIcon(icon: icon, size: 32),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.asset, required this.name});

  final String asset;
  final String name;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => ColoredBox(
              color: FhcColors.mint,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Text(
                    name.isEmpty ? '?' : name[0],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.green,
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          FhcCircleIcon(icon: Icons.groups_outlined, size: 48),
          SizedBox(height: 12),
          Text(
            'No members found',
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

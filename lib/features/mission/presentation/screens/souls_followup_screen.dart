import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class SoulsFollowupScreen extends StatefulWidget {
  const SoulsFollowupScreen({super.key});

  @override
  State<SoulsFollowupScreen> createState() => _SoulsFollowupScreenState();
}

class _SoulsFollowupScreenState extends State<SoulsFollowupScreen> {
  int _tab = 0;

  static const _tabs = <(String, int)>[('New Souls', 124), ('Follow-up', 56)];

  static const _followUpBlue = Color(0xFF2E90C7);

  static const _souls = <_Soul>[
    _Soul(
      name: 'Emeka Onyema',
      date: 'May 20, 2025',
      photo: 'assets/images/profile_chibuikem.png',
      isNew: true,
    ),
    _Soul(
      name: 'Sarah Ibrahim',
      date: 'May 20, 2025',
      photo: 'assets/images/member_avatar.png',
      isNew: true,
    ),
    _Soul(
      name: 'John Musa',
      date: 'May 18, 2025',
      photo: 'assets/images/mentor_avatar.png',
      isNew: false,
    ),
    _Soul(
      name: 'Blessing Uche',
      date: 'May 17, 2025',
      photo: 'assets/images/member_avatar.png',
      isNew: false,
    ),
    _Soul(
      name: 'David Okafor',
      date: 'May 16, 2025',
      photo: 'assets/images/member_avatar.png',
      isNew: true,
    ),
    _Soul(
      name: 'Joy Naro',
      date: 'May 15, 2025',
      photo: 'assets/images/mentor_avatar.png',
      isNew: false,
    ),
    _Soul(
      name: 'Daniel Dandeli',
      date: 'May 14, 2025',
      photo: 'assets/images/profile_chibuikem.png',
      isNew: false,
    ),
    _Soul(
      name: 'Tunde Adeboyo',
      date: 'May 13, 2025',
      photo: 'assets/images/member_avatar.png',
      isNew: true,
    ),
  ];

  List<_Soul> get _visible =>
      _tab == 0 ? _souls : _souls.where((soul) => !soul.isNew).toList();

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.crusade);
    }
  }

  void _openFollowup() => fhcPush(context, FhcRoutes.messages);

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'Soul Follow-up', onBack: _onBack),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _SoulsTab(
                      label: '${_tabs[i].$1} (${_tabs[i].$2})',
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                FhcSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: FhcColors.border),
                        _SoulRow(
                          soul: visible[i],
                          followUpBlue: _followUpBlue,
                          onFollowUp: _openFollowup,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FhcPrimaryButton(label: 'Add New Soul', onPressed: () {}),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _Soul {
  const _Soul({
    required this.name,
    required this.date,
    required this.photo,
    required this.isNew,
  });

  final String name;
  final String date;
  final String photo;
  final bool isNew;
}

class _SoulsTab extends StatelessWidget {
  const _SoulsTab({
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

class _SoulRow extends StatelessWidget {
  const _SoulRow({
    required this.soul,
    required this.followUpBlue,
    required this.onFollowUp,
  });

  final _Soul soul;
  final Color followUpBlue;
  final VoidCallback onFollowUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          _SoulPhoto(asset: soul.photo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soul.name,
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
                  '${soul.isNew ? 'New' : 'Follow-up'} • ${soul.date}',
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
          const SizedBox(width: 6),
          _StatusBadge(
            label: soul.isNew ? 'New' : 'Follow-up',
            color: soul.isNew ? FhcColors.orange : followUpBlue,
            filled: soul.isNew,
          ),
          const SizedBox(width: 6),
          _FollowupButton(onPressed: onFollowUp),
        ],
      ),
    );
  }
}

class _SoulPhoto extends StatelessWidget {
  const _SoulPhoto({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => const ColoredBox(
              color: FhcColors.mint,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: FhcColors.green,
                ),
              ),
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: filled ? FhcColors.white : color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _FollowupButton extends StatelessWidget {
  const _FollowupButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Follow-up',
      child: SizedBox(
        height: 32,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: FhcColors.green,
            foregroundColor: FhcColors.white,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Follow-up',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PrayerNewScreen extends StatefulWidget {
  const PrayerNewScreen({super.key});

  @override
  State<PrayerNewScreen> createState() => _PrayerNewScreenState();
}

class _PrayerNewScreenState extends State<PrayerNewScreen> {
  final _requestController = TextEditingController();
  bool _anonymous = false;
  String _category = 'Personal';

  static const _categories = <(IconData, String)>[
    (Icons.person_outline, 'Personal'),
    (Icons.groups_outlined, 'Family'),
    (Icons.favorite_border, 'Healing'),
    (Icons.auto_awesome, 'Breakthrough'),
    (Icons.shield_outlined, 'Protection'),
    (Icons.volunteer_activism_outlined, 'Thanksgiving'),
  ];

  static const _recent = <(String, String, String)>[
    ('Healing for my mother', 'Healing', '24 praying · 2 days ago'),
    ('Breakthrough in my business', 'Breakthrough', '18 praying · 5 days ago'),
    ('Protection over my family', 'Protection', '12 praying · 1 week ago'),
  ];

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      fhcGo(context, FhcRoutes.prayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'Prayer', onBack: _onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                const Text(
                  'Write your prayer request',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _RequestField(controller: _requestController),
                const SizedBox(height: 12),
                _AnonymousToggle(
                  value: _anonymous,
                  onChanged: (value) => setState(() => _anonymous = value),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.12,
                  children: [
                    for (final item in _categories)
                      _CategoryTile(
                        icon: item.$1,
                        label: item.$2,
                        selected: _category == item.$2,
                        onTap: () => setState(() => _category = item.$2),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Recent Requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _recent.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _RecentRequestCard(
                    title: _recent[i].$1,
                    category: _recent[i].$2,
                    meta: _recent[i].$3,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FhcPrimaryButton(
              label: 'Submit',
              onPressed: () => fhcGo(context, FhcRoutes.prayer),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestField extends StatelessWidget {
  const _RequestField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: FhcTypography.body,
      decoration: InputDecoration(
        hintText: 'Share what you would like the church to pray for.',
        hintStyle: FhcTypography.hint,
        filled: true,
        fillColor: FhcColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: FhcColors.border),
          borderRadius: radius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: FhcColors.border),
          borderRadius: radius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
          borderRadius: radius,
        ),
      ),
    );
  }
}

class _AnonymousToggle extends StatelessWidget {
  const _AnonymousToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit Anonymously',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your name will not be shown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: FhcColors.green,
            inactiveTrackColor: FhcColors.border,
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FhcColors.mint : FhcColors.white,
      borderRadius: BorderRadius.circular(FhcRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? FhcColors.mint : FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(
              color: selected ? FhcColors.green : FhcColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? FhcColors.green : FhcColors.ink,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: selected ? FhcColors.green : FhcColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentRequestCard extends StatelessWidget {
  const _RecentRequestCard({
    required this.title,
    required this.category,
    required this.meta,
  });

  final String title;
  final String category;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FhcColors.mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.pan_tool_outlined,
              color: FhcColors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  '$category · $meta',
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
        ],
      ),
    );
  }
}

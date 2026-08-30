import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PrayerNewScreen extends StatefulWidget {
  const PrayerNewScreen({super.key, this.prayerRepository});

  final PrayerRepository? prayerRepository;

  @override
  State<PrayerNewScreen> createState() => _PrayerNewScreenState();
}

class _PrayerNewScreenState extends State<PrayerNewScreen> {
  final _requestController = TextEditingController();
  bool _anonymous = false;
  String _category = 'Personal';
  bool _submitting = false;
  String? _error;
  List<_RecentPrayer> _recent = const [];

  static const _categories = <(IconData, String, String)>[
    (Icons.person_outline, 'Personal', 'member.prayer.categoryPersonal'),
    (Icons.groups_outlined, 'Family', 'member.prayer.categoryFamily'),
    (Icons.favorite_border, 'Healing', 'member.prayer.categoryHealing'),
    (Icons.auto_awesome, 'Breakthrough', 'member.prayer.categoryBreakthrough'),
    (Icons.shield_outlined, 'Protection', 'member.prayer.categoryProtection'),
    (
      Icons.volunteer_activism_outlined,
      'Thanksgiving',
      'member.prayer.categoryThanksgiving',
    ),
  ];

  PrayerRepository? get _repo =>
      widget.prayerRepository ??
      AppServicesScope.maybeOf(context)?.prayerRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recent.isEmpty) {
      _loadRecent();
    }
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final repo = _repo;
    if (repo == null) return;
    final result = await repo.listOwn();
    if (!mounted) return;
    if (result is AppSuccess<List<JsonObject>>) {
      setState(() {
        _recent = [
          for (final item in result.value.take(3))
            _RecentPrayer(
              title:
                  '${item['subject'] ?? item['title'] ?? item['request'] ?? item['body'] ?? fhcT(context, 'member.prayer', fallback: 'Prayer')}',
              category:
                  '${item['status'] ?? item['category'] ?? fhcT(context, 'member.prayer.categoryPersonal', fallback: 'Personal')}',
              meta:
                  '${item['praying_count'] ?? item['supporters'] ?? fhcT(context, 'member.prayer.shared', fallback: 'Shared')}',
            ),
        ];
      });
    }
  }

  Future<void> _submit() async {
    final text = _requestController.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'member.prayer.writeBeforeSubmit',
          fallback: 'Write your prayer request before submitting.',
        ),
      );
      return;
    }
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error = fhcT(
          context,
          'member.prayer.submitUnavailable',
          fallback: 'Prayer submission is waiting on the Laravel prayers API.',
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final subject = text.length > 80 ? '${text.substring(0, 77)}…' : text;
    final result = await repo.create({
      'subject': subject,
      'body': _anonymous
          ? '[$_category · anonymous]\n$text'
          : '[$_category]\n$text',
    });

    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        setState(() => _submitting = false);
        fhcGo(context, FhcRoutes.prayer);
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
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
          FhcTopBar(
            title: fhcT(context, 'member.prayer', fallback: 'Prayer'),
            onBack: _onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Text(
                  fhcT(
                    context,
                    'member.prayer.writeRequest',
                    fallback: 'Write your prayer request',
                  ),
                  style: const TextStyle(
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
                Text(
                  fhcT(context, 'member.prayer.category', fallback: 'Category'),
                  style: const TextStyle(
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
                        label: fhcT(context, item.$3, fallback: item.$2),
                        selected: _category == item.$2,
                        onTap: () => setState(() => _category = item.$2),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  FhcErrorState(
                    title: fhcT(
                      context,
                      'errors.unableToSubmit',
                      fallback: 'Unable to submit',
                    ),
                    message: _error!,
                    onRetry: _submitting ? null : _submit,
                  ),
                ],
                if (_recent.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    fhcT(
                      context,
                      'member.prayer.recentRequests',
                      fallback: 'Recent Requests',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _recent.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _RecentRequestCard(
                      title: _recent[i].title,
                      category: _recent[i].category,
                      meta: _recent[i].meta,
                    ),
                  ],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FhcPrimaryButton(
              label: _submitting
                  ? fhcT(
                      context,
                      'common.submitting',
                      fallback: 'Submitting…',
                    )
                  : fhcT(context, 'common.submit', fallback: 'Submit'),
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPrayer {
  const _RecentPrayer({
    required this.title,
    required this.category,
    required this.meta,
  });

  final String title;
  final String category;
  final String meta;
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
        hintText: fhcT(
          context,
          'member.prayer.requestHint',
          fallback: 'Share what you would like the church to pray for.',
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fhcT(
                    context,
                    'member.prayer.submitAnonymously',
                    fallback: 'Submit Anonymously',
                  ),
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
                  fhcT(
                    context,
                    'member.prayer.anonymousCopy',
                    fallback: 'Your name will not be shown',
                  ),
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

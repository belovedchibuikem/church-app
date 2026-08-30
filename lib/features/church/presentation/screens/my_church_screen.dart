import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Member churches and linked home churches from GET /user/memberships.
class MyChurchScreen extends StatefulWidget {
  const MyChurchScreen({super.key, this.churchRepository});

  final ChurchRepository? churchRepository;

  @override
  State<MyChurchScreen> createState() => _MyChurchScreenState();
}

class _MyChurchScreenState extends State<MyChurchScreen> {
  bool _loading = true;
  String? _error;
  List<JsonObject> _memberships = const [];
  bool _started = false;

  ChurchRepository? get _repo =>
      widget.churchRepository ??
      AppServicesScope.maybeOf(context)?.churchRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _loading = false;
        _error = 'Church memberships require a signed-in session.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await repo.listMemberships();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _memberships = value;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _openHomeChurch(String? id) {
    final trimmed = id?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    Navigator.of(context).pushNamed(
      FhcRoutes.homeChurch,
      arguments: FhcRouteArgs(entityId: trimmed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'member.myChurch', fallback: 'My Church'),
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                fhcGo(context, FhcRoutes.churchHome);
              }
            },
          ),
          Expanded(child: _body()),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return FhcErrorState(
        title: fhcT(
          context,
          'member.unableToLoadMemberships',
          fallback: 'Unable to load memberships',
        ),
        message: _error!,
        onRetry: _load,
      );
    }
    if (_memberships.isEmpty) {
      return FhcEmptyState(
        icon: Icons.church_outlined,
        title: fhcT(
          context,
          'member.noMembershipYet',
          fallback: 'No church membership yet',
        ),
        message: fhcT(
          context,
          'member.noMembershipBody',
          fallback:
              'Find a Family House church and request to join. Home churches appear here once linked.',
        ),
        actionLabel: fhcT(context, 'member.findChurches', fallback: 'Find Churches'),
        onAction: () => fhcPush(context, FhcRoutes.discover),
      );
    }

    final active = _memberships
        .where((m) => '${m['status'] ?? 'active'}' == 'active')
        .toList();
    final withHome = _memberships
        .where((m) => (m['home_church_id'] as String?)?.isNotEmpty == true)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: fhcT(
                  context,
                  'member.activeMemberships',
                  fallback: 'Active',
                ),
                value: '${active.length}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                label: fhcT(
                  context,
                  'member.homeChurches',
                  fallback: 'Home churches',
                ),
                value: '${withHome.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          fhcT(context, 'member.churchesYouBelongTo', fallback: 'Churches you belong to'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        FhcSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _memberships.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _MembershipRow(
                  membership: _memberships[i],
                  onOpenChurch: () {
                    final id = (_memberships[i]['church_id'] as String?)?.trim();
                    if (id == null || id.isEmpty) return;
                    fhcPush(context, '${FhcRoutes.churchDetail}?id=$id');
                  },
                  onOpenHome: () => _openHomeChurch(
                    _memberships[i]['home_church_id'] as String?,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FhcPrimaryButton(
          label: fhcT(context, 'member.findChurches', fallback: 'Find Churches'),
          onPressed: () => fhcPush(context, FhcRoutes.discover),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => fhcPush(context, FhcRoutes.homeChurchStart),
          child: Text(
            fhcT(
              context,
              'member.startHomeChurch',
              fallback: 'Start a home church',
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: FhcColors.green,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: FhcColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({
    required this.membership,
    required this.onOpenChurch,
    required this.onOpenHome,
  });

  final JsonObject membership;
  final VoidCallback onOpenChurch;
  final VoidCallback onOpenHome;

  @override
  Widget build(BuildContext context) {
    final churchName = (membership['church_name'] as String?)?.trim().isNotEmpty == true
        ? (membership['church_name'] as String).trim()
        : fhcT(context, 'member.church', fallback: 'Church');
    final status = '${membership['status'] ?? 'active'}';
    final homeId = (membership['home_church_id'] as String?)?.trim();
    final homeName = (membership['home_church_name'] as String?)?.trim();
    final joined = (membership['joined_at'] as String?) ?? '';

    return InkWell(
      onTap: onOpenChurch,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.church_outlined, color: FhcColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    churchName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FhcColors.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: FhcColors.green,
                    ),
                  ),
                ),
              ],
            ),
            if (joined.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                fhcT(
                  context,
                  'member.joinedOn',
                  fallback: 'Joined $joined',
                  args: {'when': joined},
                ),
                style: const TextStyle(fontSize: 11, color: FhcColors.muted),
              ),
            ],
            if (homeId != null && homeId.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: onOpenHome,
                child: Row(
                  children: [
                    const Icon(Icons.home_work_outlined, size: 16, color: FhcColors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        homeName?.isNotEmpty == true
                            ? homeName!
                            : fhcT(
                              context,
                              'member.linkedHomeChurch',
                              fallback: 'Linked home church',
                            ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FhcColors.green,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: FhcColors.muted),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

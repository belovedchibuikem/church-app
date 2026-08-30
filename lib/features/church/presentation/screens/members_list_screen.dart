import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key, this.churchId, this.repository});

  final String? churchId;
  final ChurchRepository? repository;

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  int _tab = 0;
  String _query = '';
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();

  ChurchRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.churchRepository;

  List<String> get _tabLabels => [
    fhcT(context, 'common.all', fallback: 'All'),
    fhcT(context, 'member.leaders', fallback: 'Leaders'),
    fhcT(context, 'member.newMembers', fallback: 'New'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<String?> _resolveChurchId(ChurchRepository repo) async {
    final fromWidget = widget.churchId?.trim();
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    final fromRoute = FhcRouteArgs.entityIdOf(context)?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) return fromRoute;

    final memberships = await repo.listMemberships();
    return switch (memberships) {
      AppSuccess(:final value) => _firstActiveChurchId(value),
      AppError() => null,
    };
  }

  String? _firstActiveChurchId(List<JsonObject> memberships) {
    for (final item in memberships) {
      final status = '${item['status'] ?? ''}'.toLowerCase();
      if (status.isNotEmpty &&
          status != 'active' &&
          status != 'approved' &&
          status != 'member') {
        continue;
      }
      final churchId = '${item['church_id'] ?? item['churchId'] ?? ''}'.trim();
      if (churchId.isNotEmpty) return churchId;
      final church = item['church'];
      if (church is Map) {
        final id = '${church['id'] ?? ''}'.trim();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.membersRequireApi',
            fallback:
                'Church members require the authenticated members API. '
                'No fixture directory is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final churchId = await _resolveChurchId(repository);
    if (!mounted) return;
    if (churchId == null || churchId.isEmpty) {
      setState(() {
        _state = FhcAsyncValue.empty(
          message: fhcT(
            context,
            'member.noActiveMembership',
            fallback:
                'Join a church to see members. No active membership was found.',
          ),
        );
      });
      return;
    }

    final result = await repository.listChurchMembers(churchId);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? FhcAsyncValue.empty(
                  message: fhcT(
                    context,
                    'member.noMembersYet',
                    fallback: 'No members were returned for this church.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  bool _isLeader(JsonObject member) {
    final role = '${member['role'] ?? member['role_name'] ?? ''}'.toLowerCase();
    final leader = member['is_leader'] == true || member['leader'] == true;
    return leader ||
        role.contains('leader') ||
        role.contains('pastor') ||
        role.contains('elder');
  }

  bool _isNew(JsonObject member) {
    if (member['is_new'] == true) return true;
    final joined = DateTime.tryParse(
      '${member['joined_at'] ?? member['created_at'] ?? ''}',
    );
    if (joined == null) return false;
    return DateTime.now().difference(joined).inDays <= 90;
  }

  String _displayName(JsonObject member) {
    final person = member['person'];
    if (person is Map) {
      final preferred = '${person['preferred_name'] ?? ''}'.trim();
      final given = '${person['given_name'] ?? ''}'.trim();
      final family = '${person['family_name'] ?? ''}'.trim();
      final parts = [
        if (preferred.isNotEmpty) preferred,
        if (preferred.isEmpty && given.isNotEmpty) given,
        if (family.isNotEmpty) family,
      ];
      if (parts.isNotEmpty) return parts.join(' ');
    }
    final name = '${member['name'] ?? member['display_name'] ?? ''}'.trim();
    return name.isEmpty ? 'Member' : name;
  }

  String _roleLabel(JsonObject member) {
    final role = '${member['role'] ?? member['role_name'] ?? ''}'.trim();
    return role.isEmpty
        ? fhcT(context, 'member.roleMember', fallback: 'Member')
        : role;
  }

  String _joinedLabel(JsonObject member) {
    final raw = '${member['joined_at'] ?? member['created_at'] ?? ''}'.trim();
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  }

  List<JsonObject> _visible(List<JsonObject> members) {
    final q = _query.trim().toLowerCase();
    return members.where((member) {
      final matchesTab = switch (_tab) {
        1 => _isLeader(member),
        2 => _isNew(member),
        _ => true,
      };
      if (!matchesTab) return false;
      if (q.isEmpty) return true;
      final hay = '${_displayName(member)} ${_roleLabel(member)}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    fhcGo(context, FhcRoutes.churchHome);
  }

  @override
  Widget build(BuildContext context) {
    final tabLabels = _tabLabels;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'member.members', fallback: 'Members'),
            onBack: _goBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: fhcT(
                  context,
                  'common.search',
                  fallback: 'Search members…',
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.field),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (var i = 0; i < tabLabels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(
                      label: tabLabels[i],
                      selected: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: FhcAsyncBody<List<JsonObject>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.noMembers',
                fallback: 'No members',
              ),
              unavailableTitle: fhcT(
                context,
                'member.membersUnavailable',
                fallback: 'Members unavailable',
              ),
              builder: (context, members) {
                final visible = _visible(members);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      fhcT(
                        context,
                        'member.noMatchingMembers',
                        fallback: 'No members match this filter.',
                      ),
                      style: FhcTypography.caption,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: FhcColors.border),
                    itemBuilder: (context, index) {
                      final member = visible[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: FhcColors.mint,
                          child: Text(
                            () {
                              final name = _displayName(member);
                              return name.isEmpty
                                  ? '?'
                                  : name[0].toUpperCase();
                            }(),
                            style: const TextStyle(
                              color: FhcColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          _displayName(member),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            _roleLabel(member),
                            if (_joinedLabel(member).isNotEmpty)
                              _joinedLabel(member),
                          ].join(' · '),
                          style: FhcTypography.caption,
                        ),
                        trailing: _isLeader(member)
                            ? const Icon(
                                Icons.star,
                                size: 18,
                                color: FhcColors.orange,
                              )
                            : null,
                        onTap: () => fhcPush(context, FhcRoutes.messages),
                      );
                    },
                  ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? FhcColors.green : FhcColors.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? FhcColors.green : FhcColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : FhcColors.ink,
          ),
        ),
      ),
    );
  }
}

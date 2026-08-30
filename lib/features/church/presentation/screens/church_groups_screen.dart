import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class ChurchGroupsScreen extends StatefulWidget {
  const ChurchGroupsScreen({super.key, this.repository});

  final ChurchRepository? repository;

  @override
  State<ChurchGroupsScreen> createState() => _ChurchGroupsScreenState();
}

class _ChurchGroupsScreenState extends State<ChurchGroupsScreen> {
  String _query = '';
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();

  ChurchRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.churchRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) _load();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.groupsRequireApi',
            fallback:
                'Small groups require the authenticated groups API. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repository.listGroups();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? FhcAsyncValue.empty(
                  message: fhcT(
                    context,
                    'member.noGroupsYet',
                    fallback: 'No small groups are available yet.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  String _name(JsonObject group) =>
      '${group['name'] ?? group['title'] ?? 'Group'}'.trim();

  String _leader(JsonObject group) {
    final leader = group['leader'];
    if (leader is Map) {
      final name = '${leader['name'] ?? leader['display_name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    return '${group['leader_name'] ?? group['leader'] ?? '—'}';
  }

  int _memberCount(JsonObject group) {
    final raw = group['member_count'] ?? group['members_count'] ?? group['members'];
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  List<JsonObject> _visible(List<JsonObject> groups) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return groups;
    return groups
        .where((g) => _name(g).toLowerCase().contains(q))
        .toList();
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
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'member.smallGroups', fallback: 'SMALL GROUPS'),
            onBack: _goBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: fhcT(
                  context,
                  'member.searchGroups',
                  fallback: 'Search groups...',
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: FhcColors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.field),
                ),
              ),
            ),
          ),
          Expanded(
            child: FhcAsyncBody<List<JsonObject>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.noGroups',
                fallback: 'No groups',
              ),
              unavailableTitle: fhcT(
                context,
                'member.groupsUnavailable',
                fallback: 'Groups unavailable',
              ),
              builder: (context, groups) {
                final visible = _visible(groups);
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final group = visible[index];
                      final count = _memberCount(group);
                      return FhcSurfaceCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: InkWell(
                          onTap: () => fhcPush(context, FhcRoutes.groups),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: FhcColors.mint,
                                child: Icon(
                                  Icons.groups_outlined,
                                  color: FhcColors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _name(group),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      fhcT(
                                        context,
                                        'member.groupLeader',
                                        fallback: 'Leader: ${_leader(group)}',
                                        args: {'name': _leader(group)},
                                      ),
                                      style: FhcTypography.body,
                                    ),
                                    Text(
                                      fhcT(
                                        context,
                                        'member.memberCount',
                                        fallback: '$count Members',
                                        args: {'count': '$count'},
                                      ),
                                      style: FhcTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

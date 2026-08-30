import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, this.repository});

  final ChurchRepository? repository;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int _tab = 0;
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();
  String? _busyId;

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
            'online.groupsRequireApi',
            fallback:
                'Groups require the authenticated groups API. '
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
                    'online.noGroupsYet',
                    fallback: 'No groups are available yet.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  bool _isMember(JsonObject group) =>
      group['is_member'] == true ||
      group['joined'] == true ||
      '${group['membership_status'] ?? ''}'.toLowerCase() == 'active';

  String _id(JsonObject group) => '${group['id'] ?? ''}'.trim();

  String _name(JsonObject group) =>
      '${group['name'] ?? group['title'] ?? 'Group'}'.trim();

  String _description(JsonObject group) =>
      '${group['description'] ?? group['summary'] ?? ''}'.trim();

  String _memberLabel(JsonObject group) {
    final raw =
        group['member_count'] ?? group['members_count'] ?? group['members'];
    final count = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    return fhcT(
      context,
      'member.memberCount',
      fallback: '$count Members',
      args: {'count': '$count'},
    );
  }

  List<JsonObject> _visible(List<JsonObject> groups) {
    if (_tab == 1) return groups.where(_isMember).toList();
    return groups;
  }

  Future<void> _toggleJoin(JsonObject group) async {
    final repository = _repository;
    final id = _id(group);
    if (repository == null || id.isEmpty || _busyId != null) return;

    setState(() => _busyId = id);
    final result = _isMember(group)
        ? await repository.leaveGroup(id)
        : await repository.joinGroup(id);
    if (!mounted) return;
    setState(() => _busyId = null);

    switch (result) {
      case AppSuccess():
        await _load();
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.discover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'online.groups', fallback: 'Groups'),
            onBack: _back,
            backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Segment(
                      label: fhcT(
                        context,
                        'online.allGroups',
                        fallback: 'All Groups',
                      ),
                      active: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  Expanded(
                    child: _Segment(
                      label: fhcT(
                        context,
                        'online.myGroups',
                        fallback: 'My Groups',
                      ),
                      active: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FhcAsyncBody<List<JsonObject>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'online.noGroups',
                fallback: 'No groups',
              ),
              unavailableTitle: fhcT(
                context,
                'online.groupsUnavailable',
                fallback: 'Groups unavailable',
              ),
              builder: (context, groups) {
                final visible = _visible(groups);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      fhcT(
                        context,
                        'online.noGroupsInTab',
                        fallback: 'No groups in this tab.',
                      ),
                      style: FhcTypography.caption,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final group = visible[index];
                      final joined = _isMember(group);
                      final busy = _busyId == _id(group);
                      return Container(
                        padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(FhcRadius.card),
                          border: Border.all(color: FhcColors.border),
                          boxShadow: FhcElevation.card,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 28,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _description(group).isEmpty
                                        ? '—'
                                        : _description(group),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _memberLabel(group),
                                    style: FhcTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed:
                                  busy ? null : () => _toggleJoin(group),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FhcColors.green,
                                side: const BorderSide(color: FhcColors.border),
                                minimumSize: const Size(48, 34),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                busy
                                    ? '…'
                                    : joined
                                    ? fhcT(
                                      context,
                                      'online.leave',
                                      fallback: 'Leave',
                                    )
                                    : fhcT(
                                      context,
                                      'online.join',
                                      fallback: 'Join',
                                    ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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

class _Segment extends StatelessWidget {
  const _Segment({
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? FhcColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : FhcColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

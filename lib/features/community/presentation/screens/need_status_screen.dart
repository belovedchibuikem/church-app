import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Own pastoral needs via `GET /user/needs`.
class NeedStatusScreen extends StatefulWidget {
  const NeedStatusScreen({super.key, this.needRepository});

  final NeedRepository? needRepository;

  @override
  State<NeedStatusScreen> createState() => _NeedStatusScreenState();
}

class _NeedStatusScreenState extends State<NeedStatusScreen> {
  int _tab = 0;
  FhcAsyncValue<List<_NeedItem>> _state = const FhcAsyncValue.loading();

  NeedRepository? get _repo =>
      widget.needRepository ??
      AppServicesScope.maybeOf(context)?.needRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.needs.apiUnavailable',
            fallback:
                'Needs are waiting on the needs service. '
                'No fixture inbox is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listOwn();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        if (value.isEmpty) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'member.needs.noneYet',
                fallback: 'You have not shared a pastoral need yet.',
              ),
            );
          });
          return;
        }
        setState(() {
          _state = FhcAsyncValue.data([
            for (final item in value) _NeedItem.fromJson(item, context),
          ]);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  List<_NeedItem> _visible(List<_NeedItem> items) {
    if (_tab == 0) return items;
    final wanted = switch (_tab) {
      1 => 'open',
      2 => 'in_progress',
      3 => 'completed',
      _ => '',
    };
    return items.where((item) => item.statusKey == wanted).toList();
  }

  void _open(_NeedItem item) {
    if (item.id.isEmpty) return;
    fhcPush(context, '${FhcRoutes.needDetail}?id=${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      fhcT(context, 'common.all', fallback: 'All'),
      fhcT(context, 'member.needs.open', fallback: 'Open'),
      fhcT(context, 'member.needs.inProgress', fallback: 'In Progress'),
      fhcT(context, 'member.needs.completed', fallback: 'Completed'),
    ];

    return WorkflowPage(
      title: fhcT(context, 'member.needs.status', fallback: 'Need Status'),
      domain: WorkflowDomain.church,
      children: [
        WorkflowSectionTitle(
          fhcT(context, 'member.needs.mine', fallback: 'My Needs'),
        ),
        WorkflowSegments(
          labels: tabs,
          selected: _tab,
          onSelected: (index) => setState(() => _tab = index),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 420,
          child: FhcAsyncBody<List<_NeedItem>>(
            value: _state,
            onRetry: _load,
            emptyTitle: fhcT(
              context,
              'member.needs.emptyTitle',
              fallback: 'No needs',
            ),
            emptyMessage: fhcT(
              context,
              'member.needs.emptyCopy',
              fallback: 'Share a need and track its status here.',
            ),
            unavailableTitle: fhcT(
              context,
              'member.needs.unavailableTitle',
              fallback: 'Needs unavailable',
            ),
            builder: (context, items) {
              final visible = _visible(items);
              if (visible.isEmpty) {
                return FhcEmptyState(
                  title: fhcT(
                    context,
                    'member.needs.tabEmptyTitle',
                    fallback: 'Nothing in this tab',
                  ),
                  message: fhcT(
                    context,
                    'member.needs.tabEmptyCopy',
                    fallback: 'Try another status filter.',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return WorkflowCard(
                      child: WorkflowRow(
                        title: item.title,
                        subtitle: item.subtitle,
                        onTap: () => _open(item),
                        trailing: WorkflowPill(
                          item.statusLabel,
                          color: item.statusColor,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Detail for one own need (loaded from list; no `GET /user/needs/{id}`).
class NeedDetailsScreen extends StatefulWidget {
  const NeedDetailsScreen({super.key, this.needRepository, this.needId});

  final NeedRepository? needRepository;
  final String? needId;

  @override
  State<NeedDetailsScreen> createState() => _NeedDetailsScreenState();
}

class _NeedDetailsScreenState extends State<NeedDetailsScreen> {
  FhcAsyncValue<_NeedItem?> _state = const FhcAsyncValue.loading();

  NeedRepository? get _repo =>
      widget.needRepository ??
      AppServicesScope.maybeOf(context)?.needRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  Future<void> _load() async {
    final repo = _repo;
    final id =
        (widget.needId ?? FhcRouteArgs.entityIdOf(context) ?? '').trim();
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.needs.detailsUnavailable',
            fallback: 'Need details require the needs service.',
          ),
        );
      });
      return;
    }
    if (id.isEmpty) {
      setState(() {
        _state = FhcAsyncValue.empty(
          message: fhcT(
            context,
            'member.needs.noId',
            fallback: 'No need id was provided for this screen.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.listOwn();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        _NeedItem? match;
        for (final raw in value) {
          final item = _NeedItem.fromJson(raw, context);
          if (item.id == id) {
            match = item;
            break;
          }
        }
        setState(() {
          _state =
              match == null
                  ? FhcAsyncValue.empty(
                    message: fhcT(
                      context,
                      'member.needs.notInList',
                      fallback: 'That need was not found in your list.',
                    ),
                  )
                  : FhcAsyncValue.data(match);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'member.needs.details', fallback: 'Need Details'),
      domain: WorkflowDomain.church,
      children: [
        SizedBox(
          height: 480,
          child: FhcAsyncBody<_NeedItem?>(
            value: _state,
            onRetry: _load,
            emptyTitle: fhcT(
              context,
              'member.needs.notFoundTitle',
              fallback: 'Need not found',
            ),
            emptyMessage: fhcT(
              context,
              'member.needs.notFoundCopy',
              fallback: 'Return to My Needs and open an item again.',
            ),
            unavailableTitle: fhcT(
              context,
              'member.needs.unavailableTitle',
              fallback: 'Needs unavailable',
            ),
            builder: (context, item) {
              if (item == null) {
                return FhcEmptyState(
                  title: fhcT(
                    context,
                    'member.needs.notFoundTitle',
                    fallback: 'Need not found',
                  ),
                  message: fhcT(
                    context,
                    'member.needs.notFoundCopy',
                    fallback: 'Return to My Needs and open an item again.',
                  ),
                );
              }
              return ListView(
                children: [
                  WorkflowCard(
                    child: WorkflowRow(
                      title: item.title,
                      subtitle: item.subtitle,
                      trailing: WorkflowPill(
                        item.statusLabel,
                        color: item.statusColor,
                      ),
                    ),
                  ),
                  WorkflowSectionTitle(
                    fhcT(
                      context,
                      'member.needs.requestInformation',
                      fallback: 'Request Information',
                    ),
                  ),
                  WorkflowCard(
                    child: Column(
                      children: [
                        WorkflowRow(
                          title: fhcT(
                            context,
                            'member.needs.category',
                            fallback: 'Category',
                          ),
                          subtitle: item.category,
                          leading: Icons.category_outlined,
                          trailing: const SizedBox.shrink(),
                        ),
                        WorkflowRow(
                          title: fhcT(
                            context,
                            'member.needs.description',
                            fallback: 'Description',
                          ),
                          subtitle: item.summary,
                          leading: Icons.notes_outlined,
                          trailing: const SizedBox.shrink(),
                        ),
                        WorkflowRow(
                          title: fhcT(
                            context,
                            'member.needs.statusLabel',
                            fallback: 'Status',
                          ),
                          subtitle: item.statusLabel,
                          leading: Icons.flag_outlined,
                          trailing: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NeedItem {
  const _NeedItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.statusKey,
    required this.statusLabel,
    required this.statusColor,
    required this.subtitle,
  });

  factory _NeedItem.fromJson(JsonObject json, BuildContext context) {
    final status = '${json['status'] ?? 'open'}'.toLowerCase();
    final summary = '${json['summary'] ?? json['body'] ?? json['description'] ?? ''}';
    final category =
        '${json['category'] ?? fhcT(context, 'member.needs', fallback: 'Need')}';
    final created = '${json['created_at'] ?? ''}';
    final parsed = DateTime.tryParse(created);
    final dateLabel =
        parsed == null
            ? (created.isEmpty ? '—' : created)
            : fhcT(
                context,
                'member.needs.requestedOn',
                args: {
                  'date':
                      '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}',
                },
                fallback: 'Requested on {date}',
              );

    final statusKey = switch (status) {
      'open' || 'new' || 'submitted' => 'open',
      'in_progress' || 'review' || 'under_review' || 'active' => 'in_progress',
      'completed' || 'closed' || 'resolved' || 'done' => 'completed',
      _ => status,
    };

    return _NeedItem(
      id: '${json['id'] ?? json['ulid'] ?? ''}',
      title: summary.isEmpty
          ? category
          : (summary.length > 48 ? '${summary.substring(0, 45)}…' : summary),
      summary: summary.isEmpty
          ? fhcT(
              context,
              'member.needs.noDescription',
              fallback: 'No description provided.',
            )
          : summary,
      category: category,
      statusKey: statusKey,
      statusLabel: switch (statusKey) {
        'open' => fhcT(context, 'member.needs.open', fallback: 'Open'),
        'in_progress' => fhcT(
          context,
          'member.needs.inProgress',
          fallback: 'In Progress',
        ),
        'completed' => fhcT(
          context,
          'member.needs.completed',
          fallback: 'Completed',
        ),
        _ => status,
      },
      statusColor: switch (statusKey) {
        'open' => FhcColors.green,
        'in_progress' => FhcColors.gold,
        'completed' => FhcColors.muted,
        _ => FhcColors.muted,
      },
      subtitle: dateLabel,
    );
  }

  final String id;
  final String title;
  final String summary;
  final String category;
  final String statusKey;
  final String statusLabel;
  final Color statusColor;
  final String subtitle;
}

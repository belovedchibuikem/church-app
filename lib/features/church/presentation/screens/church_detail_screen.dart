import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/church_repository.dart';
import '../membership_join.dart';

class ChurchDetailScreen extends StatefulWidget {
  const ChurchDetailScreen({
    super.key,
    this.churchId,
    this.repository,
  });

  final String? churchId;
  final ChurchRepositoryImpl? repository;

  @override
  State<ChurchDetailScreen> createState() => _ChurchDetailScreenState();
}

class _ChurchDetailScreenState extends State<ChurchDetailScreen> {
  FhcAsyncValue<ChurchSummary> _state = const FhcAsyncValue.loading();
  bool _membershipBusy = false;
  bool _started = false;

  ChurchRepositoryImpl? get _repository {
    final injected = widget.repository;
    if (injected != null) return injected;
    final fromServices = AppServicesScope.maybeOf(context)?.churchRepository;
    return fromServices is ChurchRepositoryImpl ? fromServices : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _resolveAndLoad();
    }
  }

  String? _resolveChurchId() {
    final fromProp = widget.churchId?.trim();
    if (fromProp != null && fromProp.isNotEmpty) return fromProp;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is FhcRouteArgs &&
        args.entityId != null &&
        args.entityId!.trim().isNotEmpty) {
      return args.entityId!.trim();
    }
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final mapped = args['entityId'] ?? args['churchId'] ?? args['id'];
      if (mapped is String && mapped.trim().isNotEmpty) return mapped.trim();
    }

    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    for (final prefix in const ['/discover/church/', '/church/detail/']) {
      if (routeName.startsWith(prefix)) {
        final id = routeName.substring(prefix.length).split('/').first.trim();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  String get _membershipAction => fhcT(
        context,
        'church.membershipAction',
        fallback: 'Membership for this church',
      );

  Future<void> _resolveAndLoad() async {
    final id = _resolveChurchId();
    if (id == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'errors.churchIdMissing',
            fallback: 'Church id is missing from this route.',
          ),
        );
      });
      return;
    }
    await _load(id);
  }

  Future<void> _load(String id) async {
    final repo = _repository;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'errors.churchDetailWaiting',
            fallback:
                'Church detail is waiting on AppServices churchRepository. '
                'No fixture profile is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());

    final result = await repo.getChurchById(id);
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(value));
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          setState(() {
            _state = FhcAsyncValue.unavailable(message: failure.message);
          });
          return;
        }
        if (failure is NotFoundFailure) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message: fhcT(
                context,
                'errors.churchUnpublished',
                fallback: 'This church is unavailable or unpublished.',
              ),
            );
          });
          return;
        }
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _requestMembership(
    ChurchSummary church, {
    String? homeChurchId,
    bool confirmTransfer = false,
  }) async {
    if (_membershipBusy) return;
    final repo = _repository;
    if (repo == null) {
      await fhcApiUnavailable(
        context,
        action: _membershipAction,
      );
      return;
    }

    setState(() => _membershipBusy = true);
    final result = homeChurchId == null || homeChurchId.isEmpty
        ? await repo.requestMembership(
            church.id,
            confirmTransfer: confirmTransfer,
          )
        : await repo.joinHomeChurch(
            homeChurchId,
            confirmTransfer: confirmTransfer,
          );
    if (!mounted) return;
    setState(() => _membershipBusy = false);

    switch (result) {
      case AppSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fhcT(
                context,
                'church.membershipStarted',
                fallback: 'You have joined this church. Open My Church for details and updates.',
              ),
            ),
          ),
        );
        fhcPush(context, FhcRoutes.myChurch);
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          await fhcApiUnavailable(
            context,
            action: _membershipAction,
          );
          return;
        }
        if (isMembershipTransferRequired(failure)) {
          final confirmed = await confirmMembershipTransfer(context, failure);
          if (confirmed && mounted) {
            await _requestMembership(
              church,
              homeChurchId: homeChurchId,
              confirmTransfer: true,
            );
          }
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  void back() {
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
          _Header(onBack: back),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final id = _resolveChurchId();
                if (id != null) await _load(id);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  FhcAsyncBody<ChurchSummary>(
                    value: _state,
                    onRetry: () {
                      final id = _resolveChurchId();
                      if (id != null) _load(id);
                    },
                    emptyTitle: fhcT(
                      context,
                      'errors.churchNotFound',
                      fallback: 'Church not found',
                    ),
                    unavailableTitle: fhcT(
                      context,
                      'errors.churchUnavailable',
                      fallback: 'Church unavailable',
                    ),
                    builder: (context, church) {
                      final country = church.location.countryName;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: AspectRatio(
                              aspectRatio: 1.63,
                              child: Image.asset(
                                'assets/images/church_grace_hero.png',
                                fit: BoxFit.cover,
                                semanticLabel: fhcT(
                                  context,
                                  'church.buildingA11y',
                                  args: {'name': church.name},
                                  fallback: '{name} building',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            church.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: FhcColors.green,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  church.location.placeLabel,
                                  style: FhcTypography.caption,
                                ),
                              ),
                            ],
                          ),
                          if (church.location.administrativeUnitName !=
                              null) ...[
                            const SizedBox(height: 8),
                            Text(
                              church.location.administrativeUnitName!,
                              style: FhcTypography.caption,
                            ),
                          ],
                          const SizedBox(height: 22),
                          _Heading(
                            fhcT(context, 'common.about', fallback: 'About'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            country == null
                                ? fhcT(
                                    context,
                                    'church.community',
                                    fallback:
                                        'A Family House church community.',
                                  )
                                : fhcT(
                                    context,
                                    'church.communityIn',
                                    args: {'country': country},
                                    fallback:
                                        'A Family House church community in {country}.',
                                  ),
                            style: const TextStyle(fontSize: 13, height: 1.45),
                          ),
                          if (church.publishedAt != null) ...[
                            const SizedBox(height: 20),
                            _Heading(
                              fhcT(
                                context,
                                'church.published',
                                fallback: 'Published',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatPublishedDate(church.publishedAt!),
                              style: const TextStyle(fontSize: 13, height: 1.45),
                            ),
                          ],
                          if (church.homeChurches.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _Heading(
                              fhcT(
                                context,
                                'church.homeChurchesToJoin',
                                fallback: 'Home churches',
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final home in church.homeChurches)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(home.name),
                                subtitle: Text(
                                  home.meetingSchedules.isEmpty
                                      ? (home.status ?? '')
                                      : home.meetingSchedules
                                          .map((row) =>
                                              '${row['day'] ?? ''} ${row['time'] ?? ''} · ${row['activity'] ?? ''}'
                                                  .trim())
                                          .join('\n'),
                                ),
                                trailing: IconButton(
                                  tooltip: fhcT(
                                    context,
                                    'church.joinHomeChurch',
                                    fallback: 'Join this home church',
                                  ),
                                  onPressed: _membershipBusy
                                      ? null
                                      : () => _requestMembership(
                                            church,
                                            homeChurchId: home.id,
                                          ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            fhcT(
                              context,
                              'church.membershipGroupsCopy',
                              fallback:
                                  'Request membership to connect with this church. '
                                  'Groups and documents open once your membership is active.',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: FhcColors.muted,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_state case FhcAsyncData<ChurchSummary>(:final value))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Actions(
                membershipBusy: _membershipBusy,
                onMembership: () => _requestMembership(value),
              ),
            ),
        ],
      ),
    );
  }

  String _formatPublishedDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final local = parsed.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: fhcT(context, 'common.back', fallback: 'Back'),
              icon: const Icon(Icons.chevron_left, size: 28),
            ),
            IconButton(
              onPressed:
                  () => fhcApiUnavailable(
                    context,
                    action: fhcT(
                      context,
                      'church.shareAction',
                      fallback: 'Sharing this church profile',
                    ),
                  ),
              tooltip: fhcT(context, 'church.share', fallback: 'Share'),
              icon: const Icon(Icons.ios_share_outlined, size: 23),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onMembership,
    required this.membershipBusy,
  });

  final VoidCallback onMembership;
  final bool membershipBusy;

  static const _secondary = <(IconData, String, String)>[
    (Icons.groups_outlined, 'church.groups', 'Groups'),
    (Icons.description_outlined, 'church.documents', 'Documents'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: membershipBusy ? null : onMembership,
              icon: membershipBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, size: 16),
              label: Text(
                fhcT(context, 'church.join', fallback: 'Join'),
                style: const TextStyle(fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: FhcColors.greenDark,
                side: const BorderSide(color: FhcColors.green),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        for (final item in _secondary) ...[
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed:
                    () => fhcApiUnavailable(
                      context,
                      action: fhcT(
                        context,
                        'church.featureAction',
                        args: {'feature': item.$3},
                        fallback: '{feature} for this church',
                      ),
                    ),
                icon: Icon(item.$1, size: 16),
                label: Text(
                  fhcT(context, item.$2, fallback: item.$3),
                  style: const TextStyle(fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FhcColors.greenDark,
                  side: const BorderSide(color: FhcColors.green),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

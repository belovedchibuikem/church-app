import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key, this.repository});

  final ChurchRepository? repository;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
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
            'member.announcementsRequireApi',
            fallback:
                'Announcements require the authenticated announcements API. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repository.listAnnouncements();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? FhcAsyncValue.empty(
                  message: fhcT(
                    context,
                    'member.noAnnouncementsYet',
                    fallback: 'No announcements yet.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  String _title(JsonObject item) =>
      '${item['title'] ?? item['subject'] ?? 'Announcement'}'.trim();

  String _snippet(JsonObject item) =>
      '${item['summary'] ?? item['body'] ?? item['excerpt'] ?? ''}'.trim();

  String _date(JsonObject item) {
    final raw = '${item['published_at'] ?? item['created_at'] ?? ''}'.trim();
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.churchHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(
              context,
              'member.announcements',
              fallback: 'Announcements',
            ),
            onBack: _goBack,
          ),
          Expanded(
            child: FhcAsyncBody<List<JsonObject>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.noAnnouncements',
                fallback: 'No announcements',
              ),
              unavailableTitle: fhcT(
                context,
                'member.announcementsUnavailable',
                fallback: 'Announcements unavailable',
              ),
              builder: (context, items) {
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FhcSurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: InkWell(
                          onTap: () =>
                              fhcPush(context, FhcRoutes.notifications),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title(item),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_date(item).isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(_date(item), style: FhcTypography.caption),
                              ],
                              if (_snippet(item).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _snippet(item),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: FhcTypography.body,
                                ),
                              ],
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

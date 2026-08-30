import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, this.repository});

  final EventRepository? repository;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _tab = 0;
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();
  bool _loadedTab = false;

  EventRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.eventRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedTab) {
      _loadedTab = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'events.catalogueRequiresApi',
            fallback:
                'Events catalogue requires the Laravel public events API. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final AppResult<List<JsonObject>> result;
    if (_tab == 0) {
      result = await repository.list(const {'sort': 'starts_at'});
    } else {
      final when = _tab == 1 ? 'upcoming' : 'past';
      result = await repository.listMyRegistrations(when: when);
    }
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? FhcAsyncValue.empty(
                  message: fhcT(
                    context,
                    'events.publishedAppearHere',
                    fallback:
                        'When events are published, they will appear here.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  void _selectTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    _load();
  }

  void _openEvent(String id) {
    if (id.isEmpty) return;
    Navigator.of(context).pushNamed('/events/$id', arguments: id);
  }

  void _openRegister(String id) {
    if (id.isEmpty) return;
    Navigator.of(context).pushNamed('/events/$id/register', arguments: id);
  }

  void _openTicket(JsonObject registration) {
    final id =
        '${registration['id'] ?? registration['registration_id'] ?? ''}'.trim();
    if (id.isEmpty) return;
    Navigator.of(context).pushNamed('/events/tickets', arguments: id);
  }

  String _monthLabel(int month) {
    const keys = [
      'events.monthJan',
      'events.monthFeb',
      'events.monthMar',
      'events.monthApr',
      'events.monthMay',
      'events.monthJun',
      'events.monthJul',
      'events.monthAug',
      'events.monthSep',
      'events.monthOct',
      'events.monthNov',
      'events.monthDec',
    ];
    const fallbacks = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return fhcT(context, keys[month - 1], fallback: fallbacks[month - 1]);
  }

  String _formatDate(DateTime d) {
    return '${_monthLabel(d.month)} ${d.day}, ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12
        ? fhcT(context, 'events.pm', fallback: 'PM')
        : fhcT(context, 'events.am', fallback: 'AM');
    return '$hour:$minute $suffix';
  }

  JsonObject _eventOf(JsonObject row) {
    final nested = row['event'];
    if (nested is Map) {
      return Map<String, Object?>.from(
        nested.map((k, v) => MapEntry('$k', v)),
      );
    }
    return row;
  }

  String _when(JsonObject event) {
    final startsAt = DateTime.tryParse('${event['starts_at'] ?? ''}');
    final endsAt = DateTime.tryParse('${event['ends_at'] ?? ''}');
    if (startsAt == null) {
      return fhcT(context, 'events.scheduleTba', fallback: 'Schedule TBA');
    }
    final localStart = startsAt.toLocal();
    if (endsAt != null) {
      final localEnd = endsAt.toLocal();
      if (localStart.year == localEnd.year &&
          localStart.month == localEnd.month &&
          localStart.day == localEnd.day) {
        return '${_formatDate(localStart)}  •  ${_formatTime(localStart)}';
      }
      return '${_formatDate(localStart)} – ${_formatDate(localEnd)}';
    }
    return '${_formatDate(localStart)}  •  ${_formatTime(localStart)}';
  }

  String _where(JsonObject event) {
    final location = event['location'];
    if (location is Map) {
      final name = '${location['name'] ?? ''}'.trim();
      final locality = '${location['locality'] ?? ''}'.trim();
      if (name.isNotEmpty && locality.isNotEmpty) return '$name, $locality';
      if (name.isNotEmpty) return name;
      if (locality.isNotEmpty) return locality;
    }
    return fhcT(context, 'events.locationTba', fallback: 'Location TBA');
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'nav.events', fallback: 'Events'),
          ),
          Row(
            children: [
              for (var index = 0; index < 3; index++)
                Expanded(
                  child: _EventTab(
                    label: [
                      fhcT(context, 'events.upcoming', fallback: 'Upcoming'),
                      fhcT(context, 'events.myEvents', fallback: 'My Events'),
                      fhcT(context, 'events.past', fallback: 'Past'),
                    ][index],
                    active: _tab == index,
                    onTap: () => _selectTab(index),
                  ),
                ),
            ],
          ),
          Expanded(child: _buildBody()),
          const FhcBottomNavigation(selected: 3),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FhcAsyncBody<List<JsonObject>>(
      value: _state,
      onRetry: _load,
      emptyTitle: fhcT(
        context,
        'events.noUpcoming',
        fallback: 'No upcoming events',
      ),
      emptyMessage: fhcT(
        context,
        'events.publishedAppearHere',
        fallback: 'When events are published, they will appear here.',
      ),
      unavailableTitle: fhcT(
        context,
        'events.unavailable',
        fallback: 'Events unavailable',
      ),
      builder: (context, rows) {
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              final event = _eventOf(row);
              final id = '${event['id'] ?? row['event_id'] ?? ''}'.trim();
              final name =
                  '${event['name'] ?? row['event_name'] ?? fhcT(context, 'events.event', fallback: 'Event')}';
              final ticketCode =
                  '${row['ticket_code'] ?? row['code'] ?? ''}'.trim();
              final isRegistrationTab = _tab != 0;
              return _EventRow(
                title: name,
                when: _when(event),
                where: ticketCode.isNotEmpty
                    ? '${_where(event)}  •  $ticketCode'
                    : _where(event),
                actionLabel: isRegistrationTab
                    ? fhcT(context, 'events.ticket', fallback: 'Ticket')
                    : fhcT(context, 'common.register', fallback: 'Register'),
                onOpen: () => _openEvent(id),
                onAction: () => isRegistrationTab
                    ? _openTicket(row)
                    : _openRegister(id),
              );
            },
          ),
        );
      },
    );
  }
}

class _EventTab extends StatelessWidget {
  const _EventTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? FhcColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
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

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.title,
    required this.when,
    required this.where,
    required this.onOpen,
    required this.onAction,
    required this.actionLabel,
  });

  final String title;
  final String when;
  final String where;
  final VoidCallback onOpen;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        height: 106,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FhcColors.border)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: FhcColors.green.withValues(alpha: 0.12),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.event, color: FhcColors.green),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(when, style: FhcTypography.caption),
                  const SizedBox(height: 3),
                  Text(where, style: FhcTypography.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

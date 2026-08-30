import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, this.eventId, this.repository});

  final String? eventId;
  final EventRepository? repository;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  String? _error;
  JsonObject? _event;
  bool _started = false;

  static const _reserved = {
    'detail',
    'register',
    'payment',
    'tickets',
    'attendance',
    'feedback',
  };

  EventRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.eventRepository;

  String? get _resolvedId {
    final explicit = widget.eventId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is FhcRouteArgs && args.extra is String) {
      final extra = (args.extra as String).trim();
      if (extra.isNotEmpty) return extra;
    }
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id = args['id'] ?? args['eventId'] ?? args['entityId'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }

    final name = ModalRoute.of(context)?.settings.name ?? '';
    final parts = name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2 && parts.first == 'events') {
      final candidate = parts[1];
      if (!_reserved.contains(candidate)) return candidate;
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _loading = false;
        _error = fhcT(
          context,
          'events.detailsRequireApi',
          fallback:
              'Event details require the Laravel public events API. '
              'No fixture detail is shown.',
        );
      });
      return;
    }

    final id = _resolvedId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = fhcT(
          context,
          'events.openFromCatalogue',
          fallback:
              'Open an event from the catalogue so its public id can be loaded.',
        );
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await repository.get(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _event = value;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _event = null;
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.events);
    }
  }

  void _openRegister() {
    final id = _resolvedId ?? '${_event?['id'] ?? ''}';
    if (id.isEmpty) {
      fhcApiUnavailable(
        context,
        action: fhcT(
          context,
          'events.registeringAction',
          fallback: 'Registering for an event',
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed('/events/$id/register', arguments: id);
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

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null) {
      return fhcT(context, 'events.scheduleTba', fallback: 'Schedule TBA');
    }
    String fmt(DateTime d) {
      return '${_monthLabel(d.month)} ${d.day}, ${d.year}';
    }

    final localStart = start.toLocal();
    if (end == null) return fmt(localStart);
    final localEnd = end.toLocal();
    if (localStart.year == localEnd.year &&
        localStart.month == localEnd.month &&
        localStart.day == localEnd.day) {
      return fmt(localStart);
    }
    return '${fmt(localStart)} – ${fmt(localEnd)}';
  }

  String _formatTime(DateTime? start) {
    if (start == null) {
      return fhcT(context, 'events.timeTba', fallback: 'Time TBA');
    }
    final d = start.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12
        ? fhcT(context, 'events.pm', fallback: 'PM')
        : fhcT(context, 'events.am', fallback: 'AM');
    return '$hour:$minute $suffix';
  }

  String _locationLabel(JsonObject event) {
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

  String _feeLabel(JsonObject event) {
    final fee = event['fee'];
    if (fee is! Map) {
      return fhcT(context, 'events.freeAdmission', fallback: 'Free admission');
    }
    final minor = fee['amount_minor'];
    final currency = '${fee['currency'] ?? ''}'.trim();
    if (minor is! num) {
      return fhcT(context, 'events.freeAdmission', fallback: 'Free admission');
    }
    final major = minor / 100;
    final amount = major == major.roundToDouble()
        ? major.toStringAsFixed(0)
        : major.toStringAsFixed(2);
    return currency.isEmpty ? amount : '$currency $amount';
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final eventFallback = fhcT(context, 'events.event', fallback: 'Event');
    final name = event == null ? eventFallback : '${event['name'] ?? eventFallback}';
    final startsAt = event == null
        ? null
        : DateTime.tryParse('${event['starts_at'] ?? ''}');
    final endsAt = event == null
        ? null
        : DateTime.tryParse('${event['ends_at'] ?? ''}');
    final category =
        event == null ? '' : '${event['category'] ?? ''}'.trim();

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'events.details', fallback: 'EVENT DETAILS'),
            onBack: _goBack,
            trailing: IconButton(
              onPressed: () => fhcApiUnavailable(
                context,
                action: fhcT(
                  context,
                  'events.sharingAction',
                  fallback: 'Sharing an event',
                ),
              ),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'events.share', fallback: 'Share'),
            ),
          ),
          Expanded(child: _buildBody(name, startsAt, endsAt, category)),
          if (!_loading && _error == null && event != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FhcPrimaryButton(
                label: fhcT(
                  context,
                  'events.registerNow',
                  fallback: 'Register Now',
                ),
                onPressed: _openRegister,
              ),
            ),
          const FhcBottomNavigation(selected: 3),
        ],
      ),
    );
  }

  Widget _buildBody(
    String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String category,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return FhcErrorState(
        title: fhcT(
          context,
          'events.unableToLoad',
          fallback: 'Unable to load event',
        ),
        message: _error!,
        onRetry: _load,
      );
    }
    final event = _event;
    if (event == null) {
      return FhcEmptyState(
        title: fhcT(context, 'events.unavailable', fallback: 'Event unavailable'),
        message: fhcT(
          context,
          'events.couldNotBeFound',
          fallback: 'This event could not be found.',
        ),
        icon: Icons.event_busy_outlined,
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _EventHero(title: name, category: category),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const _UpcomingBadge(),
              const SizedBox(height: 14),
              _InfoLine(
                icon: Icons.calendar_today_outlined,
                text: _formatRange(startsAt, endsAt),
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.schedule_outlined,
                text: _formatTime(startsAt),
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.place_outlined,
                text: _locationLabel(event),
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.payments_outlined,
                text: _feeLabel(event),
              ),
              if (category.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  fhcT(context, 'events.category', fallback: 'Category'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: FhcColors.muted,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                fhcT(context, 'events.registration', fallback: 'Registration'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fhcT(
                  context,
                  'events.registrationCopy',
                  fallback:
                      'Signed-in members can register with the authenticated person '
                      'profile via POST /user/events/{event}/registrations.',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: FhcColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.title, required this.category});

  final String title;
  final String category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(
            color: FhcColors.greenDeep,
            child: Center(
              child: Icon(Icons.event, size: 56, color: FhcColors.white),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xB3000000)],
              ),
            ),
          ),
          const Positioned(left: 12, top: 12, child: _UpcomingBadge()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FhcColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0.2,
                  ),
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FhcColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBadge extends StatelessWidget {
  const _UpcomingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FhcColors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        fhcT(context, 'events.upcoming', fallback: 'Upcoming'),
        maxLines: 1,
        style: const TextStyle(
          color: FhcColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FhcColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

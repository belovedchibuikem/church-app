import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../press/presentation/screens/press_book_screen.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/payment_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.paymentRepository});

  final PaymentRepository? paymentRepository;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  FhcAsyncValue<List<JsonObject>> _state = const FhcAsyncValue.loading();
  List<JsonObject> _intents = const [];

  PaymentRepository? get _repo =>
      widget.paymentRepository ??
      AppServicesScope.maybeOf(context)?.paymentRepository;

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
            'give.walletRequiresApi',
            fallback: 'Wallet transactions require the Laravel payments API.',
          ),
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final txns = await repo.listTransactions();
    final intents = await repo.listIntents();
    if (!mounted) return;
    switch (txns) {
      case AppSuccess(:final value):
        setState(() {
          _intents = switch (intents) {
            AppSuccess(:final value) => value,
            AppError() => const [],
          };
          _state =
              value.isEmpty
                  ? FhcAsyncValue.empty(
                    message: fhcT(
                      context,
                      'give.noWalletTransactionsYet',
                      fallback: 'No wallet transactions yet.',
                    ),
                  )
                  : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() {
          _state = FhcAsyncValue.error(
            failure.code == 'PAYMENT_GOVERNANCE_DENIED' ||
                    failure is PaymentFailure
                ? PaymentFailure(
                    paymentFailureMessage(failure),
                    code: failure.code,
                  )
                : failure is ForbiddenFailure
                ? ForbiddenFailure(
                    failure.message.isNotEmpty
                        ? failure.message
                        : fhcT(
                            context,
                            'give.walletAccessRestricted',
                            fallback:
                                'Wallet access is restricted by payment governance.',
                          ),
                  )
                : failure,
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingIntents =
        _intents
            .where((item) => '${item['status']}' == 'pending_provider')
            .length;

    return WorkflowPage(
      title: fhcT(context, 'give.wallet', fallback: 'My Wallet'),
      domain: WorkflowDomain.community,
      actionLabel: fhcT(
        context,
        'give.viewAllTransactions',
        fallback: 'View All Transactions',
      ),
      onAction: () => fhcPush(context, FhcRoutes.giveHistory),
      backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
      children: [
        WorkflowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fhcT(context, 'give.balance', fallback: 'Balance'),
                style: FhcTypography.caption,
              ),
              const SizedBox(height: 8),
              Text(
                fhcT(context, 'give.serverOwned', fallback: 'Server-owned'),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                pendingIntents > 0
                    ? fhcT(
                        context,
                        'give.pendingIntentsCopy',
                        args: {'count': '$pendingIntents'},
                        fallback:
                            '{count} pending giving intent(s). Balances come '
                            'from confirmed payment transactions — no client-side '
                            'wallet balance is invented.',
                      )
                    : fhcT(
                        context,
                        'give.walletBalanceCopy',
                        fallback:
                            'Balances come from payment transactions once the API '
                            'confirms them. No client-side wallet balance is invented.',
                      ),
                style: FhcTypography.caption,
              ),
            ],
          ),
        ),
        WorkflowSectionTitle(
          fhcT(
            context,
            'give.recentTransactions',
            fallback: 'Recent Transactions',
          ),
        ),
        SizedBox(
          height: 320,
          child: FhcAsyncBody<List<JsonObject>>(
            value: _state,
            onRetry: _load,
            emptyTitle: fhcT(
              context,
              'give.noTransactions',
              fallback: 'No transactions',
            ),
            emptyMessage: fhcT(
              context,
              'give.completedPaymentsAppearHere',
              fallback: 'Completed payments will appear here.',
            ),
            unavailableTitle: fhcT(
              context,
              'give.walletUnavailable',
              fallback: 'Wallet unavailable',
            ),
            builder: (context, items) {
              return WorkflowCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
                  children: [
                    for (final item in items.take(8))
              WorkflowRow(
                        title:
                            '${item['purpose_code'] ?? item['purpose'] ?? item['title'] ?? fhcT(context, 'member.giving', fallback: 'Giving')}',
                        subtitle:
                            '${item['occurred_at'] ?? item['created_at'] ?? item['status'] ?? ''}',
                leading: Icons.account_balance_wallet_outlined,
                trailing: Text(
                          _walletAmountLabel(item),
                          style: const TextStyle(
                    color: FhcColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                        onTap: () {
                          final id = '${item['id'] ?? ''}';
                          fhcPush(
                            context,
                            id.isEmpty
                                ? '/payments/transaction'
                                : '/payments/transaction?id=${Uri.encodeComponent(id)}',
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _walletAmountLabel(JsonObject item) {
    final minor = paymentAmountMinorOf(item);
    if (minor == null) return '—';
    return formatPaymentAmountMinor(
      minor,
      currency: '${item['currency'] ?? 'NGN'}',
    );
  }
}

class EventRegistrationScreen extends StatefulWidget {
  const EventRegistrationScreen({
    super.key,
    this.eventId,
    this.eventRepository,
  });

  final String? eventId;
  final EventRepository? eventRepository;

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  FhcAsyncValue<JsonObject> _eventState = const FhcAsyncValue.loading();
  bool _submitting = false;
  String? _submitError;
  bool _started = false;

  EventRepository? get _repo =>
      widget.eventRepository ??
      AppServicesScope.maybeOf(context)?.eventRepository;

  String? get _resolvedId {
    final explicit = widget.eventId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
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
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _eventState = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'events.registrationRequiresApi',
            fallback:
                'Event registration requires the Laravel events API. '
                'No fixture registration form is shown.',
          ),
        );
      });
      return;
    }
    final id = _resolvedId;
    if (id == null) {
      setState(() {
        _eventState = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'events.registrationNeedsPublicId',
            fallback:
                'Open an event from the catalogue to register. '
                'A public event id is required.',
          ),
        );
      });
      return;
    }
    setState(() => _eventState = const FhcAsyncValue.loading());
    final result = await repo.get(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _eventState = FhcAsyncValue.data(value));
      case AppError(:final failure):
        setState(() => _eventState = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _register() async {
    final repo = _repo;
    final id = _resolvedId ??
        (_eventState is FhcAsyncData<JsonObject>
            ? '${(_eventState as FhcAsyncData<JsonObject>).value['id'] ?? ''}'
            : '');
    if (repo == null || id.isEmpty) {
      setState(() {
        _submitError = fhcT(
          context,
          'events.registrationRequiresAuth',
          fallback:
              'Registration requires an authenticated events API and event id.',
        );
      });
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final result = await repo.register(id, const {});
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _submitting = false);
        final registrationId = '${value['id'] ?? value['public_id'] ?? ''}'.trim();
        final status = '${value['status'] ?? ''}'.toLowerCase();
        final paymentRequired = value['payment_required'] == true ||
            status == 'payment_pending';
        if (registrationId.isNotEmpty && paymentRequired) {
          fhcPush(
            context,
            '/events/payment?id=${Uri.encodeComponent(registrationId)}',
          );
        } else if (registrationId.isNotEmpty) {
          fhcPush(context, '/events/$registrationId/ticket');
        } else {
          fhcPush(context, FhcRoutes.eventTickets);
        }
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _submitError = failure.message;
        });
    }
  }

  String _schedule(JsonObject event) {
    final startsAt = DateTime.tryParse('${event['starts_at'] ?? ''}');
    final endsAt = DateTime.tryParse('${event['ends_at'] ?? ''}');
    if (startsAt == null) {
      return fhcT(context, 'events.scheduleTba', fallback: 'Schedule TBA');
    }
    String fmt(DateTime d) {
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${fhcT(context, keys[d.month - 1], fallback: fallbacks[d.month - 1])} ${d.day}, ${d.year}';
    }
    final localStart = startsAt.toLocal();
    if (endsAt == null) return fmt(localStart);
    return '${fmt(localStart)} – ${fmt(endsAt.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _eventState is FhcAsyncData<JsonObject> && !_submitting;
    return WorkflowPage(
      title: fhcT(
        context,
        'events.registrationTitle',
        fallback: 'Event Registration',
      ),
      domain: WorkflowDomain.church,
      actionLabel: _submitting
          ? fhcT(context, 'events.registering', fallback: 'Registering…')
          : fhcT(context, 'events.registerNow', fallback: 'Register Now'),
      onAction: canSubmit ? _register : null,
      backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
      children: [
        SizedBox(
          height: 280,
          child: FhcAsyncBody<JsonObject>(
            value: _eventState,
            onRetry: _load,
            unavailableTitle: fhcT(
              context,
              'events.registrationUnavailable',
              fallback: 'Registration unavailable',
            ),
            builder: (context, event) {
              final name =
                  '${event['name'] ?? fhcT(context, 'events.event', fallback: 'Event')}';
              final category = '${event['category'] ?? ''}'.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        WorkflowCard(
          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(category, style: FhcTypography.caption),
                        ],
                        const SizedBox(height: 8),
                        Text(_schedule(event), style: FhcTypography.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fhcT(
                      context,
                      'events.registrationUsesProfile',
                      fallback:
                          'Registration uses your signed-in person profile. '
                          'Attendee fields are owned by Laravel and are not collected here.',
                    ),
                    style: FhcTypography.caption,
                  ),
                ],
              );
            },
          ),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            _submitError!,
            style: const TextStyle(color: FhcColors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class EventPaymentScreen extends StatefulWidget {
  const EventPaymentScreen({
    super.key,
    this.registrationId,
    this.paymentRepository,
    this.eventRepository,
  });

  final String? registrationId;
  final PaymentRepository? paymentRepository;
  final EventRepository? eventRepository;

  @override
  State<EventPaymentScreen> createState() => _EventPaymentScreenState();
}

class _EventPaymentScreenState extends State<EventPaymentScreen> {
  bool _submitting = false;
  bool _started = false;
  String? _error;
  JsonObject? _registration;

  PaymentRepository? get _payments =>
      widget.paymentRepository ??
      AppServicesScope.maybeOf(context)?.paymentRepository;

  EventRepository? get _events =>
      widget.eventRepository ??
      AppServicesScope.maybeOf(context)?.eventRepository;

  String? get _resolvedId {
    final explicit = widget.registrationId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final events = _events;
    final id = _resolvedId;
    if (events == null || id == null || id.isEmpty) {
      setState(() {
        _error = fhcT(
          context,
          'events.paymentOpenFromRegistration',
          fallback:
              'Open this screen from a paid event registration. '
              'No fixture event fee is shown.',
        );
      });
      return;
    }
    final result = await events.getTicket(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _registration = value;
          _error = null;
        });
      case AppError(:final failure):
        setState(() => _error = paymentFailureMessage(failure));
    }
  }

  Future<void> _pay() async {
    final repo = _payments;
    final id = _resolvedId;
    if (repo == null || id == null || id.isEmpty) {
      setState(() {
        _error = fhcT(
          context,
          'events.paymentRequiresApi',
          fallback: 'Event payment requires the Laravel payments API.',
        );
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await repo.initiateEventPayment(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        final intentId = '${value['id'] ?? ''}';
        final provider = '${value['provider_code'] ?? ''}';
        if ('${value['status']}' == 'succeeded') {
          setState(() => _submitting = false);
          fhcGo(context, paymentIntentRoute(value));
          return;
        }
        if (provider == 'local_manual' && intentId.isNotEmpty) {
          setState(() {
            _submitting = false;
            _error = fhcT(
              context,
              'events.manualPaymentReceiptRequired',
              fallback:
                  'Manual event payment needs a receipt upload from Give, or wait for the provider webhook.',
            );
          });
          return;
        }
        final checkoutUrl = hostedCheckoutUrlOf(value);
        if (checkoutUrl != null) {
          final launched = await launchUrl(
            Uri.parse(checkoutUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!mounted) return;
          if (!launched) {
            setState(() {
              _submitting = false;
              _error = fhcT(
                context,
                'events.checkoutOpenFailed',
                fallback:
                    'Could not open checkout. Try again from a device with a browser.',
              );
            });
            return;
          }
        }
        setState(() => _submitting = false);
        fhcPush(context, paymentIntentRoute(value));
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = paymentFailureMessage(failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final registration = _registration;
    final minor = registration == null
        ? null
        : paymentAmountMinorOf(registration) ??
            (registration['fee_amount_minor'] is num
                ? (registration['fee_amount_minor'] as num).round()
                : null);
    final currency = '${registration?['fee_currency'] ?? 'NGN'}';
    final amountLabel = minor == null
        ? fhcT(context, 'events.paySecurely', fallback: 'Pay securely')
        : fhcT(
            context,
            'events.payAmount',
            args: {
              'amount': formatPaymentAmountMinor(minor, currency: currency),
            },
            fallback: 'Pay {amount}',
          );
    final eventName =
        '${registration?['event_name'] ?? registration?['name'] ?? fhcT(context, 'events.eventRegistration', fallback: 'Event registration')}';

    return WorkflowPage(
      title: fhcT(context, 'events.payment', fallback: 'Payment'),
      domain: WorkflowDomain.church,
      actionLabel: _submitting
          ? fhcT(context, 'give.processing', fallback: 'Processing…')
          : amountLabel,
      onAction: _submitting ? null : _pay,
      backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
      children: [
        WorkflowCard(
          color: const Color(0xFFF3F7F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fhcT(context, 'give.amount', fallback: 'Amount'),
                      style: FhcTypography.label,
                    ),
                  ),
                  Text(
                    minor == null
                        ? fhcT(
                            context,
                            'events.serverOwnedFee',
                            fallback: 'Server-owned fee',
                          )
                        : formatPaymentAmountMinor(minor, currency: currency),
                    style: FhcTypography.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        WorkflowSectionTitle(
          fhcT(context, 'give.checkout', fallback: 'Checkout'),
        ),
        WorkflowCard(
          child: Text(
            fhcT(
              context,
              'events.paymentCheckoutCopy',
              fallback:
                  'Event fees use the same activated provider as giving '
                  '(Paystack, Flutterwave, or Stripe). Card, transfer, and mobile '
                  'money options are shown on that provider page — not as fake '
                  'methods in this app.',
            ),
            style: FhcTypography.caption,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: FhcColors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: Text(
            fhcT(
              context,
              'events.securedPaymentIntent',
              fallback: 'Secured payment intent via Laravel',
            ),
            style: FhcTypography.caption,
          ),
        ),
      ],
    );
  }
}

class EventTicketsScreen extends StatefulWidget {
  const EventTicketsScreen({
    super.key,
    this.registrationId,
    this.eventRepository,
  });

  final String? registrationId;
  final EventRepository? eventRepository;

  @override
  State<EventTicketsScreen> createState() => _EventTicketsScreenState();
}

class _EventTicketsScreenState extends State<EventTicketsScreen> {
  FhcAsyncValue<JsonObject> _state = const FhcAsyncValue.loading();
  bool _started = false;

  EventRepository? get _repo =>
      widget.eventRepository ??
      AppServicesScope.maybeOf(context)?.eventRepository;

  String? get _resolvedId {
    final explicit = widget.registrationId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
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
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'events.ticketsRequireApi',
            fallback:
                'Event tickets require the Laravel ticket read API. '
                'No fixture ticket is shown.',
          ),
        );
      });
      return;
    }
    final id = _resolvedId;
    if (id == null || id.isEmpty) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'events.ticketsNeedRegistrationId',
            fallback:
                'No registration id is available for a ticket lookup. '
                'Register for an event first.',
          ),
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getTicket(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _state = FhcAsyncValue.data(value));
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          setState(() {
            _state = FhcAsyncValue.unavailable(message: failure.message);
          });
        } else {
          setState(() => _state = FhcAsyncValue.error(failure));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(context, 'events.myTickets', fallback: 'My Tickets'),
      domain: WorkflowDomain.church,
      actionLabel: fhcT(
        context,
        'events.browseEvents',
        fallback: 'Browse Events',
      ),
      onAction: () => fhcPush(context, FhcRoutes.events),
      backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
      children: [
        SizedBox(
          height: 360,
          child: FhcAsyncBody<JsonObject>(
            value: _state,
            onRetry: _load,
            unavailableTitle: fhcT(
              context,
              'events.ticketsUnavailable',
              fallback: 'Tickets unavailable',
            ),
            builder: (context, ticket) {
              final code =
                  '${ticket['ticket_code'] ?? ticket['code'] ?? ticket['id'] ?? ''}'
                      .trim();
              final qrPayload =
                  '${ticket['qr_payload'] ?? ticket['qr'] ?? ''}'.trim();
              final name =
                  '${ticket['event_name'] ?? ticket['name'] ?? fhcT(context, 'events.registration', fallback: 'Registration')}';
              return WorkflowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: FhcTypography.titleSmall),
                    const SizedBox(height: 20),
                    const Center(child: Icon(Icons.qr_code_2, size: 128)),
                    const SizedBox(height: 16),
                    Text(
                      fhcT(context, 'events.ticketCode', fallback: 'Ticket Code'),
                      style: FhcTypography.caption,
                    ),
                    Text(
                      code.isEmpty ? '—' : code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (qrPayload.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        fhcT(
                          context,
                          'events.qrPayload',
                          fallback: 'QR payload',
                        ),
                        style: FhcTypography.caption,
                      ),
                      SelectableText(
                        qrPayload,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EventAttendanceScreen extends StatelessWidget {
  const EventAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: fhcT(
        context,
        'events.attendance',
        fallback: 'Event Attendance',
      ),
      domain: WorkflowDomain.church,
      backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
      children: [
        WorkflowCard(
          color: const Color(0xFFF3F7F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fhcT(
                  context,
                  'events.attendanceDemoTitle',
                  fallback: 'Kingdom Impact Conference 2025',
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                fhcT(
                  context,
                  'events.attendanceDemoSchedule',
                  fallback: 'May 30 - June 1, 2025\nThe Garden House, Lagos',
                ),
                style: FhcTypography.caption,
              ),
              const SizedBox(height: 10),
              WorkflowPill(
                fhcT(context, 'events.confirmed', fallback: 'Confirmed'),
              ),
            ],
          ),
        ),
        WorkflowSectionTitle(
          fhcT(context, 'events.attendanceSection', fallback: 'Attendance'),
        ),
        WorkflowSegments(
          labels: [
            fhcT(context, 'events.attendanceDay1', fallback: 'Day 1\nMay 30'),
            fhcT(context, 'events.attendanceDay2', fallback: 'Day 2\nMay 31'),
            fhcT(context, 'events.attendanceDay3', fallback: 'Day 3\nJun 1'),
          ],
        ),
        const SizedBox(height: 28),
        const Center(child: Icon(Icons.qr_code_2, size: 150)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            fhcT(
              context,
              'events.showAtEntrance',
              fallback: 'Show this at the entrance',
            ),
            style: FhcTypography.caption,
          ),
        ),
      ],
    );
  }
}

class EventFeedbackScreen extends StatefulWidget {
  const EventFeedbackScreen({super.key, this.eventRepository});

  final EventRepository? eventRepository;

  @override
  State<EventFeedbackScreen> createState() => _EventFeedbackScreenState();
}

class _EventFeedbackScreenState extends State<EventFeedbackScreen> {
  late final TextEditingController _registrationId;
  int _rating = 0;
  bool _submitting = false;
  String? _error;
  String? _info;
  bool _prefilled = false;

  EventRepository? get _repo =>
      widget.eventRepository ??
      AppServicesScope.maybeOf(context)?.eventRepository;

  @override
  void initState() {
    super.initState();
    _registrationId = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final fromArgs = FhcRouteArgs.entityIdOf(context)?.trim();
    if (fromArgs != null && fromArgs.isNotEmpty) {
      _registrationId.text = fromArgs;
    }
  }

  @override
  void dispose() {
    _registrationId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _error =
            'Event feedback requires an authenticated events API. '
            'No rating was submitted.';
        _info = null;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });
    final result = await repo.recordFeedback(
      _registrationId.text.trim(),
      _rating,
    );
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _submitting = false;
          _info =
              'Feedback accepted (${value['id'] ?? value['rating'] ?? 'recorded'}).';
        });
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkflowPage(
      title: 'Event Feedback',
      domain: WorkflowDomain.church,
      actionLabel: _submitting ? 'Submitting…' : 'Submit Feedback',
      onAction: _submitting ? () {} : _submit,
            children: [
        const Text(
          'POST /user/events/feedback requires a registration ULID and a '
          'rating from 1 to 5. No fixture event or comments are submitted.',
          style: FhcTypography.caption,
        ),
        const SizedBox(height: 12),
        const Text('Registration ID (ULID)', style: FhcTypography.label),
        const SizedBox(height: 6),
        TextField(
          controller: _registrationId,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'From event registration',
            hintStyle: const TextStyle(fontSize: 12, color: FhcColors.hint),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FhcColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: FhcColors.border),
            ),
          ),
        ),
        const WorkflowSectionTitle('Rating'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _rating = i),
                tooltip: '$i',
                icon: Icon(
                  i <= _rating ? Icons.star : Icons.star_border,
                  color: i <= _rating ? FhcColors.gold : FhcColors.muted,
                  size: 38,
                ),
              ),
          ],
        ),
        Center(
          child: Text(
            _rating == 0 ? 'Select 1–5' : '$_rating / 5',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: FhcColors.red, fontSize: 12),
          ),
        ],
        if (_info != null) ...[
          const SizedBox(height: 12),
          Text(
            _info!,
            style: const TextStyle(color: FhcColors.green, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class PressCategoriesScreen extends StatelessWidget {
  const PressCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FhcFeatureUnavailablePage(
      feature: 'Press Categories',
      detail:
          'Category browsing is available from the Press library catalogue. '
          'No separate categories API is published in this build.',
    );
  }
}

class PressResourceDetailScreen extends StatelessWidget {
  const PressResourceDetailScreen({super.key, this.publicationId});

  final String? publicationId;

  @override
  Widget build(BuildContext context) {
    final id = publicationId ?? FhcRouteArgs.entityIdOf(context);
    if (id != null && id.trim().isNotEmpty) {
      return PressBookScreen(publicationId: id.trim());
    }
    return const FhcFeatureUnavailablePage(
      feature: 'Press Publication',
      detail:
          'Open a title from the Press library so its public id can be loaded.',
    );
  }
}

class PressAudioPlayerScreen extends StatelessWidget {
  const PressAudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FhcFeatureUnavailablePage(
      feature: 'Press Audio',
      detail:
          'Audio playback requires a signed asset contract that is not '
          'published in this build. No fixture player is shown.',
    );
  }
}

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FhcFeatureUnavailablePage(
      feature: 'My Downloads',
      detail:
          'Local downloads require a signed Press asset contract that is not '
          'published in this build. No fixture download list is shown.',
    );
  }
}


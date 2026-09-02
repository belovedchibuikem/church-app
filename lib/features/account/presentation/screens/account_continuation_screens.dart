import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/notifications/push_notification_scaffold.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../../shared/widgets/recent_mfa_challenge_sheet.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../community/data/payment_repository.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/profile_repository.dart';
import '../../data/security_repository.dart';

enum AccountContinuationKind {
  receipt,
  shareReceipt,
  paymentHistory,
  transaction,
  paymentPending,
  refund,
  dispute,
  recurringGiving,
  notificationPreferences,
  communicationPreferences,
  activeSessions,
  privacy,
  consents,
  dataExport,
  accountDeletion,
  childProfile,
  guardianControls,
  guardianConsent,
  restrictedCommunication,
  safeguardingReport,
  pastoralRecord,
  aiHub,
  pastoralAssistant,
  paymentProcessing,
  paymentSuccess,
  paymentFailed,
}

bool _isApiBackedAccountKind(AccountContinuationKind kind) =>
    kind == AccountContinuationKind.notificationPreferences ||
    kind == AccountContinuationKind.activeSessions ||
    kind == AccountContinuationKind.consents ||
    kind == AccountContinuationKind.privacy ||
    kind == AccountContinuationKind.receipt ||
    kind == AccountContinuationKind.shareReceipt ||
    kind == AccountContinuationKind.paymentHistory ||
    kind == AccountContinuationKind.transaction ||
    kind == AccountContinuationKind.paymentPending ||
    kind == AccountContinuationKind.paymentProcessing ||
    kind == AccountContinuationKind.paymentSuccess ||
    kind == AccountContinuationKind.paymentFailed;

class AccountContinuationScreen extends StatefulWidget {
  const AccountContinuationScreen({
    super.key,
    required this.kind,
    this.profileRepository,
    this.securityRepository,
    this.paymentRepository,
  });

  final AccountContinuationKind kind;
  final ProfileRepository? profileRepository;
  final SecurityRepository? securityRepository;
  final PaymentRepository? paymentRepository;

  @override
  State<AccountContinuationScreen> createState() =>
      _AccountContinuationScreenState();
}

class _AccountContinuationScreenState extends State<AccountContinuationScreen>
    with WidgetsBindingObserver {
  bool enabled = true;

  LaravelProfileRepository? _profile;
  LaravelSecurityRepository? _security;
  PaymentRepository? _payment;
  PushNotificationScaffold _push = const PushNotificationScaffold();
  bool _reposReady = false;

  bool _loading = false;
  String? _error;
  bool _saving = false;

  String _locale = 'en';
  String _timezone = 'Africa/Lagos';
  final Map<String, bool> _channelEnabled = {
    'push': false,
    'email': true,
    'sms': false,
    'whatsapp': false,
    'in_app': true,
  };

  List<JsonObject> _sessions = const [];
  List<JsonObject> _devices = const [];
  List<JsonObject> _consents = const [];
  List<JsonObject> _transactions = const [];
  List<JsonObject> _files = const [];
  JsonObject? _receipt;
  JsonObject? _transaction;

  String _dsrType = 'export';
  final TextEditingController _dsrNotes = TextEditingController();
  String? _dsrInfo;
  bool _statusNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reposReady) return;
    final services = AppServicesScope.maybeOf(context);
    final profile =
        widget.profileRepository ?? services?.profileRepository;
    final security =
        widget.securityRepository ?? services?.securityRepository;
    _profile =
        profile is LaravelProfileRepository
            ? profile
            : createProfileRepository() as LaravelProfileRepository;
    _security =
        security is LaravelSecurityRepository
            ? security
            : createSecurityRepository() as LaravelSecurityRepository;
    _payment = widget.paymentRepository ?? services?.paymentRepository;
    _push = services?.pushNotifications ?? const PushNotificationScaffold();
    _reposReady = true;
    if (_isApiBackedAccountKind(widget.kind) &&
        AppServicesScope.maybeOf(context)?.visualReview != true) {
      _loadApiSurface();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dsrNotes.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.kind == AccountContinuationKind.paymentProcessing) {
      unawaited(_refreshProcessingIntent());
    }
  }

  Future<void> _loadPaymentSurface(PaymentRepository? payment) async {
    if (payment == null) {
      setState(() {
        _error = fhcT(
          context,
          'account.paymentHistoryRequiresApi',
          fallback:
              'Payment history requires the payments service. '
              'No fixture amounts are shown.',
        );
        _loading = false;
      });
      return;
    }
    final entityId = FhcRouteArgs.entityIdOf(context);
    if (entityId != null && entityId.isNotEmpty) {
      final intent = await payment.getIntent(entityId);
      if (!mounted) return;
      switch (intent) {
        case AppSuccess(:final value):
          setState(() {
            _transaction = value;
            _loading = false;
          });
          if (widget.kind == AccountContinuationKind.paymentProcessing) {
            _redirectIfIntentSettled(value);
          }
          return;
        case AppError():
          break;
      }
    }

    final listed = await payment.listTransactions();
    if (!mounted) return;
    switch (listed) {
      case AppError(:final failure):
        setState(() {
          _error = paymentFailureMessage(failure);
          _loading = false;
        });
      case AppSuccess(:final value):
        JsonObject? selected;
        if (entityId != null && entityId.isNotEmpty) {
          for (final item in value) {
            final id = '${item['id'] ?? item['ulid'] ?? ''}';
            final receiptId = '${item['receipt_id'] ?? ''}';
            final intentId = '${item['payment_intent_id'] ?? ''}';
            if (id == entityId || receiptId == entityId || intentId == entityId) {
              selected = item;
              break;
            }
          }
        }
        setState(() {
          _transactions = value;
          _transaction = selected ?? _transaction ?? (value.isEmpty ? null : value.first);
          _loading = false;
          if (widget.kind == AccountContinuationKind.transaction &&
              entityId != null &&
              entityId.isNotEmpty &&
              selected == null &&
              _transaction == null) {
            _error = fhcT(
              context,
              'account.transactionNotFound',
              args: {'id': entityId},
              fallback: 'Transaction $entityId was not found.',
            );
          }
        });
    }
  }

  Future<void> _refreshProcessingIntent() async {
    if (!mounted || widget.kind != AccountContinuationKind.paymentProcessing) {
      return;
    }
    final payment = _payment;
    final entityId = FhcRouteArgs.entityIdOf(context) ??
        '${_transaction?['id'] ?? ''}';
    if (payment == null || entityId.trim().isEmpty) return;
    final intent = await payment.getIntent(entityId.trim());
    if (!mounted) return;
    switch (intent) {
      case AppError():
        return;
      case AppSuccess(:final value):
        setState(() => _transaction = value);
        _redirectIfIntentSettled(value);
    }
  }

  void _redirectIfIntentSettled(JsonObject intent) {
    if (_statusNavigated) return;
    final status = '${intent['status'] ?? ''}'.toLowerCase();
    if (status != 'succeeded' &&
        status != 'failed' &&
        status != 'cancelled' &&
        status != 'expired') {
      return;
    }
    _statusNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fhcGo(context, paymentIntentRoute(intent));
    });
  }

  void _showSecurityFailure(AppFailure failure) {
    final messenger = ScaffoldMessenger.of(context);
    if (isRecentMfaRequired(failure)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(honestMfaRequiredMessage(failure)),
          action: SnackBarAction(
            label: fhcT(context, 'account.openMfa', fallback: 'Open MFA'),
            onPressed: () async {
              final ok = await showRecentMfaChallengeSheet(
                context,
                reason: honestMfaRequiredMessage(failure),
              );
              if (!ok || !mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    fhcT(
                      context,
                      'account.mfaVerifiedRetry',
                      fallback: 'Verified. Retry your action.',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _loadApiSurface() async {
    final profile = _profile;
    final security = _security;
    final payment = _payment;
    setState(() {
      _loading = true;
      _error = null;
    });

    switch (widget.kind) {
      case AccountContinuationKind.notificationPreferences:
        if (profile == null) {
          setState(() {
            _error = fhcT(
              context,
              'account.profileUnavailable',
              fallback: 'Profile repository is unavailable.',
            );
            _loading = false;
          });
          return;
        }
        final result = await profile.getProfile();
        if (!mounted) return;
        switch (result) {
          case AppSuccess(:final value):
            final preferences = value['preferences'];
            if (preferences is Map) {
              _locale = (preferences['locale'] as String?) ?? _locale;
              _timezone = (preferences['timezone'] as String?) ?? _timezone;
              final channels = preferences['notification_channels'];
              if (channels is List) {
                final enabled = {for (final item in channels) '$item'};
                for (final key in _channelEnabled.keys) {
                  _channelEnabled[key] = enabled.contains(key);
                }
              }
            }
            setState(() => _loading = false);
          case AppError(:final failure):
            setState(() {
              _error = failure.message;
              _loading = false;
            });
        }
      case AccountContinuationKind.activeSessions:
        if (security == null) {
          setState(() {
            _error = fhcT(
              context,
              'account.securityUnavailable',
              fallback: 'Security repository is unavailable.',
            );
            _loading = false;
          });
          return;
        }
        final sessionsResult = await security.sessions();
        final devicesResult = await security.devices();
        if (!mounted) return;
        switch (sessionsResult) {
          case AppError(:final failure):
            setState(() {
              _error =
                  isRecentMfaRequired(failure)
                      ? honestMfaRequiredMessage(failure)
                      : failure.message;
              _loading = false;
            });
            return;
          case AppSuccess(:final value):
            switch (devicesResult) {
              case AppError(:final failure):
                setState(() {
                  _error =
                      isRecentMfaRequired(failure)
                          ? honestMfaRequiredMessage(failure)
                          : failure.message;
                  _loading = false;
                });
                return;
              case AppSuccess(value: final devices):
                setState(() {
                  _sessions =
                      value
                          .where((item) => item['revoked_at'] == null)
                          .toList(growable: false);
                  _devices =
                      devices
                          .where((item) => item['revoked_at'] == null)
                          .toList(growable: false);
                  _loading = false;
                });
            }
        }
      case AccountContinuationKind.privacy:
        if (security == null) {
          setState(() {
            _error = fhcT(
              context,
              'account.securityUnavailable',
              fallback: 'Security repository is unavailable.',
            );
            _loading = false;
          });
          return;
        }
        final filesResult = await security.listFiles();
        if (!mounted) return;
        switch (filesResult) {
          case AppError(:final failure):
            setState(() {
              _error = null;
              _files = const [];
              _dsrInfo =
                  isRecentMfaRequired(failure)
                      ? honestMfaRequiredMessage(failure)
                      : fhcT(
                        context,
                        'account.filesCouldNotBeListed',
                        args: {'message': failure.message},
                        fallback:
                            'Files could not be listed: ${failure.message}',
                      );
              _loading = false;
            });
          case AppSuccess(:final value):
            setState(() {
              _files = value;
              _error = null;
              _dsrInfo = null;
              _loading = false;
            });
        }
      case AccountContinuationKind.consents:
        if (security == null) {
          setState(() {
            _error = fhcT(
              context,
              'account.securityUnavailable',
              fallback: 'Security repository is unavailable.',
            );
            _loading = false;
          });
          return;
        }
        final result = await security.listConsents();
        if (!mounted) return;
        switch (result) {
          case AppSuccess(:final value):
            setState(() {
              _consents = value;
              _loading = false;
            });
          case AppError(:final failure):
            setState(() {
              _error =
                  isRecentMfaRequired(failure)
                      ? honestMfaRequiredMessage(failure)
                      : failure.message;
              _loading = false;
            });
        }
      case AccountContinuationKind.paymentHistory:
      case AccountContinuationKind.paymentPending:
      case AccountContinuationKind.paymentProcessing:
      case AccountContinuationKind.paymentSuccess:
      case AccountContinuationKind.paymentFailed:
      case AccountContinuationKind.transaction:
        await _loadPaymentSurface(payment);
      case AccountContinuationKind.receipt:
      case AccountContinuationKind.shareReceipt:
        if (payment == null) {
          setState(() {
            _error = fhcT(
              context,
              'account.receiptsRequireApi',
              fallback: 'Receipts require the payments service.',
            );
            _loading = false;
          });
          return;
        }
        final receiptEntityId = FhcRouteArgs.entityIdOf(context);
        final listed = await payment.listTransactions();
        if (!mounted) return;
        switch (listed) {
          case AppError(:final failure):
            setState(() {
              _error = paymentFailureMessage(failure);
              _loading = false;
            });
          case AppSuccess(:final value):
            _transactions = value;
            var receiptId = receiptEntityId ?? '';
            JsonObject? matchedTxn;
            if (receiptId.isEmpty && value.isNotEmpty) {
              matchedTxn = value.first;
              receiptId = '${matchedTxn['receipt_id'] ?? ''}';
            } else if (receiptId.isNotEmpty) {
              for (final item in value) {
                final id = '${item['id'] ?? ''}';
                final rid = '${item['receipt_id'] ?? ''}';
                if (id == receiptId || rid == receiptId) {
                  matchedTxn = item;
                  receiptId = rid.isNotEmpty ? rid : receiptId;
                  break;
                }
              }
            }
            _transaction = matchedTxn;
            if (receiptId.isEmpty) {
              setState(() {
                _error = fhcT(
                  context,
                  'account.noReceiptYet',
                  fallback:
                      'No receipt is available yet for this payment. '
                      'Receipts are issued after a completed giving intent.',
                );
                _loading = false;
              });
              return;
            }
            final receipt = await payment.getReceipt(receiptId);
            if (!mounted) return;
            switch (receipt) {
              case AppSuccess(:final value):
                setState(() {
                  _receipt = value;
                  _loading = false;
                });
              case AppError(:final failure):
                setState(() {
                  _error = paymentFailureMessage(failure);
                  _loading = false;
                });
            }
        }
      default:
        setState(() => _loading = false);
    }
  }

  Future<void> _saveNotificationPreferences() async {
    final profile = _profile;
    if (profile == null) return;
    setState(() => _saving = true);
    final channels = [
      for (final entry in _channelEnabled.entries)
        if (entry.value) entry.key,
    ];
    final result = await profile.updatePreferences({
      'locale': _locale,
      'timezone': _timezone,
      'notification_channels': channels,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case AppSuccess():
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              fhcT(
                context,
                'account.notificationPreferencesSaved',
                fallback: 'Notification preferences saved.',
              ),
            ),
          ),
        );
      case AppError(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _revokeOtherSessions() async {
    final security = _security;
    if (security == null) return;
    setState(() => _saving = true);
    var failures = 0;
    AppFailure? mfaFailure;
    for (final session in _sessions) {
      final id = session['id'] as String?;
      if (id == null || id.isEmpty) continue;
      final result = await security.revokeSession(id);
      if (result is AppError) {
        failures += 1;
        if (mfaFailure == null && isRecentMfaRequired(result.failure)) {
          mfaFailure = result.failure;
        }
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    await _loadApiSurface();
    if (!mounted) return;
    if (mfaFailure != null) {
      _showSecurityFailure(mfaFailure);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failures == 0
              ? fhcT(
                context,
                'account.otherSessionsSignedOut',
                fallback: 'Other sessions were signed out.',
              )
              : fhcT(
                context,
                'account.someSessionsNotRevoked',
                fallback: 'Some sessions could not be revoked.',
              ),
        ),
      ),
    );
  }

  Future<void> _submitDataSubjectRequest() async {
    final security = _security;
    if (security == null) {
      _showSecurityFailure(
        ValidationFailure(
          fhcT(
            context,
            'account.securityUnavailable',
            fallback: 'Security repository is unavailable.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _dsrInfo = null;
    });
    final result = await security.submitDataSubjectRequest(
      requestType: _dsrType,
      notes: _dsrNotes.text.trim().isEmpty ? null : _dsrNotes.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _dsrInfo = fhcT(
            context,
            'account.dataRequestAccepted',
            args: {
              'id': '${value['id'] ?? 'recorded'}',
              'type': '${value['request_type'] ?? _dsrType}',
              'status': '${value['status'] ?? 'submitted'}',
            },
            fallback:
                'Request accepted (${value['id'] ?? 'recorded'}; '
                'type ${value['request_type'] ?? _dsrType}; '
                'status ${value['status'] ?? 'submitted'}).',
          );
        });
      case AppError(:final failure):
        _showSecurityFailure(failure);
    }
  }

  Future<void> _revokeSession(String id) async {
    final security = _security;
    if (security == null) return;
    final result = await security.revokeSession(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        await _loadApiSurface();
      case AppError(:final failure):
        _showSecurityFailure(failure);
    }
  }

  Future<void> _revokeDevice(String id) async {
    final security = _security;
    if (security == null) return;
    final result = await security.revokeDevice(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        await _loadApiSurface();
      case AppError(:final failure):
        _showSecurityFailure(failure);
    }
  }

  Future<void> _withdrawConsent(String id) async {
    final security = _security;
    if (security == null) return;
    final result = await security.updateConsent(id, false);
    if (!mounted) return;
    switch (result) {
      case AppSuccess():
        await _loadApiSurface();
      case AppError(:final failure):
        _showSecurityFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(widget.kind);
    final liveApi = _isApiBackedAccountKind(widget.kind) &&
        AppServicesScope.maybeOf(context)?.visualReview != true;
    if (!liveApi) {
      return WorkflowPage(
        title: spec.title,
        domain: WorkflowDomain.more,
        actionLabel: spec.action,
        onAction: spec.next == null ? null : () => fhcPush(context, spec.next!),
        children: _content(widget.kind),
      );
    }

    return WorkflowPage(
      title: spec.title,
      domain: WorkflowDomain.more,
      actionLabel: _apiActionLabel(widget.kind),
      onAction: _apiAction(widget.kind),
      children: _apiChildren(widget.kind),
    );
  }

  String? _apiActionLabel(AccountContinuationKind kind) {
    if (_loading || _error != null) return null;
    return switch (kind) {
      AccountContinuationKind.notificationPreferences =>
        _saving
            ? fhcT(context, 'common.saving', fallback: 'Saving…')
            : fhcT(
              context,
              'account.savePreferences',
              fallback: 'Save Preferences',
            ),
      AccountContinuationKind.activeSessions =>
        _saving
            ? fhcT(context, 'common.signingOut', fallback: 'Signing out…')
            : fhcT(
              context,
              'account.signOutOtherSessions',
              fallback: 'Sign Out of All Other Sessions',
            ),
      AccountContinuationKind.consents => null,
      AccountContinuationKind.privacy =>
        _saving
            ? fhcT(context, 'account.submitting', fallback: 'Submitting…')
            : fhcT(
              context,
              'account.submitDataRequest',
              fallback: 'Submit data request',
            ),
      AccountContinuationKind.receipt => fhcT(
        context,
        'account.shareReceipt',
        fallback: 'Share Receipt',
      ),
      AccountContinuationKind.shareReceipt => fhcT(
        context,
        'account.saveToGallery',
        fallback: 'Save to Gallery',
      ),
      AccountContinuationKind.paymentSuccess => fhcT(
        context,
        'account.viewReceipt',
        fallback: 'View Receipt',
      ),
      AccountContinuationKind.paymentFailed => fhcT(
        context,
        'common.tryAgain',
        fallback: 'Try Again',
      ),
      AccountContinuationKind.paymentProcessing =>
        _saving
            ? fhcT(context, 'account.checking', fallback: 'Checking…')
            : fhcT(context, 'account.checkStatus', fallback: 'Check status'),
      AccountContinuationKind.transaction =>
        '${_transaction?['receipt_id'] ?? ''}'.isEmpty
            ? null
            : fhcT(context, 'account.viewReceipt', fallback: 'View Receipt'),
      _ => null,
    };
  }

  VoidCallback? _apiAction(AccountContinuationKind kind) {
    if (_loading || _error != null || _saving) return null;
    return switch (kind) {
      AccountContinuationKind.notificationPreferences =>
        _saveNotificationPreferences,
      AccountContinuationKind.activeSessions => _revokeOtherSessions,
      AccountContinuationKind.privacy => _submitDataSubjectRequest,
      AccountContinuationKind.receipt =>
        () {
          final receiptId =
              '${_receipt?['id'] ?? _transaction?['receipt_id'] ?? ''}';
          fhcPush(
            context,
            receiptId.isEmpty
                ? '/payments/receipt/share'
                : '/payments/receipt/share?id=${Uri.encodeComponent(receiptId)}',
          );
        },
      AccountContinuationKind.shareReceipt => _copyReceiptToClipboard,
      AccountContinuationKind.paymentSuccess ||
      AccountContinuationKind.transaction => () {
        final receiptId = '${_transaction?['receipt_id'] ?? _receipt?['id'] ?? ''}';
        fhcPush(
          context,
          receiptId.isEmpty
              ? '/payments/receipt'
              : '/payments/receipt?id=${Uri.encodeComponent(receiptId)}',
        );
      },
      AccountContinuationKind.paymentFailed => () => fhcPush(context, '/give'),
      AccountContinuationKind.paymentProcessing => () {
        unawaited(_refreshProcessingIntent());
      },
      _ => null,
    };
  }

  List<Widget> _apiChildren(AccountContinuationKind kind) {
    if (_loading) {
      return const [
        SizedBox(height: 80),
        Center(child: CircularProgressIndicator.adaptive()),
      ];
    }
    if (_error != null) {
      final mfa = _error!.toLowerCase().contains('multi-factor') ||
          _error!.toLowerCase().contains('mfa');
      return [
        FhcErrorState(
          title: mfa
              ? fhcT(context, 'account.mfaRequired', fallback: 'MFA required')
              : fhcT(context, 'errors.unableToLoad', fallback: 'Unable to load'),
          message: _error!,
          onRetry: _loadApiSurface,
        ),
        if (mfa) ...[
          const SizedBox(height: 12),
          FhcPrimaryButton(
            label: fhcT(
              context,
              'account.openMfaChallenge',
              fallback: 'Open MFA challenge',
            ),
            onPressed: () => fhcPush(context, '/2fa'),
          ),
        ],
      ];
    }

    return switch (kind) {
      AccountContinuationKind.notificationPreferences =>
        _notificationPreferenceContent(),
      AccountContinuationKind.activeSessions => _sessionContent(),
      AccountContinuationKind.privacy => _privacyContent(),
      AccountContinuationKind.consents => _consentContent(),
      AccountContinuationKind.paymentHistory ||
      AccountContinuationKind.paymentPending ||
      AccountContinuationKind.paymentProcessing ||
      AccountContinuationKind.paymentSuccess ||
      AccountContinuationKind.paymentFailed ||
      AccountContinuationKind.transaction =>
        _livePaymentListContent(kind),
      AccountContinuationKind.receipt => _liveReceiptContent(),
      AccountContinuationKind.shareReceipt => _liveShareReceiptContent(),
      _ => _content(kind),
    };
  }

  List<Widget> _notificationPreferenceContent() {
    final pushConfigured = _push.isConfigured;
    final labels = <(String, String, String)>[
      (
        'push',
        fhcT(
          context,
          'account.pushNotifications',
          fallback: 'Push Notifications',
        ),
        fhcT(
          context,
          'account.pushNotificationsCopy',
          fallback: 'Receive push notifications',
        ),
      ),
      (
        'email',
        fhcT(
          context,
          'account.emailNotifications',
          fallback: 'Email Notifications',
        ),
        fhcT(
          context,
          'account.emailNotificationsCopy',
          fallback: 'Receive emails',
        ),
      ),
      (
        'sms',
        fhcT(
          context,
          'account.smsNotifications',
          fallback: 'SMS Notifications',
        ),
        fhcT(
          context,
          'account.smsNotificationsCopy',
          fallback: 'Receive SMS messages',
        ),
      ),
      (
        'whatsapp',
        fhcT(
          context,
          'account.whatsappNotifications',
          fallback: 'WhatsApp Notifications',
        ),
        fhcT(
          context,
          'account.whatsappNotificationsCopy',
          fallback: 'Receive WhatsApp messages',
        ),
      ),
      (
        'in_app',
        fhcT(
          context,
          'account.inAppNotifications',
          fallback: 'In-App Notifications',
        ),
        fhcT(
          context,
          'account.inAppNotificationsCopy',
          fallback: 'Receive in-app alerts',
        ),
      ),
    ];
    return [
      if (!pushConfigured)
        _notice(
          fhcT(
            context,
            'account.devicePushNotConfigured',
            fallback:
                'Device push is not configured yet (no FCM/APNs provider). '
                'You can still save the push preference for when OD-009 lands; '
                'in-app notifications continue via /user/notifications.',
          ),
        ),
      for (final item in labels)
        _channelToggle(
          item.$1,
          item.$2,
          item.$1 == 'push' && !pushConfigured
              ? fhcT(
                context,
                'account.pushPreferenceOnly',
                fallback: 'Preference only — device push unbound',
              )
              : item.$3,
        ),
      _notice(
        fhcT(
          context,
          'account.channelPreferencesSync',
          fallback: 'Channel preferences sync to your Family House account.',
        ),
      ),
    ];
  }

  Widget _channelToggle(String key, String title, String subtitle) {
    return WorkflowCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: FhcTypography.caption),
              ],
            ),
          ),
          Switch(
            value: _channelEnabled[key] ?? false,
            activeTrackColor: FhcColors.green,
            onChanged: (value) => setState(() => _channelEnabled[key] = value),
          ),
        ],
      ),
    );
  }

  List<Widget> _livePaymentListContent(AccountContinuationKind kind) {
    if (kind == AccountContinuationKind.paymentProcessing) {
      final intent = _transaction;
      if (intent == null) {
        return [
          _notice(
            fhcT(
              context,
              'account.noLiveGivingIntent',
              fallback:
                  'No live giving intent is available yet. Start from Give, then '
                  'return here after the provider checkout page.',
            ),
          ),
        ];
      }
      final minor = paymentAmountMinorOf(intent) ?? 0;
      final currency = '${intent['currency'] ?? 'NGN'}';
      final status = '${intent['status'] ?? 'pending_provider'}';
      final providerCode = '${intent['provider_code'] ?? 'payment'}';
      return [
        _notice(
          status == 'pending_provider'
              ? fhcT(
                context,
                'account.finishCheckout',
                args: {'provider': providerCode},
                fallback:
                    'Finish checkout in the $providerCode '
                    'page, then return to this screen. We refresh the intent when '
                    'the app comes back to the foreground.',
              )
              : fhcT(
                context,
                'account.latestIntentStatus',
                fallback: 'Latest status from GET /user/payments/intents/{id}.',
              ),
        ),
        _details([
          (
            fhcT(context, 'account.intentId', fallback: 'Intent ID'),
            '${intent['id'] ?? '—'}',
          ),
          (
            fhcT(context, 'account.purpose', fallback: 'Purpose'),
            paymentPurposeLabel(intent),
          ),
          (
            fhcT(context, 'account.amount', fallback: 'Amount'),
            formatPaymentAmountMinor(minor, currency: currency),
          ),
          (
            fhcT(context, 'account.currency', fallback: 'Currency'),
            currency,
          ),
          (
            fhcT(context, 'account.status', fallback: 'Status'),
            status,
          ),
          (
            fhcT(context, 'account.provider', fallback: 'Provider'),
            '${intent['provider_code'] ?? fhcT(context, 'account.serverSelected', fallback: 'server-selected')}',
          ),
        ]),
        const SizedBox(height: 24),
        const Center(
          child: CircularProgressIndicator(
            color: FhcColors.green,
            backgroundColor: FhcColors.border,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fhcT(
            context,
            'account.waitingForWebhook',
            fallback: 'Waiting for the provider webhook…',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Text(
          fhcT(
            context,
            'account.pollingDoesNotCharge',
            fallback:
                'You can leave the checkout page and come back. No extra charge is created by polling.',
          ),
          textAlign: TextAlign.center,
          style: FhcTypography.caption,
        ),
      ];
    }

    if (kind == AccountContinuationKind.transaction ||
        kind == AccountContinuationKind.paymentSuccess ||
        kind == AccountContinuationKind.paymentPending) {
      final tx = _transaction;
      if (tx == null) {
        return [
          FhcEmptyState(
            title: fhcT(
              context,
              'account.noPaymentRecords',
              fallback: 'No payment records',
            ),
            message: fhcT(
              context,
              'account.noPaymentRecordsCopy',
              fallback:
                  'Transactions will appear here once payment records are available. '
                  'No fixture amounts are shown.',
            ),
          ),
        ];
      }
      final minor = paymentAmountMinorOf(tx) ?? 0;
      final currency = '${tx['currency'] ?? 'NGN'}';
      return [
        _status(
          formatPaymentAmountMinor(minor, currency: currency),
          kind == AccountContinuationKind.paymentPending
              ? fhcT(
                context,
                'account.pendingConfirmation',
                fallback: 'Pending confirmation',
              )
              : fhcT(
                context,
                'account.recordedOnLaravel',
                fallback: 'Recorded on platform',
              ),
          kind != AccountContinuationKind.paymentPending,
        ),
        _details([
          (
            fhcT(context, 'account.transactionId', fallback: 'Transaction ID'),
            '${tx['id'] ?? '—'}',
          ),
          (
            fhcT(context, 'account.intentId', fallback: 'Intent ID'),
            '${tx['payment_intent_id'] ?? '—'}',
          ),
          (
            fhcT(context, 'account.receiptId', fallback: 'Receipt ID'),
            '${tx['receipt_id'] ?? '—'}',
          ),
          (
            fhcT(context, 'account.amount', fallback: 'Amount'),
            formatPaymentAmountMinor(minor, currency: currency),
          ),
          (
            fhcT(context, 'account.currency', fallback: 'Currency'),
            currency,
          ),
          (
            fhcT(context, 'account.date', fallback: 'Date'),
            _formatTimestamp(tx['occurred_at'] ?? tx['created_at']),
          ),
        ]),
        if ('${tx['receipt_id'] ?? ''}'.isNotEmpty)
          _notice(
            fhcT(
              context,
              'account.openReceiptToLoad',
              fallback: 'Open Receipt to load GET /user/payments/receipts/{id}.',
            ),
          ),
      ];
    }

    if (kind == AccountContinuationKind.paymentFailed) {
      final intent = _transaction;
      final minor = intent == null ? null : paymentAmountMinorOf(intent);
      final currency = '${intent?['currency'] ?? 'NGN'}';
      return [
        _status(
          fhcT(context, 'account.paymentFailed', fallback: 'Payment Failed'),
          fhcT(
            context,
            'account.paymentFailedCopy',
            fallback:
                'The payment could not be completed under current governance or the provider declined it.',
          ),
          false,
        ),
        if (intent != null)
          _details([
            (
              fhcT(context, 'account.intentId', fallback: 'Intent ID'),
              '${intent['id'] ?? '—'}',
            ),
            (
              fhcT(context, 'account.purpose', fallback: 'Purpose'),
              paymentPurposeLabel(intent),
            ),
            if (minor != null)
              (
                fhcT(context, 'account.amount', fallback: 'Amount'),
                formatPaymentAmountMinor(minor, currency: currency),
              ),
            (
              fhcT(context, 'account.status', fallback: 'Status'),
              '${intent['status'] ?? 'failed'}',
            ),
          ]),
        _notice(
          fhcT(
            context,
            'account.givingClosedUntilActivated',
            fallback:
                'Giving and event fees stay closed until an administrator activates '
                'Paystack, Flutterwave, or Stripe — or until you retry a declined checkout. '
                'No fixture charge was recorded.',
          ),
        ),
      ];
    }

    if (_transactions.isEmpty) {
      return [
        FhcEmptyState(
          title: fhcT(
            context,
            'account.noPaymentRecords',
            fallback: 'No payment records',
          ),
          message: fhcT(
            context,
            'account.noPaymentRecordsCopy',
            fallback:
                'Transactions will appear here once payment records are available. '
                'No fixture amounts are shown.',
          ),
        ),
      ];
    }
    return [
      _notice(
        fhcT(
          context,
          'account.livePaymentRecords',
          fallback:
              'Live payment records from the platform. Hosted checkout completes through signed provider webhooks.',
        ),
      ),
      WorkflowCard(
        child: Column(
          children: [
            for (final tx in _transactions)
              WorkflowRow(
                title: _paymentTitle(tx),
                subtitle: _paymentSubtitle(tx),
                onTap: () {
                  final id = '${tx['id'] ?? ''}';
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
      ),
    ];
  }

  List<Widget> _liveReceiptContent() {
    final receipt = _receipt;
    if (receipt == null) {
      return [
        FhcEmptyState(
          title: fhcT(
            context,
            'account.noReceiptAvailable',
            fallback: 'No receipt available',
          ),
          message: fhcT(
            context,
            'account.noReceiptAvailableCopy',
            fallback:
                'Receipts require a successful payment.',
          ),
        ),
      ];
    }
    return [
      _notice(
        fhcT(
          context,
          'account.receiptLoaded',
          fallback: 'Receipt loaded from GET /user/payments/receipts/{id}.',
        ),
      ),
      _details(_liveReceiptRows()),
    ];
  }

  List<Widget> _liveShareReceiptContent() {
    if (_receipt == null) {
      return _liveReceiptContent();
    }
    return [
      _receiptCard(),
      WorkflowSectionTitle(
        fhcT(context, 'account.shareVia', fallback: 'Share via'),
      ),
      _iconChoices([
        (
          Icons.chat,
          fhcT(context, 'account.whatsapp', fallback: 'WhatsApp'),
          () => unawaited(_shareReceipt('whatsapp')),
        ),
        (
          Icons.email_outlined,
          fhcT(context, 'account.email', fallback: 'Email'),
          () => unawaited(_shareReceipt('email')),
        ),
        (
          Icons.message_outlined,
          fhcT(context, 'common.messages', fallback: 'Message'),
          () => unawaited(_shareReceipt('sms')),
        ),
        (
          Icons.more_horiz,
          fhcT(context, 'common.more', fallback: 'More'),
          () => unawaited(_copyReceiptToClipboard()),
        ),
      ]),
    ];
  }

  List<(String, String)> _liveReceiptRows() {
    final receipt = _receipt;
    final tx = _transaction;
    if (receipt == null && tx == null) return _receiptDetails;
    final minor =
        paymentAmountMinorOf(receipt ?? const {}) ??
        (tx == null ? null : paymentAmountMinorOf(tx));
    final currency = '${receipt?['currency'] ?? tx?['currency'] ?? 'NGN'}';
    final purpose =
        '${receipt?['purpose_label'] ?? tx?['purpose_code'] ?? 'Giving'}';
    final settlement = '${receipt?['settlement'] ?? ''}';
    final method = settlement == 'manual'
        ? fhcT(
            context,
            'account.manualPayment',
            fallback: 'Manual payment (bank transfer / proof)',
          )
        : settlement == 'automatic'
        ? fhcT(
            context,
            'account.automaticPayment',
            fallback: 'Automatic checkout',
          )
        : '${tx?['provider_code'] ?? receipt?['provider_code'] ?? '—'}';
    return [
      (
        fhcT(context, 'account.amount', fallback: 'Amount'),
        minor == null
            ? '—'
            : formatPaymentAmountMinor(minor, currency: currency),
      ),
      (
        fhcT(context, 'account.currency', fallback: 'Currency'),
        currency,
      ),
      (
        fhcT(context, 'account.purpose', fallback: 'Purpose'),
        purpose,
      ),
      (
        fhcT(context, 'account.referenceId', fallback: 'Reference ID'),
        '${receipt?['receipt_number'] ?? receipt?['id'] ?? '—'}',
      ),
      (
        fhcT(context, 'account.dateTime', fallback: 'Date & Time'),
        _formatTimestamp(
          receipt?['occurred_at'] ??
              receipt?['issued_at'] ??
              tx?['occurred_at'],
        ),
      ),
      (
        fhcT(context, 'account.paymentMethod', fallback: 'Payment Method'),
        method,
      ),
      (
        fhcT(context, 'account.status', fallback: 'Status'),
        '${receipt?['status'] ?? tx?['status'] ?? 'successful'}',
      ),
    ];
  }

  String _receiptShareText() {
    final rows = _liveReceiptRows();
    final buffer = StringBuffer('Family House Connect — Official Receipt\n');
    for (final row in rows) {
      buffer.writeln('${row.$1}: ${row.$2}');
    }
    return buffer.toString().trim();
  }

  Future<void> _copyReceiptToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _receiptShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fhcT(
            context,
            'account.receiptCopied',
            fallback: 'Receipt copied. You can paste it or save it from share.',
          ),
        ),
      ),
    );
  }

  Future<void> _shareReceipt(String channel) async {
    final text = _receiptShareText();
    final encoded = Uri.encodeComponent(text);
    final uri = switch (channel) {
      'whatsapp' => Uri.parse('https://wa.me/?text=$encoded'),
      'email' => Uri.parse(
        'mailto:?subject=${Uri.encodeComponent('Family House Connect receipt')}&body=$encoded',
      ),
      'sms' => Uri.parse('sms:?body=$encoded'),
      _ => null,
    };
    if (uri == null) {
      await _copyReceiptToClipboard();
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      await _copyReceiptToClipboard();
    }
  }

  String _paymentTitle(JsonObject tx) {
    return '${tx['purpose_code'] ?? tx['purpose'] ?? tx['description'] ?? fhcT(context, 'member.giving', fallback: 'Giving')}';
  }

  String _paymentSubtitle(JsonObject tx) {
    final minor = paymentAmountMinorOf(tx);
    final currency = '${tx['currency'] ?? 'NGN'}';
    final amountLabel =
        minor == null
            ? '—'
            : formatPaymentAmountMinor(minor, currency: currency);
    final when = _formatTimestamp(
      tx['occurred_at'] ?? tx['created_at'] ?? tx['paid_at'],
    );
    return '$amountLabel  •  $when';
  }

  List<Widget> _sessionContent() {
    if (_sessions.isEmpty && _devices.isEmpty) {
      return [
        FhcEmptyState(
          title: fhcT(
            context,
            'account.noActiveSessions',
            fallback: 'No active sessions',
          ),
          message: fhcT(
            context,
            'account.noActiveSessionsCopy',
            fallback: 'There are no security sessions or devices to show.',
          ),
        ),
      ];
    }

    final deviceById = <String, JsonObject>{
      for (final device in _devices)
        if (device['id'] is String) device['id'] as String: device,
    };

    return [
      _notice(
        fhcT(
          context,
          'account.sessionsRequireMfa',
          fallback:
              'Keep your account secure. Sessions and devices require recent MFA to revoke.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.activeSessions', fallback: 'Active Sessions'),
      ),
      if (_sessions.isEmpty)
        _notice(
          fhcT(
            context,
            'account.noSessionsReturned',
            fallback: 'No sessions returned for this account.',
          ),
        )
      else
        WorkflowCard(
          child: Column(
            children: [
              for (final session in _sessions)
                WorkflowRow(
                  title: _sessionTitle(session, deviceById),
                  subtitle: _sessionSubtitle(session),
                  onTap: () {
                    final id = session['id'] as String?;
                    if (id != null) _revokeSession(id);
                  },
                ),
            ],
          ),
        ),
      WorkflowSectionTitle(
        fhcT(context, 'account.trustedDevices', fallback: 'Trusted Devices'),
      ),
      if (_devices.isEmpty)
        _notice(
          fhcT(
            context,
            'account.noDevicesReturned',
            fallback: 'No devices returned for this account.',
          ),
        )
      else
        WorkflowCard(
          child: Column(
            children: [
              for (final device in _devices)
                WorkflowRow(
                  title:
                      (device['label'] as String?) ??
                      (device['platform'] as String?) ??
                      fhcT(context, 'account.device', fallback: 'Device'),
                  subtitle: fhcT(
                    context,
                    'account.deviceLastSeen',
                    args: {
                      'type': '${device['device_type'] ?? fhcT(context, 'common.unknown', fallback: 'unknown')}',
                      'when': _formatTimestamp(device['last_seen_at']),
                    },
                    fallback:
                        '${device['device_type'] ?? 'unknown'} • last seen ${_formatTimestamp(device['last_seen_at'])}',
                  ),
                  onTap: () {
                    final id = device['id'] as String?;
                    if (id != null) _revokeDevice(id);
                  },
                ),
            ],
          ),
        ),
    ];
  }

  String _sessionTitle(JsonObject session, Map<String, JsonObject> devices) {
    final deviceId = session['device_id'] as String?;
    final device = deviceId == null ? null : devices[deviceId];
    if (device != null) {
      return (device['label'] as String?) ??
          (device['platform'] as String?) ??
          fhcT(context, 'account.session', fallback: 'Session');
    }
    return fhcT(context, 'account.session', fallback: 'Session');
  }

  String _sessionSubtitle(JsonObject session) {
    return fhcT(
      context,
      'account.sessionSubtitle',
      args: {
        'started': _formatTimestamp(session['started_at']),
        'seen': _formatTimestamp(session['last_seen_at']),
      },
      fallback:
          'Started ${_formatTimestamp(session['started_at'])} • last seen ${_formatTimestamp(session['last_seen_at'])}',
    );
  }

  List<Widget> _privacyContent() {
    final types = <(String, String)>[
      (
        'export',
        fhcT(context, 'account.export', fallback: 'Export'),
      ),
      (
        'correction',
        fhcT(context, 'account.correction', fallback: 'Correction'),
      ),
      (
        'deletion',
        fhcT(context, 'account.deletion', fallback: 'Deletion'),
      ),
      (
        'restriction',
        fhcT(context, 'account.restriction', fallback: 'Restriction'),
      ),
    ];
    return [
      _notice(
        fhcT(
          context,
          'account.dataSubjectRequestHelp',
          fallback:
              'Submit a data-subject request via POST /user/privacy/data-subject-requests. '
              'Recent MFA is required. File upload (multipart POST /user/files) is not wired.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.requestType', fallback: 'Request type'),
      ),
      WorkflowCard(
        child: Column(
          children: [
            for (final item in types)
              RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.$2, style: FhcTypography.body),
                value: item.$1,
                groupValue: _dsrType,
                onChanged: (value) {
                  if (value != null) setState(() => _dsrType = value);
                },
              ),
          ],
        ),
      ),
      WorkflowSectionTitle(
        fhcT(
          context,
          'account.notesOptional',
          fallback: 'Notes (optional)',
        ),
      ),
      TextField(
        controller: _dsrNotes,
        maxLines: 3,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: fhcT(
            context,
            'account.requestContextHint',
            fallback: 'Context for this request',
          ),
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
      if (_dsrInfo != null) _notice(_dsrInfo!),
      WorkflowSectionTitle(
        fhcT(context, 'account.yourFiles', fallback: 'Your files'),
      ),
      if (_files.isEmpty)
        _notice(
          fhcT(
            context,
            'account.noFilesReturned',
            fallback: 'No files returned for this account.',
          ),
        )
      else
        WorkflowCard(
          child: Column(
            children: [
              for (final file in _files)
                WorkflowRow(
                  title:
                      (file['purpose'] as String?) ??
                      fhcT(context, 'account.file', fallback: 'File'),
                  subtitle:
                      '${file['classification'] ?? '—'} • ${file['status'] ?? '—'} • ${_formatTimestamp(file['created_at'])}',
                ),
            ],
          ),
        ),
      FhcMenuTile(
        icon: Icons.devices_outlined,
        title: fhcT(
          context,
          'account.openActiveSessions',
          fallback: 'Open active sessions',
        ),
        subtitle: fhcT(
          context,
          'account.openActiveSessionsCopy',
          fallback: 'Review and revoke signed-in sessions',
        ),
        onTap: () => fhcPush(context, '/settings/sessions'),
      ),
      const SizedBox(height: 8),
      FhcMenuTile(
        icon: Icons.policy_outlined,
        title: fhcT(context, 'account.openConsents', fallback: 'Open consents'),
        subtitle: fhcT(
          context,
          'account.openConsentsCopy',
          fallback: 'Grant or withdraw purposes',
        ),
        onTap: () => fhcPush(context, '/settings/consents'),
      ),
    ];
  }

  List<Widget> _consentContent() {
    final active =
        _consents.where((item) => item['withdrawn_at'] == null).toList();
    final history =
        _consents.where((item) => item['withdrawn_at'] != null).toList();

    if (_consents.isEmpty) {
      return [
        FhcEmptyState(
          title: fhcT(
            context,
            'account.noConsentsYet',
            fallback: 'No consents yet',
          ),
          message: fhcT(
            context,
            'account.noConsentsCopy',
            fallback: 'Granted privacy purposes will appear here.',
          ),
        ),
      ];
    }

    return [
      _notice(
        fhcT(
          context,
          'account.reviewConsentsMfa',
          fallback:
              'Review and manage your consents. Withdrawal requires recent MFA.',
        ),
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.active', fallback: 'Active'),
      ),
      if (active.isEmpty)
        _notice(
          fhcT(
            context,
            'account.noActiveConsents',
            fallback: 'No active consents.',
          ),
        )
      else
        WorkflowCard(
          child: Column(
            children: [
              for (final consent in active)
                WorkflowRow(
                  title:
                      (consent['purpose'] as String?) ??
                      fhcT(context, 'account.consent', fallback: 'Consent'),
                  subtitle: fhcT(
                    context,
                    'account.consentGranted',
                    args: {
                      'when': _formatTimestamp(consent['granted_at']),
                      'policy': '${consent['policy_version'] ?? '—'}',
                    },
                    fallback:
                        'Granted ${_formatTimestamp(consent['granted_at'])} • policy ${consent['policy_version'] ?? '—'}',
                  ),
                  onTap: () {
                    final id = consent['id'] as String?;
                    if (id != null) _withdrawConsent(id);
                  },
                ),
            ],
          ),
        ),
      WorkflowSectionTitle(
        fhcT(context, 'account.history', fallback: 'History'),
      ),
      if (history.isEmpty)
        _notice(
          fhcT(
            context,
            'account.noWithdrawnConsents',
            fallback: 'No withdrawn consents.',
          ),
        )
      else
        WorkflowCard(
          child: Column(
            children: [
              for (final consent in history)
                WorkflowRow(
                  title:
                      (consent['purpose'] as String?) ??
                      fhcT(context, 'account.consent', fallback: 'Consent'),
                  subtitle: fhcT(
                    context,
                    'account.consentWithdrawn',
                    args: {
                      'when': _formatTimestamp(consent['withdrawn_at']),
                    },
                    fallback:
                        'Withdrawn ${_formatTimestamp(consent['withdrawn_at'])}',
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  String _formatTimestamp(Object? value) {
    if (value is! String || value.isEmpty) {
      return fhcT(context, 'common.unknown', fallback: 'unknown');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  _AccountSpec _spec(AccountContinuationKind kind) => switch (kind) {
    AccountContinuationKind.receipt => _AccountSpec(
      fhcT(context, 'account.receiptDetail', fallback: 'Receipt Detail'),
      fhcT(context, 'account.downloadReceipt', fallback: 'Download Receipt'),
      '/payments/receipt/share',
    ),
    AccountContinuationKind.shareReceipt => _AccountSpec(
      fhcT(context, 'account.shareReceipt', fallback: 'Share Receipt'),
      fhcT(context, 'account.saveToGallery', fallback: 'Save to Gallery'),
      null,
    ),
    AccountContinuationKind.paymentHistory => _AccountSpec(
      fhcT(context, 'account.paymentHistory', fallback: 'Payment History'),
      null,
      null,
    ),
    AccountContinuationKind.transaction => _AccountSpec(
      fhcT(context, 'account.transactionDetail', fallback: 'Transaction Detail'),
      fhcT(context, 'account.downloadReceipt', fallback: 'Download Receipt'),
      '/payments/receipt',
    ),
    AccountContinuationKind.paymentPending => _AccountSpec(
      fhcT(context, 'account.paymentPending', fallback: 'Payment Pending'),
      fhcT(context, 'account.viewStatus', fallback: 'View Status'),
      '/payments/history',
    ),
    AccountContinuationKind.refund => _AccountSpec(
      fhcT(context, 'account.refundStatus', fallback: 'Refund Status'),
      null,
      null,
    ),
    AccountContinuationKind.dispute => _AccountSpec(
      fhcT(context, 'account.disputeChargeback', fallback: 'Dispute / Chargeback'),
      null,
      null,
    ),
    AccountContinuationKind.recurringGiving => _AccountSpec(
      fhcT(context, 'account.recurringGiving', fallback: 'Recurring Giving'),
      fhcT(context, 'account.saveChanges', fallback: 'Save Changes'),
      null,
    ),
    AccountContinuationKind.notificationPreferences => _AccountSpec(
      fhcT(
        context,
        'settings.notificationPreferences',
        fallback: 'Notification Preferences',
      ),
      fhcT(context, 'account.savePreferences', fallback: 'Save Preferences'),
      null,
    ),
    AccountContinuationKind.communicationPreferences => _AccountSpec(
      fhcT(
        context,
        'account.communicationPreferences',
        fallback: 'Communication Preferences',
      ),
      fhcT(context, 'account.savePreferences', fallback: 'Save Preferences'),
      null,
    ),
    AccountContinuationKind.activeSessions => _AccountSpec(
      fhcT(context, 'account.activeSessions', fallback: 'Active Sessions'),
      fhcT(
        context,
        'account.signOutOtherSessions',
        fallback: 'Sign Out of All Other Sessions',
      ),
      null,
    ),
    AccountContinuationKind.privacy => _AccountSpec(
      fhcT(context, 'account.privacyControls', fallback: 'Privacy Controls'),
      fhcT(context, 'account.savePreferences', fallback: 'Save Preferences'),
      null,
    ),
    AccountContinuationKind.consents => _AccountSpec(
      fhcT(context, 'account.consentManagement', fallback: 'Consent Management'),
      fhcT(context, 'account.updateConsents', fallback: 'Update Consents'),
      null,
    ),
    AccountContinuationKind.dataExport => _AccountSpec(
      fhcT(context, 'account.dataExport', fallback: 'Data Export'),
      fhcT(context, 'account.requestExport', fallback: 'Request Export'),
      null,
    ),
    AccountContinuationKind.accountDeletion => _AccountSpec(
      fhcT(context, 'account.accountDeletion', fallback: 'Account Deletion'),
      fhcT(
        context,
        'account.requestAccountDeletion',
        fallback: 'Request Account Deletion',
      ),
      null,
    ),
    AccountContinuationKind.childProfile => _AccountSpec(
      fhcT(context, 'account.childProfile', fallback: 'Child Profile'),
      fhcT(context, 'account.viewActivity', fallback: 'View Activity'),
      null,
    ),
    AccountContinuationKind.guardianControls => _AccountSpec(
      fhcT(context, 'account.guardianControls', fallback: 'Guardian Controls'),
      fhcT(context, 'account.saveSettings', fallback: 'Save Settings'),
      null,
    ),
    AccountContinuationKind.guardianConsent => _AccountSpec(
      fhcT(context, 'account.guardianConsent', fallback: 'Guardian Consent'),
      fhcT(context, 'account.provideNewConsent', fallback: 'Provide New Consent'),
      null,
    ),
    AccountContinuationKind.restrictedCommunication => _AccountSpec(
      fhcT(
        context,
        'account.restrictedChildCommunication',
        fallback: 'Restricted Child Communication',
      ),
      null,
      null,
    ),
    AccountContinuationKind.safeguardingReport => _AccountSpec(
      fhcT(context, 'account.safeguardingReport', fallback: 'Safeguarding Report'),
      fhcT(context, 'account.submitReport', fallback: 'Submit Report'),
      null,
    ),
    AccountContinuationKind.pastoralRecord => _AccountSpec(
      fhcT(context, 'account.pastoralRecord', fallback: 'Pastoral Record'),
      fhcT(context, 'account.requestAccess', fallback: 'Request Access'),
      null,
    ),
    AccountContinuationKind.aiHub => _AccountSpec(
      fhcT(context, 'account.aiAssistantHub', fallback: 'AI Assistant Hub'),
      null,
      null,
    ),
    AccountContinuationKind.pastoralAssistant => _AccountSpec(
      fhcT(
        context,
        'account.pastoralAiAssistant',
        fallback: 'Pastoral AI Assistant',
      ),
      null,
      null,
    ),
    AccountContinuationKind.paymentProcessing => _AccountSpec(
      fhcT(context, 'account.paymentProcessing', fallback: 'Payment Processing'),
      fhcT(context, 'account.checkStatus', fallback: 'Check status'),
      null,
    ),
    AccountContinuationKind.paymentSuccess => _AccountSpec(
      fhcT(context, 'account.paymentSuccess', fallback: 'Payment Success'),
      fhcT(context, 'account.viewReceipt', fallback: 'View Receipt'),
      '/payments/receipt',
    ),
    AccountContinuationKind.paymentFailed => _AccountSpec(
      fhcT(context, 'account.paymentFailed', fallback: 'Payment Failed'),
      fhcT(context, 'common.tryAgain', fallback: 'Try Again'),
      '/give',
    ),
  };

  List<Widget> _content(AccountContinuationKind kind) => switch (kind) {
    AccountContinuationKind.receipt => [
      _status(
        fhcT(context, 'account.paymentSuccessful', fallback: 'Payment Successful'),
        fhcT(
          context,
          'account.thankYouGenerosity',
          fallback: 'Thank you for your generosity!',
        ),
        true,
      ),
      WorkflowSectionTitle(
        fhcT(context, 'account.receiptInformation', fallback: 'Receipt Information'),
      ),
      _details(_receiptDetails),
      _notice(
        fhcT(
          context,
          'account.officialReceiptCopy',
          fallback:
              'This is your official receipt. A copy was also sent by email.',
        ),
      ),
    ],
    AccountContinuationKind.shareReceipt => [
      _receiptCard(),
      WorkflowSectionTitle(
        fhcT(context, 'account.shareVia', fallback: 'Share via'),
      ),
      _iconChoices([
        (
          Icons.chat,
          fhcT(context, 'account.whatsapp', fallback: 'WhatsApp'),
          null,
        ),
        (
          Icons.email_outlined,
          fhcT(context, 'account.email', fallback: 'Email'),
          null,
        ),
        (
          Icons.message_outlined,
          fhcT(context, 'common.messages', fallback: 'Message'),
          null,
        ),
        (
          Icons.more_horiz,
          fhcT(context, 'common.more', fallback: 'More'),
          null,
        ),
      ]),
    ],
    AccountContinuationKind.paymentHistory => [
      WorkflowSegments(
        labels: [
          fhcT(context, 'account.all', fallback: 'All'),
          fhcT(context, 'account.tithe', fallback: 'Tithe'),
          fhcT(context, 'account.offering', fallback: 'Offering'),
          fhcT(context, 'account.missions', fallback: 'Missions'),
        ],
      ),
      const SizedBox(height: 12),
      WorkflowSummary(
        title: fhcT(
          context,
          'account.totalContributionsThisYear',
          fallback: 'Total Contributions This Year',
        ),
        subtitle: 'NGN 245,600.00  •  2025',
        metrics: [
          ('6', fhcT(context, 'account.months', fallback: 'Months')),
          ('18', fhcT(context, 'account.payments', fallback: 'Payments')),
          ('100%', fhcT(context, 'account.successful', fallback: 'Successful')),
        ],
      ),
      const WorkflowSectionTitle('May 2025'),
      _rows(const [
        ('Tithe', 'May 19, 2025  •  NGN 10,000.00'),
        ('Offering', 'May 18, 2025  •  NGN 5,000.00'),
        ('Missions', 'May 15, 2025  •  NGN 5,000.00'),
        ('Church Building Project', 'May 10, 2025  •  NGN 20,000.00'),
        ('KCA Training', 'May 7, 2025  •  NGN 15,000.00'),
        ('Family Camp', 'May 3, 2025  •  NGN 8,000.00'),
      ]),
    ],
    AccountContinuationKind.transaction => [
      _status(
        'NGN 10,000.00',
        fhcT(context, 'account.successful', fallback: 'Successful'),
        true,
      ),
      _details([
        (
          fhcT(context, 'account.purpose', fallback: 'Purpose'),
          'Tithe',
        ),
        (
          fhcT(context, 'account.referenceId', fallback: 'Reference ID'),
          'PAY-2025-0519-000123',
        ),
        (
          fhcT(context, 'account.dateTime', fallback: 'Date & Time'),
          'May 19, 2025 • 10:30 AM',
        ),
        (
          fhcT(context, 'account.paymentMethod', fallback: 'Payment Method'),
          'Mastercard •••• 4242',
        ),
        (
          fhcT(context, 'account.transactionId', fallback: 'Transaction ID'),
          'TXN-9F7B-2D4C-91E3',
        ),
        (
          fhcT(context, 'account.gateway', fallback: 'Gateway'),
          'Paystack',
        ),
        (
          fhcT(context, 'account.status', fallback: 'Status'),
          fhcT(context, 'account.successful', fallback: 'Successful'),
        ),
      ]),
    ],
    AccountContinuationKind.paymentPending => [
      _status(
        fhcT(context, 'account.paymentPending', fallback: 'Payment Pending'),
        fhcT(
          context,
          'account.paymentBeingProcessed',
          fallback: 'Your payment is being processed.',
        ),
        false,
      ),
      _details([
        (
          fhcT(context, 'account.amount', fallback: 'Amount'),
          'NGN 15,000.00',
        ),
        (
          fhcT(context, 'account.purpose', fallback: 'Purpose'),
          'KCA Training',
        ),
        (
          fhcT(context, 'account.referenceId', fallback: 'Reference ID'),
          'PAY-2025-0519-000456',
        ),
        (
          fhcT(context, 'account.dateTime', fallback: 'Date & Time'),
          'May 19, 2025 • 10:32 AM',
        ),
        (
          fhcT(context, 'account.paymentMethod', fallback: 'Payment Method'),
          'Visa •••• 7890',
        ),
      ]),
      _notice(
        fhcT(
          context,
          'account.notifyWhenConfirmed',
          fallback: 'We will notify you once your payment is confirmed.',
        ),
      ),
    ],
    AccountContinuationKind.refund => [
      _status(
        fhcT(context, 'account.refundInProgress', fallback: 'Refund In Progress'),
        fhcT(
          context,
          'account.processingRefund',
          fallback: 'We are processing your refund.',
        ),
        true,
      ),
      _details([
        (
          fhcT(context, 'account.originalPayment', fallback: 'Original Payment'),
          'NGN 20,000.00',
        ),
        (
          fhcT(context, 'account.referenceId', fallback: 'Reference ID'),
          'PAY-2025-0505-000789',
        ),
        (
          fhcT(context, 'account.refundId', fallback: 'Refund ID'),
          'REF-2025-0519-000111',
        ),
        (
          fhcT(context, 'account.requestedOn', fallback: 'Requested On'),
          'May 19, 2025 • 11:20 AM',
        ),
        (
          fhcT(context, 'account.reason', fallback: 'Reason'),
          'Duplicate Transaction',
        ),
      ]),
      _notice(
        fhcT(
          context,
          'account.refundBusinessDays',
          fallback: 'You will receive the refund in 3–5 business days.',
        ),
      ),
    ],
    AccountContinuationKind.dispute => [
      _status(
        fhcT(context, 'account.disputeOpen', fallback: 'Dispute Open'),
        fhcT(
          context,
          'account.reviewingDispute',
          fallback: 'We are reviewing your dispute.',
        ),
        false,
      ),
      _details([
        (
          fhcT(context, 'account.transaction', fallback: 'Transaction'),
          'NGN 15,000.00',
        ),
        (
          fhcT(context, 'account.referenceId', fallback: 'Reference ID'),
          'PAY-2025-0508-000321',
        ),
        (
          fhcT(context, 'account.disputeId', fallback: 'Dispute ID'),
          'DSP-2025-0519-000222',
        ),
        (
          fhcT(context, 'account.reason', fallback: 'Reason'),
          'Unauthorized Transaction',
        ),
        (
          fhcT(context, 'account.status', fallback: 'Status'),
          fhcT(context, 'account.underReview', fallback: 'Under Review'),
        ),
      ]),
      _notice(
        fhcT(
          context,
          'account.updateWithinSevenDays',
          fallback: 'We will update you within 7 business days.',
        ),
      ),
    ],
    AccountContinuationKind.recurringGiving => [
      _notice(
        fhcT(
          context,
          'account.recurringGivingNotLive',
          fallback:
              'Recurring giving is not on the live payments API yet. '
              'One-time gifts use Give with the activated provider.',
        ),
      ),
      FhcEmptyState(
        title: fhcT(
          context,
          'account.recurringGiftsUnavailable',
          fallback: 'Recurring gifts unavailable',
        ),
        message: fhcT(
          context,
          'account.recurringGiftsUnavailableCopy',
          fallback:
              'Scheduled tithes and offerings will appear here when the server '
              'supports them. No saved card or fake next-payment date is shown.',
        ),
      ),
    ],
    AccountContinuationKind.notificationPreferences => [
      for (final item in const [
        ('Push Notifications', 'Receive push notifications'),
        ('Email Notifications', 'Receive emails'),
        ('SMS Notifications', 'Receive SMS messages'),
        ('WhatsApp Notifications', 'Receive WhatsApp messages'),
        ('In-App Notifications', 'Receive in-app alerts'),
      ])
        _toggleRow(item.$1, item.$2),
      _notice('Stay updated about what matters most to you.'),
    ],
    AccountContinuationKind.communicationPreferences => [
      const WorkflowSectionTitle('I want to receive updates about:'),
      for (final label in const [
        'Church Updates',
        'Home Church Updates',
        'Department Updates',
        'KCA Updates',
        'Mission Updates',
        'Events & Programs',
      ])
        _preferenceRow(label),
      _notice('You can change these settings anytime.'),
    ],
    AccountContinuationKind.activeSessions => [
      _notice('Keep your account secure. You are signed in on these devices.'),
      const WorkflowSectionTitle('Current Session'),
      _rows(const [('iPhone 14 Pro', 'Lagos, Nigeria • This device')]),
      const WorkflowSectionTitle('Other Active Sessions'),
      _rows(const [
        ('Windows • Chrome', 'Abuja, Nigeria • May 18, 2025'),
        ('MacBook • Safari', 'Port Harcourt, Nigeria • May 17, 2025'),
      ]),
    ],
    AccountContinuationKind.privacy => [
      _notice('You control your data and who can see your information.'),
      _rows(const [
        ('Profile Visibility', 'Who can see my profile? Church Members'),
        ('Contact Information', 'Who can contact me? Church Leaders'),
        ('Activity Visibility', 'Who can see my activities? My Mentors'),
      ]),
      _toggleRow('Allow anonymous analytics', 'Improve Family House Connect'),
      _toggleRow('Marketing & Updates', 'Receive newsletters'),
    ],
    AccountContinuationKind.consents => [
      _notice('Review and manage your active consents.'),
      const WorkflowSegments(labels: ['Active', 'History']),
      _rows(const [
        ('Data Processing Consent', 'Granted on May 10, 2025 • Active'),
        ('Photo & Media Use', 'Granted on May 10, 2025 • Active'),
        ('Ministry Communication', 'Granted on Apr 20, 2025 • Active'),
        ('Children Data Consent', 'Granted on May 12, 2025 • Active'),
      ]),
    ],
    AccountContinuationKind.dataExport => [
      _notice('Export your data. Download a copy at any time.'),
      const WorkflowSectionTitle('Select Data to Export'),
      _checkList(const [
        'Profile Information',
        'Ministry & Activities',
        'Payment & Transactions',
        'Documents & Files',
        'Communication',
      ]),
      const WorkflowField(label: 'Export Format', value: 'PDF (Readable)'),
    ],
    AccountContinuationKind.accountDeletion => [
      _notice(
        'We are sorry to see you go. Your account and data can be deleted.',
      ),
      const WorkflowSectionTitle('Before you continue'),
      _checkList(const [
        'Download a copy of your data',
        'Cancel active subscriptions',
        'Review our data deletion policy',
      ]),
      const WorkflowSectionTitle('What happens next?'),
      const Text(
        'Your account and data will be permanently deleted within 30 days of your request.',
        style: FhcTypography.body,
      ),
      const SizedBox(height: 16),
      const WorkflowField(label: 'Type DELETE to confirm', value: 'DELETE'),
    ],
    AccountContinuationKind.childProfile => [
      _profileCard('Treasure Samuel', 'Age 12 • Child / Youth Profile'),
      _details(const [
        ('Date of Birth', 'May 14, 2013'),
        ('Gender', 'Female'),
        ('Church', 'The Garden House, Lagos'),
        ('Membership Type', 'Child Member'),
      ]),
    ],
    AccountContinuationKind.guardianControls => [
      _notice('Manage access and permissions for your child.'),
      _toggleRow('Allow App Sign-in', 'App access'),
      for (final label in const [
        'Events & Announcements',
        'KCA Learning',
        'Chat / Messaging',
        'Prayer Requests',
      ])
        _toggleRow(label, 'Allowed feature'),
      const WorkflowField(label: 'Daily Usage Limit', value: '2 hours'),
    ],
    AccountContinuationKind.guardianConsent => [
      _notice('Review and provide consent for your child’s activities.'),
      _rows(const [
        ('KCA Enrollment', 'Kingdom Change Agent Training • Approved'),
        ('Mission Trip', 'Youth Outreach • July 2025 • Pending'),
        ('Media & Photo Use', 'Church & Ministry Media • Approved'),
      ]),
      const WorkflowSectionTitle('Consent History'),
      _rows(const [
        ('May 10, 2025', 'KCA Enrollment • Approved'),
        ('Apr 20, 2025', 'Media & Photo Use • Approved'),
      ]),
    ],
    AccountContinuationKind.restrictedCommunication => [
      _status(
        'Communication Restricted',
        'Messaging is limited to protect children.',
        false,
      ),
      const WorkflowSectionTitle('You can'),
      _checkList(const [
        'View church announcements',
        'Message assigned mentors & leaders',
        'Receive updates and notifications',
      ]),
      const WorkflowSectionTitle('You cannot'),
      _rows(const [
        ('Message other members directly', 'Restricted'),
        ('Send media or files', 'Restricted'),
        ('Add or remove contacts', 'Restricted'),
      ]),
    ],
    AccountContinuationKind.safeguardingReport => [
      _notice('Report a safeguarding concern. Your report is confidential.'),
      const WorkflowField(
        label: 'Report Type',
        value: 'Select the type of concern',
      ),
      const WorkflowField(
        label: 'Incident Date',
        value: 'May 19, 2025',
        icon: Icons.calendar_today_outlined,
      ),
      const WorkflowField(label: 'Location', value: 'Select location'),
      const WorkflowField(
        label: 'Description',
        value: 'Provide full details of the incident',
        lines: 4,
      ),
      const WorkflowUploadBox(label: 'Upload evidence (optional)'),
    ],
    AccountContinuationKind.pastoralRecord => [
      _notice('Pastoral / Counselling Record. This information is restricted.'),
      const SizedBox(height: 28),
      const Center(
        child: Icon(Icons.lock, size: 96, color: FhcColors.greenDark),
      ),
      const SizedBox(height: 20),
      const Text(
        'Restricted Access',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      const Text(
        'Pastoral records are private and can only be viewed by authorized leaders.',
        textAlign: TextAlign.center,
        style: FhcTypography.body,
      ),
    ],
    AccountContinuationKind.aiHub => [
      _notice(
        'AI Assistants help with ministry insight while leaders remain responsible.',
      ),
      _rows(const [
        ('Pastoral Assistant', 'Biblical insights and pastoral guidance'),
        ('Mission Assistant', 'Follow-up analysis & mission support'),
        ('KCA Study Assistant', 'Learning help & study guidance'),
        ('Press Assistant', 'Find resources & publications'),
      ], onTap: () => fhcPush(context, '/ai/pastoral')),
      const WorkflowSectionTitle('Recent Conversations'),
      _rows(const [
        ('How can I grow in my faith?', 'May 19, 2025'),
        ('Prayer strategies for youth', 'May 18, 2025'),
      ]),
    ],
    AccountContinuationKind.pastoralAssistant => [
      _notice('Pastoral AI offers biblical guidance and pastoral support.'),
      const WorkflowSegments(labels: ['Chat', 'Resources']),
      _chat('How can I help someone struggling with anxiety?', true),
      _chat(
        'Encourage them with God’s promises, listen with empathy, pray together, and guide them to seek help from a pastor or counsellor.\n\nReferences: Philippians 4:6–7, 1 Peter 5:7',
        false,
      ),
      _chat('What Bible verses can I share?', true),
      const WorkflowField(label: 'Ask follow-up…', value: 'Type your message'),
    ],
    AccountContinuationKind.paymentProcessing => [
      _notice('Secure Payment. Your payment is waiting on the provider.'),
      const Center(child: CircularProgressIndicator.adaptive()),
    ],
    AccountContinuationKind.paymentSuccess => [
      _status('Payment Successful!', 'Thank you for your generosity.', true),
    ],
    AccountContinuationKind.paymentFailed => [
      _status('Payment Failed', 'We could not process your payment.', false),
      _notice('Try again from Give after an administrator activates checkout.'),
    ],
  };

  static const _receiptDetails = [
    ('Amount', 'NGN 10,000.00'),
    ('Currency', 'NGN'),
    ('Purpose', 'Tithe'),
    ('Reference ID', 'PAY-2025-0519-000123'),
    ('Date', 'May 19, 2025 • 10:30 AM'),
    ('Payment Method', 'Mastercard •••• 4242'),
    ('Status', 'Successful'),
  ];

  Widget _status(String title, String subtitle, bool positive) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: (positive ? FhcColors.green : FhcColors.orange).withValues(
        alpha: .10,
      ),
      borderRadius: BorderRadius.circular(FhcRadius.card),
    ),
    child: Column(
      children: [
        Icon(
          positive ? Icons.check_circle : Icons.error_outline,
          size: 54,
          color: positive ? FhcColors.green : FhcColors.orange,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: FhcTypography.caption,
        ),
      ],
    ),
  );

  Widget _notice(String text) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FhcColors.mint,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 20, color: FhcColors.green),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: FhcTypography.body)),
      ],
    ),
  );

  Widget _details(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(value.$1, style: FhcTypography.caption)),
                Expanded(
                  child: Text(
                    value.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _receiptCard() => WorkflowCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FAMILY HOUSE CONNECT',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Text('Official Receipt', style: FhcTypography.caption),
        const SizedBox(height: 14),
        _details(_liveReceiptRows().take(5).toList()),
        const SizedBox(height: 14),
        const Center(child: Icon(Icons.qr_code_2, size: 74)),
        const Center(
          child: Text('Scan to verify', style: FhcTypography.caption),
        ),
      ],
    ),
  );

  Widget _rows(List<(String, String)> values, {VoidCallback? onTap}) =>
      WorkflowCard(
        child: Column(
          children: [
            for (final value in values)
              WorkflowRow(title: value.$1, subtitle: value.$2, onTap: onTap),
          ],
        ),
      );

  Widget _toggleRow(String title, String subtitle) => WorkflowCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(subtitle, style: FhcTypography.caption),
            ],
          ),
        ),
        Switch(
          value: enabled,
          activeTrackColor: FhcColors.green,
          onChanged: (value) => setState(() => enabled = value),
        ),
      ],
    ),
  );

  Widget _preferenceRow(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(
          width: 150,
          child: WorkflowSegments(labels: ['All', 'Important', 'None']),
        ),
      ],
    ),
  );

  Widget _checkList(List<String> labels) => WorkflowCard(
    child: Column(
      children: [
        for (final label in labels)
          WorkflowRow(
            title: label,
            leading: Icons.check_circle,
            trailing: const SizedBox.shrink(),
          ),
      ],
    ),
  );

  Widget _profileCard(String name, String subtitle) => WorkflowCard(
    child: Row(
      children: [
        const CircleAvatar(
          radius: 29,
          backgroundColor: FhcColors.mint,
          child: Icon(Icons.person, color: FhcColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(subtitle, style: FhcTypography.caption),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _iconChoices(List<(IconData, String, VoidCallback?)> items) => Row(
    children: [
      for (final item in items)
        Expanded(
          child: InkWell(
            onTap: item.$3,
            borderRadius: BorderRadius.circular(9),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FhcColors.canvas,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item.$1, color: FhcColors.greenDark),
                ),
                const SizedBox(height: 5),
                Text(item.$2, style: FhcTypography.caption),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _chat(String text, bool user) => Align(
    alignment: user ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(13),
      constraints: const BoxConstraints(maxWidth: 310),
      decoration: BoxDecoration(
        color: user ? FhcColors.canvas : FhcColors.mint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: FhcTypography.body),
    ),
  );
}

class _AccountSpec {
  const _AccountSpec(this.title, this.action, this.next);
  final String title;
  final String? action;
  final String? next;
}

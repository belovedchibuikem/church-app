import 'package:flutter/material.dart';

import '../../core/api/app_failure.dart';
import '../../core/design_system/fhc_tokens.dart';
import '../../core/di/app_services_scope.dart';
import '../../core/l10n/locale_scope.dart';
import '../../features/foundation/data/auth_repository.dart';

/// Modal MFA step-up for recent-MFA gated mutations (profile, etc.).
///
/// Returns `true` when [LaravelAuthRepository.challengeMfa] succeeds.
Future<bool> showRecentMfaChallengeSheet(
  BuildContext context, {
  String? reason,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _RecentMfaChallengeSheet(
          reason: reason ?? honestMfaRequiredMessage(
            const ForbiddenFailure(
              'Recent multi-factor authentication is required.',
              code: 'MFA_RECENT_REQUIRED',
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

class _RecentMfaChallengeSheet extends StatefulWidget {
  const _RecentMfaChallengeSheet({required this.reason});

  final String reason;

  @override
  State<_RecentMfaChallengeSheet> createState() =>
      _RecentMfaChallengeSheetState();
}

class _RecentMfaChallengeSheetState extends State<_RecentMfaChallengeSheet> {
  final _code = TextEditingController();
  final _recovery = TextEditingController();
  bool _submitting = false;
  String? _error;

  LaravelAuthRepository? get _auth {
    final repo = AppServicesScope.maybeOf(context)?.authRepository;
    return repo is LaravelAuthRepository ? repo : null;
  }

  @override
  void dispose() {
    _code.dispose();
    _recovery.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = _auth;
    if (auth == null) {
      setState(
        () => _error = fhcT(
          context,
          'errors.authNotConfigured',
          fallback: 'Auth repository is not configured.',
        ),
      );
      return;
    }
    if (_submitting) return;

    final code = _code.text.trim();
    final recovery = _recovery.text.trim();
    if (code.isEmpty && recovery.isEmpty) {
      setState(
        () => _error = fhcT(
          context,
          'auth.enterCodeOrRecovery',
          fallback: 'Enter a 6-digit code or a recovery code.',
        ),
      );
      return;
    }
    if (code.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(
        () => _error = fhcT(
          context,
          'auth.authenticatorSixDigits',
          fallback: 'Authenticator codes must be 6 digits.',
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await auth.challengeMfa(
      code: code.isEmpty ? null : code,
      recoveryCode: recovery.isEmpty ? null : recovery,
    );
    if (!mounted) return;

    switch (result) {
      case AppSuccess():
        Navigator.of(context).pop(true);
      case AppError(:final failure):
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fhcT(
              context,
              'account.mfaRequired',
              fallback: 'Confirm it is you',
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            widget.reason,
            style: const TextStyle(fontSize: 13, color: FhcColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: fhcT(
                context,
                'auth.authenticatorCode',
                fallback: 'Authenticator code',
              ),
              counterText: '',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recovery,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: fhcT(
                context,
                'auth.recoveryCode',
                fallback: 'Recovery code (optional)',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: FhcColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(
                _submitting
                    ? fhcT(context, 'common.verifying', fallback: 'Verifying…')
                    : fhcT(context, 'auth.verify', fallback: 'Verify'),
              ),
            ),
          ),
          TextButton(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(fhcT(context, 'common.cancel', fallback: 'Cancel')),
          ),
        ],
      ),
    );
  }
}

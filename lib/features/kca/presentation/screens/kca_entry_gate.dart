import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../dashboards/presentation/screens/kca_dashboard_screen.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../kca_access.dart';

class KcaEntryGate extends StatefulWidget {
  const KcaEntryGate({super.key, this.kcaRepository});

  final KcaRepository? kcaRepository;

  @override
  State<KcaEntryGate> createState() => _KcaEntryGateState();
}

class _KcaEntryGateState extends State<KcaEntryGate> {
  String? _message;
  String? _destination;
  bool _loading = true;

  KcaRepository? get _repo =>
      widget.kcaRepository ??
      AppServicesScope.maybeOf(context)?.kcaRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _destination == null) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _loading = false;
        _destination = 'overview';
        _message = 'Sign in to apply or continue KCA.';
      });
      return;
    }
    final result = await repo.getAccess();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        final destination = (value['destination'] as String?) ?? 'overview';
        setState(() {
          _loading = false;
          _destination = destination;
          _message = (value['next_step'] as String?) ??
              (value['label'] as String?) ??
              '';
        });
      case AppError(:final failure):
        setState(() {
          _loading = false;
          _destination = 'overview';
          _message = failure.message;
        });
    }
  }

  void _openPrimary() {
    final destination = _destination ?? 'overview';
    if (destination == 'student_dashboard') return;
    fhcGo(context, kcaRouteForDestination(destination));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const FhcDevicePage(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_destination == 'student_dashboard') {
      return const KcaDashboardScreen();
    }

    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: 'KCA', onBack: () => fhcGo(context, FhcRoutes.hub)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(Icons.school, size: 64, color: FhcColors.kca),
                  const SizedBox(height: 16),
                  const Text(
                    'Kingdom Change Agents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message ??
                        'Enroll to begin the journey, or continue if you are already a student.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: FhcColors.muted,
                    ),
                  ),
                  const Spacer(),
                  FhcPrimaryButton(
                    label: kcaCtaLabel(_destination),
                    color: FhcColors.kca,
                    onPressed: _openPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

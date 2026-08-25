import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

enum _ModuleStatus { completed, inProgress, notStarted }

class KcaModulesScreen extends StatefulWidget {
  const KcaModulesScreen({super.key});

  @override
  State<KcaModulesScreen> createState() => _KcaModulesScreenState();
}

class _KcaModulesScreenState extends State<KcaModulesScreen> {
  int _tab = 0;

  static const _tabs = ['All Modules', 'My Progress'];

  static const _modules = <_ModuleSpec>[
    _ModuleSpec(1, 'Foundations of Faith', _ModuleStatus.completed),
    _ModuleSpec(2, 'Walking with Christ', _ModuleStatus.completed),
    _ModuleSpec(3, 'The Word of God', _ModuleStatus.completed),
    _ModuleSpec(4, 'Prayer & Spiritual Life', _ModuleStatus.completed),
    _ModuleSpec(5, 'Identity & Purpose', _ModuleStatus.inProgress),
    _ModuleSpec(6, 'The Holy Spirit', _ModuleStatus.notStarted),
    _ModuleSpec(7, 'Discipleship Essentials', _ModuleStatus.notStarted),
    _ModuleSpec(8, 'Leadership & Influence', _ModuleStatus.notStarted),
    _ModuleSpec(9, 'Evangelism & Mission', _ModuleStatus.notStarted),
    _ModuleSpec(10, 'Church & Community', _ModuleStatus.notStarted),
    _ModuleSpec(11, 'Stewardship & Service', _ModuleStatus.notStarted),
    _ModuleSpec(12, 'Commissioning', _ModuleStatus.notStarted),
  ];

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kca);
    }
  }

  void _openInProgress() => fhcPush(context, FhcRoutes.kcaModule);

  @override
  Widget build(BuildContext context) {
    final visible =
        _tab == 0
            ? _modules
            : _modules
                .where((m) => m.status != _ModuleStatus.notStarted)
                .toList();

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(title: 'KCA Modules', onBack: _back),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '12 Modules One Journey',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: FhcColors.muted,
                ),
              ),
            ),
          ),
          ColoredBox(
            color: FhcColors.white,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabLabel(
                      label: _tabs[i],
                      active: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                if (_tab == 1) ...[
                  const _ProgressOverview(),
                  const SizedBox(height: 12),
                ],
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ModuleRow(
                    spec: visible[i],
                    onTap:
                        visible[i].status == _ModuleStatus.inProgress
                            ? _openInProgress
                            : null,
                  ),
                ],
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _ModuleSpec {
  const _ModuleSpec(this.number, this.title, this.status);

  final int number;
  final String title;
  final _ModuleStatus status;
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
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
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? FhcColors.green : FhcColors.border,
                width: active ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: active ? FhcColors.green : FhcColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Your Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '4 / 12',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.greenDark,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 4 / 12,
              minHeight: 8,
              backgroundColor: FhcColors.border,
              valueColor: AlwaysStoppedAnimation(FhcColors.green),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Module 5 · Identity & Purpose',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: FhcColors.muted, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.spec, this.onTap});

  final _ModuleSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inProgress = spec.status == _ModuleStatus.inProgress;
    final notStarted = spec.status == _ModuleStatus.notStarted;
    final statusLabel = switch (spec.status) {
      _ModuleStatus.completed => 'Completed',
      _ModuleStatus.inProgress => 'In Progress',
      _ModuleStatus.notStarted => 'Not Started',
    };
    final statusColor = switch (spec.status) {
      _ModuleStatus.completed => FhcColors.green,
      _ModuleStatus.inProgress => FhcColors.gold,
      _ModuleStatus.notStarted => FhcColors.hint,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.card),
            border: Border.all(
              color: inProgress ? FhcColors.green : FhcColors.border,
            ),
            boxShadow: FhcElevation.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                _NumberBadge(number: spec.number, status: spec.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module ${spec.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: notStarted ? FhcColors.hint : FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: notStarted ? FhcColors.hint : FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      height: 1.1,
                    ),
                  ),
                ),
                if (inProgress)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: FhcColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.status});

  final int number;
  final _ModuleStatus status;

  @override
  Widget build(BuildContext context) {
    final completed = status == _ModuleStatus.completed;
    final inProgress = status == _ModuleStatus.inProgress;
    final fill =
        completed
            ? FhcColors.green
            : inProgress
            ? FhcColors.kca
            : FhcColors.border;
    final fg = completed || inProgress ? FhcColors.white : FhcColors.hint;

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child:
          completed
              ? const Icon(Icons.check, size: 18, color: FhcColors.white)
              : Text(
                '$number',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1,
                ),
              ),
    );
  }
}

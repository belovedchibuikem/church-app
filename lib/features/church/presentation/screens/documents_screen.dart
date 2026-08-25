import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

enum _DocKind { sermon, policy, form }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  int _tab = 0;

  static const _tabs = <String>['All', 'Sermons', 'Policies', 'Forms'];

  static const _docs = <_DocItem>[
    _DocItem(
      title: 'Church Constitution',
      size: '2.4 MB',
      kind: _DocKind.policy,
    ),
    _DocItem(title: 'Membership Form', size: '1.2 MB', kind: _DocKind.form),
    _DocItem(
      title: 'Baptism Guidelines',
      size: '890 KB',
      kind: _DocKind.policy,
    ),
    _DocItem(title: 'Financial Policy', size: '1.5 MB', kind: _DocKind.policy),
    _DocItem(
      title: 'Child Protection Policy',
      size: '1.1 MB',
      kind: _DocKind.policy,
    ),
    _DocItem(
      title: 'Sermon Series: Faith',
      size: '3.2 MB',
      kind: _DocKind.sermon,
    ),
  ];

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.churchHome);
    }
  }

  List<_DocItem> get _visible {
    return switch (_tab) {
      1 => _docs.where((d) => d.kind == _DocKind.sermon).toList(),
      2 => _docs.where((d) => d.kind == _DocKind.policy).toList(),
      3 => _docs.where((d) => d.kind == _DocKind.form).toList(),
      _ => _docs,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(title: 'Documents', onBack: _goBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _DocTab(
                      label: _tabs[i],
                      active: i == _tab,
                      onTap: () => setState(() => _tab = i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: FhcColors.border),
                  _DocRow(item: items[i]),
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

class _DocItem {
  const _DocItem({required this.title, required this.size, required this.kind});

  final String title;
  final String size;
  final _DocKind kind;
}

class _DocTab extends StatelessWidget {
  const _DocTab({
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 32,
            decoration: BoxDecoration(
              color: active ? FhcColors.green : const Color(0xFFEEF0EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? FhcColors.white : FhcColors.muted,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.item});

  final _DocItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.title}, PDF, ${item.size}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const _PdfBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: FhcColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF • ${item.size}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: FhcColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: FhcSizes.minTap,
                  minHeight: FhcSizes.minTap,
                ),
                icon: const Icon(Icons.download_outlined, size: 22),
                color: FhcColors.muted,
                tooltip: 'Download ${item.title}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfBadge extends StatelessWidget {
  const _PdfBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FhcColors.red,
        borderRadius: BorderRadius.circular(FhcRadius.sm),
      ),
      child: const Text(
        'PDF',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: FhcColors.white,
          height: 1,
        ),
      ),
    );
  }
}

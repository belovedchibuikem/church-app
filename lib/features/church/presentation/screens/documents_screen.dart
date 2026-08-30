import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, this.repository});

  final ChurchRepository? repository;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
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
            'member.documentsRequireApi',
            fallback:
                'Documents require the authenticated documents API. '
                'No fixture list is shown.',
          ),
        );
      });
      return;
    }
    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repository.listDocuments();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _state = value.isEmpty
              ? FhcAsyncValue.empty(
                  message: fhcT(
                    context,
                    'member.noDocumentsYet',
                    fallback: 'No documents are available yet.',
                  ),
                )
              : FhcAsyncValue.data(value);
        });
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  String _title(JsonObject doc) =>
      '${doc['title'] ?? doc['name'] ?? 'Document'}'.trim();

  String _meta(JsonObject doc) {
    final format = '${doc['format'] ?? doc['mime_type'] ?? ''}'.trim();
    final size = '${doc['size_label'] ?? doc['size'] ?? ''}'.trim();
    return [if (format.isNotEmpty) format, if (size.isNotEmpty) size]
        .join(' · ');
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
            title: fhcT(context, 'member.documents', fallback: 'Documents'),
            onBack: _goBack,
          ),
          Expanded(
            child: FhcAsyncBody<List<JsonObject>>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.noDocuments',
                fallback: 'No documents',
              ),
              unavailableTitle: fhcT(
                context,
                'member.documentsUnavailable',
                fallback: 'Documents unavailable',
              ),
              builder: (context, docs) {
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: FhcColors.border),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: FhcColors.mint,
                          child: Icon(
                            Icons.description_outlined,
                            color: FhcColors.green,
                          ),
                        ),
                        title: Text(
                          _title(doc),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: _meta(doc).isEmpty
                            ? null
                            : Text(_meta(doc), style: FhcTypography.caption),
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

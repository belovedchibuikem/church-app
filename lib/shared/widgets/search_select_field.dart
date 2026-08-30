import 'package:flutter/material.dart';

import '../../core/design_system/fhc_tokens.dart';
import '../../core/geography/geography_catalog.dart';
import '../../core/l10n/locale_scope.dart';

/// Searchable single-select control used by [GeographySelect] and forms.
class SearchSelectField extends StatelessWidget {
  const SearchSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
    this.required = false,
    this.enabled = true,
    this.loading = false,
    this.validator,
  });

  final String label;
  final String value;
  final List<GeoSelectOption> options;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final bool required;
  final bool enabled;
  final bool loading;
  final FormFieldValidator<String>? validator;

  String get _display {
    if (value.isEmpty) return '';
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || loading) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FhcColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _SearchSelectSheet(
          title: label,
          options: options,
          selectedValue: value,
          placeholder:
              placeholder ??
              fhcT(context, 'common.search', fallback: 'Search…'),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveValidator =
        validator ??
        (required
            ? (v) {
              if (v == null || v.trim().isEmpty) {
                return fhcT(context, 'errors.required', fallback: 'Required');
              }
              return null;
            }
            : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormField<String>(
        initialValue: value,
        validator: effectiveValidator,
        builder: (state) {
          if (state.value != value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (state.mounted) state.didChange(value);
            });
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: label,
                  style: FhcTypography.label,
                  children: [
                    if (required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: FhcColors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled && !loading ? () => _openPicker(context) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    isEmpty: _display.isEmpty,
                    decoration: InputDecoration(
                      hintText:
                          loading
                              ? fhcT(
                                context,
                                'common.loading',
                                fallback: 'Loading…',
                              )
                              : placeholder,
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: FhcColors.hint,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: enabled ? Colors.white : FhcColors.canvas,
                      errorText: state.errorText,
                      suffixIcon:
                          loading
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : const Icon(
                                Icons.expand_more,
                                size: 20,
                                color: FhcColors.muted,
                              ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FhcColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FhcColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: FhcColors.green,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: FhcColors.red),
                      ),
                    ),
                    child: Text(
                      _display.isEmpty ? (placeholder ?? '') : _display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _display.isEmpty
                                ? FhcColors.hint
                                : (enabled ? FhcColors.ink : FhcColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchSelectSheet extends StatefulWidget {
  const _SearchSelectSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.placeholder,
  });

  final String title;
  final List<GeoSelectOption> options;
  final String selectedValue;
  final String placeholder;

  @override
  State<_SearchSelectSheet> createState() => _SearchSelectSheetState();
}

class _SearchSelectSheetState extends State<_SearchSelectSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final filtered = [
      for (final option in widget.options)
        if (q.isEmpty ||
            option.label.toLowerCase().contains(q) ||
            option.value.toLowerCase().contains(q) ||
            (option.meta?.toLowerCase().contains(q) ?? false))
          option,
    ];
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FhcColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: FhcTypography.titleSmall),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: fhcT(context, 'common.close', fallback: 'Close'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  filtered.isEmpty
                      ? Center(
                        child: Text(
                          fhcT(
                            context,
                            'common.noResults',
                            fallback: 'No matches found.',
                          ),
                          style: const TextStyle(color: FhcColors.muted),
                        ),
                      )
                      : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final selected =
                              option.value == widget.selectedValue;
                          return ListTile(
                            title: Text(option.label),
                            subtitle:
                                option.meta == null
                                    ? null
                                    : Text(option.meta!),
                            trailing:
                                selected
                                    ? const Icon(
                                      Icons.check,
                                      color: FhcColors.green,
                                    )
                                    : null,
                            onTap:
                                () => Navigator.pop(context, option.value),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

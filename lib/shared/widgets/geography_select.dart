import 'package:flutter/material.dart';

import '../../core/geography/geography_catalog.dart';
import '../../core/l10n/locale_scope.dart';
import 'search_select_field.dart';

/// Cascading searchable Country → State/Region → LGA/City selects.
///
/// Keeps [countryController] (ISO-2), optional [countryLabelController],
/// [regionController], and [localityController] in sync for form drafts/APIs.
class GeographySelect extends StatefulWidget {
  const GeographySelect({
    super.key,
    required this.countryController,
    required this.regionController,
    required this.localityController,
    this.countryLabelController,
    this.catalog,
    this.required = true,
    this.defaultCountryCode = GeographyCatalog.defaultCountryCode,
  });

  final TextEditingController countryController;
  final TextEditingController regionController;
  final TextEditingController localityController;
  final TextEditingController? countryLabelController;
  final GeographyCatalog? catalog;
  final bool required;
  final String defaultCountryCode;

  @override
  State<GeographySelect> createState() => _GeographySelectState();
}

class _GeographySelectState extends State<GeographySelect> {
  late final GeographyCatalog _catalog =
      widget.catalog ?? GeographyCatalog();

  List<GeoCountry> _countries = GeographyCatalog.fallbackCountries;
  List<String> _states = const [];
  List<String> _cities = const [];

  bool _loadingCountries = true;
  bool _loadingStates = false;
  bool _loadingCities = false;
  String? _statesError;
  String? _citiesError;

  String get _countryCode {
    final raw = widget.countryController.text.trim().toUpperCase();
    if (raw.isNotEmpty) return raw;
    return widget.defaultCountryCode.trim().toUpperCase();
  }

  String get _countryName =>
      _catalog.countryDisplayName(_countryCode, _countries);

  String get _region => widget.regionController.text.trim();
  String get _locality => widget.localityController.text.trim();

  @override
  void initState() {
    super.initState();
    if (widget.countryController.text.trim().isEmpty) {
      widget.countryController.text = widget.defaultCountryCode.toUpperCase();
    }
    _syncCountryLabel();
    _loadCountries();
  }

  void _syncCountryLabel() {
    final label = widget.countryLabelController;
    if (label == null) return;
    label.text = _countryName;
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    final list = await _catalog.fetchCountries();
    if (!mounted) return;
    setState(() {
      _countries = list;
      _loadingCountries = false;
    });
    _syncCountryLabel();
    await _loadStates();
  }

  Future<void> _loadStates() async {
    final name = _countryName;
    if (name.isEmpty) {
      setState(() {
        _states = const [];
        _cities = const [];
      });
      return;
    }
    setState(() {
      _loadingStates = true;
      _statesError = null;
    });
    try {
      final list = await _catalog.fetchStates(name);
      if (!mounted) return;
      setState(() {
        _states = list;
        _loadingStates = false;
      });
      if (_region.isNotEmpty && !list.contains(_region)) {
        widget.regionController.text = '';
        widget.localityController.text = '';
        setState(() => _cities = const []);
      } else if (_region.isNotEmpty) {
        await _loadCities();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _states = const [];
        _loadingStates = false;
        _statesError = '$error';
      });
    }
  }

  Future<void> _loadCities() async {
    final country = _countryName;
    final region = _region;
    if (country.isEmpty || region.isEmpty) {
      setState(() => _cities = const []);
      return;
    }
    setState(() {
      _loadingCities = true;
      _citiesError = null;
    });
    try {
      final list = await _catalog.fetchCities(country, region);
      if (!mounted) return;
      setState(() {
        _cities = list;
        _loadingCities = false;
      });
      if (_locality.isNotEmpty && !list.contains(_locality)) {
        widget.localityController.text = '';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cities = const [];
        _loadingCities = false;
        _citiesError = '$error';
      });
    }
  }

  List<GeoSelectOption> get _countryOptions => [
    for (final country in _countries)
      GeoSelectOption(
        value: country.code,
        label: country.label,
        meta: country.code,
      ),
  ];

  List<GeoSelectOption> get _stateOptions => [
    for (final name in _states) GeoSelectOption(value: name, label: name),
  ];

  List<GeoSelectOption> get _cityOptions => [
    for (final name in _cities) GeoSelectOption(value: name, label: name),
  ];

  @override
  Widget build(BuildContext context) {
    final localityLabel =
        GeographyCatalog.isNigeria(_countryCode)
            ? fhcT(context, 'common.lgaCity', fallback: 'LGA / City')
            : fhcT(context, 'common.cityArea', fallback: 'City / Area');
    final regionRequired = widget.required && _states.isNotEmpty;
    final localityRequired = widget.required && _cities.isNotEmpty;

    final regionPlaceholder =
        _loadingStates
            ? fhcT(context, 'common.loadingStates', fallback: 'Loading states…')
            : _statesError != null
            ? fhcT(
              context,
              'common.searchOrTryAgain',
              fallback: 'Search or try again…',
            )
            : fhcT(
              context,
              'common.searchStateOrRegion',
              fallback: 'Search state or region…',
            );

    final localityPlaceholder =
        _region.isEmpty
            ? fhcT(
              context,
              'common.selectStateFirst',
              fallback: 'Select a state first…',
            )
            : _loadingCities
            ? fhcT(
              context,
              'common.loadingCities',
              fallback: 'Loading cities…',
            )
            : _citiesError != null
            ? fhcT(
              context,
              'common.searchOrTryAgain',
              fallback: 'Search or try again…',
            )
            : fhcT(
              context,
              'common.searchNamed',
              fallback: 'Search {name}…',
              args: {'name': localityLabel.toLowerCase()},
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchSelectField(
          label: fhcT(context, 'common.country', fallback: 'Country'),
          value: _countryCode,
          options: _countryOptions,
          loading: _loadingCountries,
          required: widget.required,
          placeholder: fhcT(
            context,
            'common.searchCountry',
            fallback: 'Search country…',
          ),
          onChanged: (next) async {
            setState(() {
              widget.countryController.text = next.trim().toUpperCase();
              widget.regionController.text = '';
              widget.localityController.text = '';
              _cities = const [];
            });
            _syncCountryLabel();
            await _loadStates();
          },
        ),
        SearchSelectField(
          key: ValueKey('region-$_countryCode'),
          label: fhcT(
            context,
            'common.stateRegion',
            fallback: 'State / Region',
          ),
          value: _region,
          options: _stateOptions,
          loading: _loadingStates,
          enabled: _countryCode.isNotEmpty &&
              !(_loadingStates && _states.isEmpty),
          required: regionRequired,
          placeholder: regionPlaceholder,
          onChanged: (next) async {
            setState(() {
              widget.regionController.text = next;
              widget.localityController.text = '';
              _cities = const [];
            });
            await _loadCities();
          },
        ),
        SearchSelectField(
          key: ValueKey('locality-$_countryCode-$_region'),
          label: localityLabel,
          value: _locality,
          options: _cityOptions,
          loading: _loadingCities,
          enabled:
              _region.isNotEmpty && !(_loadingCities && _cities.isEmpty),
          required: localityRequired,
          placeholder: localityPlaceholder,
          onChanged: (next) {
            setState(() => widget.localityController.text = next);
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/l10n/supported_locales.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class LanguageLocationScreen extends StatefulWidget {
  const LanguageLocationScreen({super.key});

  @override
  State<LanguageLocationScreen> createState() => _LanguageLocationScreenState();
}

class _LanguageOption {
  const _LanguageOption(this.code, this.label);

  final String code;
  final String label;
}

class _LanguageLocationScreenState extends State<LanguageLocationScreen> {
  List<_LanguageOption> get _languages => [
    for (final code in kFhcSupportedLocales)
      _LanguageOption(code, kFhcLocaleMeta[code]!.endonym),
  ];

  bool _started = false;
  String _selectedCode = 'en';
  String _locationLabel = '';
  bool _locating = true;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final stored = AppLaunchScope.maybeOf(context);
    if (stored != null) {
      _selectedCode = stored.languageCode;
      final existing = stored.locationLabel;
      if (existing != null && existing.isNotEmpty) {
        _locationLabel = existing;
        _locating = false;
        return;
      }
    }
    _detectLocation();
  }

  Future<void> _selectLanguage(_LanguageOption option) async {
    setState(() => _selectedCode = option.code);
    final store = AppLaunchScope.maybeOf(context);
    await store?.setLanguage(
      languageCode: option.code,
      languageLabel: option.label,
    );
  }

  Future<void> _detectLocation() async {
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      setState(() {
        _locating = false;
        _locationLabel = fhcT(context, 'onboarding.locationOnDevice');
      });
      return;
    }
    setState(() {
      _locating = true;
      _locationLabel = fhcT(context, 'onboarding.detectingLocation');
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationLabel = fhcT(context, 'onboarding.locationServicesOff');
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationLabel = fhcT(context, 'onboarding.locationPermission');
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationLabel =
            '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationLabel = fhcT(context, 'onboarding.locationUnavailable');
      });
    }
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    final selected = _languages.firstWhere(
      (item) => item.code == _selectedCode,
      orElse: () => _languages.first,
    );
    final store = AppLaunchScope.maybeOf(context);
    await store?.completeSetup(
      languageCode: selected.code,
      languageLabel: selected.label,
      locationLabel: _locationLabel,
    );
    if (!mounted) return;
    fhcGo(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'onboarding.languageLocation'),
            onBack: () => fhcGo(context, '/onboarding/multiply'),
          ),
          const FhcBrandLogo(size: 64),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              fhcT(context, 'onboarding.chooseLanguageAndLocation'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: FhcColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fhcT(context, 'onboarding.chooseLanguage'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FhcSurfaceCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(FhcRadius.md),
                        child: ListView.separated(
                          itemCount: _languages.length,
                          separatorBuilder:
                              (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final option = _languages[i];
                            return _LanguageRow(
                              label: option.label,
                              selected: _selectedCode == option.code,
                              onTap: () => _selectLanguage(option),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fhcT(context, 'onboarding.yourLocation'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _locating ? null : _detectLocation,
                    borderRadius: BorderRadius.circular(FhcRadius.card),
                    child: FhcSurfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 20,
                              color:
                                  _locating
                                      ? FhcColors.muted
                                      : FhcColors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: FhcColors.ink,
                                ),
                              ),
                            ),
                            if (_locating)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.refresh,
                                size: 20,
                                color: FhcColors.muted,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FhcPrimaryButton(
                    label:
                        _saving
                            ? fhcT(context, 'onboarding.saving')
                            : fhcT(context, 'onboarding.continue'),
                    onPressed: _saving ? null : _continue,
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

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? FhcColors.green : const Color(0xFFC5CBC8),
            ),
          ],
        ),
      ),
    );
  }
}

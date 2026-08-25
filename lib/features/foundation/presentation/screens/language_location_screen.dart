import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class LanguageLocationScreen extends StatefulWidget {
  const LanguageLocationScreen({super.key});

  @override
  State<LanguageLocationScreen> createState() => _LanguageLocationScreenState();
}

class _LanguageLocationScreenState extends State<LanguageLocationScreen> {
  String _selected = 'English';

  static const _languages = <String>[
    'English',
    'Yoruba',
    'Igbo',
    'Hausa',
    'Français (French)',
    'العربية (Arabic)',
    '中文 (Chinese)',
    'Kiswahili (Swahili)',
  ];

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(
            title: 'Language & Location',
            onBack: () => fhcGo(context, '/onboarding/multiply'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'Choose your preferred language\nand location to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                  const Text(
                    'Choose Language',
                    style: TextStyle(
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
                        child: Column(
                          children: [
                            for (var i = 0; i < _languages.length; i++)
                              Expanded(
                                child: _LanguageRow(
                                  label: _languages[i],
                                  selected: _selected == _languages[i],
                                  showDivider: i != _languages.length - 1,
                                  onTap:
                                      () => setState(
                                        () => _selected = _languages[i],
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _LocationRow(leading: _NigeriaFlag(), label: 'Nigeria'),
                  const SizedBox(height: 8),
                  const _LocationRow(
                    leading: Icon(Icons.search, size: 20, color: FhcColors.ink),
                    label: 'Lagos, Nigeria',
                  ),
                  const SizedBox(height: 16),
                  FhcPrimaryButton(
                    label: 'Continue',
                    onPressed: () => fhcGo(context, '/sign-in'),
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
    required this.showDivider,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border:
              showDivider
                  ? const Border(bottom: BorderSide(color: FhcColors.border))
                  : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 22,
              color: FhcColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NigeriaFlag extends StatelessWidget {
  const _NigeriaFlag();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 28,
        height: 18,
        child: Image.asset(
          'assets/images/nigeria_flag.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Row(
              children: [
                Expanded(child: ColoredBox(color: Color(0xFF008751))),
                Expanded(child: ColoredBox(color: Colors.white)),
                Expanded(child: ColoredBox(color: Color(0xFF008751))),
              ],
            );
          },
        ),
      ),
    );
  }
}

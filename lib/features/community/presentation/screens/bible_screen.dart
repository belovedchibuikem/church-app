import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  static const _versions = <String>['KJV', 'NIV', 'NLT', 'ESV'];
  static const _verseRef = 'Philippians 4:13';
  static const _verseText =
      'I can do all things through Christ which strengtheneth me.';

  static const _quickAccess = <(IconData, String)>[
    (Icons.menu_book_outlined, 'Read Bible'),
    (Icons.checklist_outlined, 'Plans'),
    (Icons.bookmark_border, 'Bookmarks'),
    (Icons.highlight_outlined, 'Highlights'),
  ];

  static const _recent = <(String, String)>[
    ('John 3', 'Yesterday'),
    ('Romans 8', '3 days ago'),
    ('Psalm 23', 'Last week'),
  ];

  String _version = 'KJV';

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'Bible',
            onBack: _goBack,
            trailing: _KjvChip(
              version: _version,
              versions: _versions,
              onSelected: (value) => setState(() => _version = value),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                const _ScriptureSearch(),
                const SizedBox(height: 14),
                _VerseOfTheDayCard(
                  reference: _verseRef,
                  text: _verseText,
                  version: _version,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Quick Access',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                _QuickAccessGrid(items: _quickAccess),
                const SizedBox(height: 18),
                const Text(
                  'Recent Readings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                FhcSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < _recent.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: FhcColors.border),
                        _ReadingRow(
                          title: _recent[i].$1,
                          subtitle: _recent[i].$2,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _KjvChip extends StatelessWidget {
  const _KjvChip({
    required this.version,
    required this.versions,
    required this.onSelected,
  });

  final String version;
  final List<String> versions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Bible version',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      initialValue: version,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          for (final option in versions)
            PopupMenuItem<String>(
              value: option,
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      option == version ? FontWeight.w700 : FontWeight.w500,
                  color: option == version ? FhcColors.green : FhcColors.ink,
                ),
              ),
            ),
        ];
      },
      child: Semantics(
        button: true,
        label: 'Bible version $version',
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
            decoration: BoxDecoration(
              color: FhcColors.mint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  version,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.green,
                    height: 1.1,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: FhcColors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScriptureSearch extends StatelessWidget {
  const _ScriptureSearch();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return SizedBox(
      height: 44,
      child: TextField(
        style: FhcTypography.body,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search scripture...',
          hintStyle: FhcTypography.hint,
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: FhcColors.muted,
          ),
          suffixIcon: const Icon(Icons.tune, size: 18, color: FhcColors.muted),
          isDense: true,
          filled: true,
          fillColor: FhcColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: FhcColors.border),
            borderRadius: radius,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: FhcColors.border),
            borderRadius: radius,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  const _VerseOfTheDayCard({
    required this.reference,
    required this.text,
    required this.version,
  });

  final String reference;
  final String text;
  final String version;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Verse of the Day',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: FhcColors.green,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: FhcColors.mint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: FhcColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reference,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$reference ($version)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconAction(icon: Icons.ios_share_outlined, label: 'Share'),
              const SizedBox(width: 2),
              _IconAction(icon: Icons.bookmark_border, label: 'Bookmark'),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: () {},
        tooltip: label,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: FhcColors.muted),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.items});

  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _QuickTile(icon: items[0].$1, label: items[0].$2)),
            const SizedBox(width: 8),
            Expanded(child: _QuickTile(icon: items[1].$1, label: items[1].$2)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _QuickTile(icon: items[2].$1, label: items[2].$2)),
            const SizedBox(width: 8),
            Expanded(child: _QuickTile(icon: items[3].$1, label: items[3].$2)),
          ],
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.card);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: FhcColors.white,
              borderRadius: radius,
              border: Border.all(color: FhcColors.border),
              boxShadow: FhcElevation.card,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: FhcColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 22, color: FhcColors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FhcColors.ink,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: () {},
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: FhcColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 18,
                    color: FhcColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: FhcColors.muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
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

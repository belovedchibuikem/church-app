import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  static const _versions = <String>['KJV', 'NIV', 'NLT', 'ESV'];
  String _version = 'KJV';

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          _BibleHeader(
            version: _version,
            versions: _versions,
            onSelected: (value) => setState(() => _version = value),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                const _ScriptureSearch(),
                const SizedBox(height: 14),
                _VerseCard(version: _version),
                const SizedBox(height: 18),
                _SectionTitle(
                  fhcT(context, 'online.quickAccess', fallback: 'Quick Access'),
                ),
                const SizedBox(height: 10),
                const _QuickAccessRow(),
                const SizedBox(height: 18),
                _SectionTitle(
                  fhcT(
                    context,
                    'online.recentReadings',
                    fallback: 'Recent Readings',
                  ),
                ),
                const SizedBox(height: 10),
                const _RecentReadings(),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _BibleHeader extends StatelessWidget {
  const _BibleHeader({
    required this.version,
    required this.versions,
    required this.onSelected,
  });
  final String version;
  final List<String> versions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FhcSizes.topBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            fhcT(context, 'online.bible', fallback: 'Bible'),
            style: FhcTypography.titleSmall,
          ),
          Positioned(
            right: 12,
            child: PopupMenuButton<String>(
              tooltip: fhcT(
                context,
                'online.bibleVersion',
                fallback: 'Bible version',
              ),
              initialValue: version,
              onSelected: onSelected,
              itemBuilder:
                  (context) => [
                    for (final item in versions)
                      PopupMenuItem<String>(value: item, child: Text(item)),
                  ],
              child: Semantics(
                button: true,
                label: fhcT(
                  context,
                  'online.bibleVersionLabel',
                  args: {'version': version},
                  fallback: 'Bible version {version}',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        version,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScriptureSearch extends StatelessWidget {
  const _ScriptureSearch();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        textInputAction: TextInputAction.search,
        style: FhcTypography.body,
        decoration: InputDecoration(
          hintText: fhcT(
            context,
            'online.searchScripture',
            fallback: 'Search scripture...',
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: FhcColors.muted,
          ),
          suffixIcon: const Icon(Icons.tune, size: 18, color: FhcColors.muted),
          filled: true,
          fillColor: FhcColors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            borderSide: const BorderSide(color: FhcColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            borderSide: const BorderSide(color: FhcColors.border),
          ),
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.version});
  final String version;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fhcT(context, 'online.todaysVerse', fallback: "Today's Verse"),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FhcColors.muted,
                  ),
                ),
              ),
              const Icon(
                Icons.menu_book_outlined,
                size: 19,
                color: FhcColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Philippians 4:13',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'I can do all things through Christ\nwhich strengtheneth me.',
            style: TextStyle(fontSize: 14, height: 1.55, color: FhcColors.ink),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Philippians 4:13 ($version)',
                  style: const TextStyle(fontSize: 11, color: FhcColors.muted),
                ),
              ),
              _VerseAction(
                icon: Icons.ios_share_outlined,
                label: fhcT(context, 'online.share', fallback: 'Share'),
                action: fhcT(
                  context,
                  'online.sharingBibleVerse',
                  fallback: 'Sharing a Bible verse',
                ),
              ),
              const SizedBox(width: 8),
              _VerseAction(
                icon: Icons.bookmark_border,
                label: fhcT(context, 'online.bookmark', fallback: 'Bookmark'),
                action: fhcT(
                  context,
                  'online.savingBibleBookmark',
                  fallback: 'Saving a Bible bookmark',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerseAction extends StatelessWidget {
  const _VerseAction({
    required this.icon,
    required this.label,
    required this.action,
  });
  final IconData icon;
  final String label;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: () => fhcApiUnavailable(context, action: action),
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: FhcColors.ink),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: FhcColors.ink,
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow();
  static const _items = <(IconData, String, String)>[
    (Icons.menu_book_outlined, 'online.readBible', 'Read Bible'),
    (Icons.calendar_month_outlined, 'online.plans', 'Plans'),
    (Icons.bookmark_border, 'online.bookmarks', 'Bookmarks'),
    (Icons.draw_outlined, 'online.highlights', 'Highlights'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < _items.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _QuickTile(
              icon: _items[index].$1,
              label: fhcT(
                context,
                _items[index].$2,
                fallback: _items[index].$3,
              ),
            ),
          ),
        ],
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
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap:
            () => fhcApiUnavailable(
              context,
              action: fhcT(
                context,
                'online.openingItem',
                args: {'label': label},
                fallback: 'Opening {label}',
              ),
            ),
        borderRadius: BorderRadius.circular(FhcRadius.md),
        child: Ink(
          height: 104,
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.md),
            border: Border.all(color: FhcColors.border),
            boxShadow: FhcElevation.card,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: FhcColors.ink),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentReadings extends StatelessWidget {
  const _RecentReadings();

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _RecentRow(label: 'John 3'),
          Divider(height: 1),
          _RecentRow(label: 'Romans 8'),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => fhcApiUnavailable(
            context,
            action: fhcT(
              context,
              'online.openingReading',
              args: {'label': label},
              fallback: 'Opening the {label} reading',
            ),
          ),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 15, color: FhcColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FhcColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 19, color: FhcColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PressBookScreen extends StatefulWidget {
  const PressBookScreen({super.key});

  @override
  State<PressBookScreen> createState() => _PressBookScreenState();
}

class _PressBookScreenState extends State<PressBookScreen> {
  static const _formats = ['E-Book', 'Audio', 'PDF', 'Hardcover'];
  static const _about =
      'Walking in Purpose is a practical guide to discovering and living '
      'out God\'s call. Pastor Tunde Olaniyan shows how identity, obedience '
      'and daily discipline shape a life that multiplies the Kingdom.';

  bool _favorited = false;
  int _format = 0;

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      fhcGo(context, FhcRoutes.press);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          _BookTopBar(
            favorited: _favorited,
            onBack: _onBack,
            onFavorite: () => setState(() => _favorited = !_favorited),
            onShare: () {},
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final coverH = (constraints.maxHeight * 0.34).clamp(
                  148.0,
                  210.0,
                );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    _BookCover(height: coverH),
                    const SizedBox(height: 16),
                    const Text(
                      'Walking in Purpose',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: FhcColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'by Pastor Tunde Olaniyan',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: FhcColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _RatingRow(),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _formats.length; i++)
                          _FormatChip(
                            label: _formats[i],
                            selected: _format == i,
                            onTap: () => setState(() => _format = i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'About the Book',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FhcColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      _about,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: FhcColors.muted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const _ActionBar(),
        ],
      ),
    );
  }
}

class _BookTopBar extends StatelessWidget {
  const _BookTopBar({
    required this.favorited,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
  });

  final bool favorited;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FhcSizes.topBarHeight,
      child: Row(
        children: [
          SizedBox(
            width: FhcSizes.minTap,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 28),
              color: FhcColors.ink,
              tooltip: 'Back',
            ),
          ),
          const SizedBox(width: FhcSizes.minTap),
          const Expanded(
            child: Text(
              'Book',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FhcTypography.titleSmall,
            ),
          ),
          SizedBox(
            width: FhcSizes.minTap,
            child: IconButton(
              onPressed: onFavorite,
              padding: EdgeInsets.zero,
              icon: Icon(
                favorited ? Icons.favorite : Icons.favorite_border,
                size: 22,
              ),
              color: favorited ? FhcColors.red : FhcColors.ink,
              tooltip: favorited ? 'Remove favorite' : 'Favorite',
            ),
          ),
          SizedBox(
            width: FhcSizes.minTap,
            child: IconButton(
              onPressed: onShare,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: 'Share',
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final width = height * 0.68;
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FhcRadius.md),
          boxShadow: FhcElevation.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FhcRadius.md),
          child: Image.asset(
            'assets/images/book_walking_purpose.png',
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Image.asset(
                  'assets/images/press_book_cover.png',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => ColoredBox(
                        color: FhcColors.press,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: height * 0.28,
                              color: FhcColors.white.withValues(alpha: 0.92),
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Walking in\nPurpose',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: FhcColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, size: 16, color: FhcColors.gold),
        Icon(Icons.star, size: 16, color: FhcColors.gold),
        Icon(Icons.star, size: 16, color: FhcColors.gold),
        Icon(Icons.star, size: 16, color: FhcColors.gold),
        Icon(Icons.star_half, size: 16, color: FhcColors.gold),
        SizedBox(width: 6),
        Text(
          '4.8',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? FhcColors.press : FhcColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? FhcColors.press : FhcColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: selected ? FhcColors.white : FhcColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: FhcPrimaryButton(
              label: 'Read Now',
              color: FhcColors.press,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: FhcSizes.buttonHeight,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: FhcColors.press,
                  side: const BorderSide(color: FhcColors.press),
                  minimumSize: const Size(0, FhcSizes.buttonHeight),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FhcRadius.button),
                  ),
                ),
                child: const Text(
                  'Download',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
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

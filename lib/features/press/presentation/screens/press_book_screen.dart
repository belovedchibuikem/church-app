import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/routing/fhc_route_args.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class PressBookScreen extends StatefulWidget {
  const PressBookScreen({super.key, this.publicationId, this.repository});

  final String? publicationId;
  final PressRepository? repository;

  @override
  State<PressBookScreen> createState() => _PressBookScreenState();
}

class _PressBookScreenState extends State<PressBookScreen> {
  bool _favorited = false;
  int _format = 0;
  bool _loading = true;
  bool _downloading = false;
  String? _error;
  JsonObject? _publication;
  bool _started = false;

  static const _reserved = {'book', 'categories', 'resource', 'audio', 'library'};

  PressRepository? get _repository =>
      widget.repository ??
      AppServicesScope.maybeOf(context)?.pressRepository;

  String? get _resolvedId {
    final explicit = widget.publicationId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromArgs = FhcRouteArgs.entityIdOf(context);
    if (fromArgs != null && fromArgs.trim().isNotEmpty) return fromArgs.trim();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is FhcRouteArgs && args.extra is String) {
      final extra = (args.extra as String).trim();
      if (extra.isNotEmpty) return extra;
    }
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id =
          args['id'] ?? args['publicationId'] ?? args['publicId'] ?? args['entityId'];
      if (id is String && id.trim().isNotEmpty) return id.trim();
    }

    final name = ModalRoute.of(context)?.settings.name ?? '';
    final parts = name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2 && parts.first == 'press') {
      final candidate = parts.length >= 3 ? parts[2] : parts[1];
      if (parts.length >= 3 &&
          (parts[1] == 'book' || parts[1] == 'publication') &&
          candidate.isNotEmpty) {
        return candidate;
      }
      if (!_reserved.contains(parts[1]) && parts[1].isNotEmpty) {
        return parts[1];
      }
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) {
      setState(() {
        _loading = false;
        _error = fhcT(
          context,
          'errors.pressPublicationsRequireApi',
          fallback:
              'Press publications require the Laravel public catalogue API. '
              'No fixture detail is shown.',
        );
      });
      return;
    }

    final id = _resolvedId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = fhcT(
          context,
          'errors.pressOpenFromLibrary',
          fallback:
              'Open a publication from the Press library so its public id can be loaded.',
        );
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await repository.getPublication(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _publication = value;
          _loading = false;
          final formats = _availableFormats(context, value);
          if (_format >= formats.length) _format = 0;
        });
      case AppError(:final failure):
        setState(() {
          _publication = null;
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _download() async {
    final repository = _repository;
    final id = _resolvedId ?? '${_publication?['id'] ?? ''}';
    if (repository == null || id.isEmpty) {
      await fhcApiUnavailable(
        context,
        action: fhcT(
          context,
          'nav.pressDownloadingAsset',
          fallback: 'Downloading a Press asset',
        ),
      );
      return;
    }
    setState(() => _downloading = true);
    final result = await repository.download(id);
    if (!mounted) return;
    setState(() => _downloading = false);
    switch (result) {
      case AppSuccess(:final value):
        final filename = '${value['filename'] ?? ''}'.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              filename.isEmpty
                  ? fhcT(
                      context,
                      'nav.pressDownloadReady',
                      fallback: 'Download ready.',
                    )
                  : fhcT(
                      context,
                      'nav.pressDownloadReadyNamed',
                      args: {'filename': filename},
                      fallback: 'Download ready: $filename',
                    ),
            ),
          ),
        );
      case AppError(:final failure):
        if (failure is IntegrationUnavailableFailure) {
          await fhcApiUnavailable(
            context,
            action: fhcT(
              context,
              'nav.pressDownloadingAsset',
              fallback: 'Downloading a Press asset',
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
    }
  }

  void _onBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      fhcGo(context, FhcRoutes.press);
    }
  }

  static List<String> _availableFormats(
    BuildContext context,
    JsonObject publication,
  ) {
    final format = '${publication['format'] ?? ''}'.trim();
    if (format.isEmpty) {
      return [fhcT(context, 'nav.pressDetails', fallback: 'Details')];
    }
    return [_titleCase(format)];
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _authorLine(BuildContext context, JsonObject publication) {
    final publisher = '${publication['publisher'] ?? ''}'.trim();
    if (publisher.isNotEmpty) {
      return fhcT(
        context,
        'nav.pressByPublisher',
        args: {'name': publisher},
        fallback: 'by $publisher',
      );
    }
    final category = '${publication['category'] ?? ''}'.trim();
    if (category.isNotEmpty) return category;
    return fhcT(
      context,
      'nav.pressBrand',
      fallback: 'Family House Press',
    );
  }

  @override
  Widget build(BuildContext context) {
    final publication = _publication;
    final title = publication == null
        ? fhcT(context, 'nav.pressPublication', fallback: 'Publication')
        : '${publication['title'] ?? fhcT(context, 'nav.pressPublication', fallback: 'Publication')}';
    final formats = publication == null
        ? <String>[fhcT(context, 'nav.pressDetails', fallback: 'Details')]
        : _availableFormats(context, publication);
    final about = publication == null
        ? ''
        : () {
            final description = '${publication['description'] ?? ''}'.trim();
            if (description.isNotEmpty) return description;
            final subtitle = '${publication['subtitle'] ?? ''}'.trim();
            if (subtitle.isNotEmpty) return subtitle;
            return fhcT(
              context,
              'nav.pressNoDescription',
              fallback: 'No description has been published for this title yet.',
            );
          }();

    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          _BookTopBar(
            favorited: _favorited,
            onBack: _onBack,
            onFavorite: () => setState(() => _favorited = !_favorited),
            onShare: () => fhcApiUnavailable(
              context,
              action: fhcT(
                context,
                'nav.pressSharingPublication',
                fallback: 'Sharing a publication',
              ),
            ),
          ),
          Expanded(child: _buildBody(title, formats, about, publication)),
          if (!_loading && _error == null && publication != null)
            _ActionBar(
              downloading: _downloading,
              onRead: () => fhcApiUnavailable(
                context,
                action: fhcT(
                  context,
                  'nav.pressOpeningReader',
                  fallback: 'Opening a Press asset reader',
                ),
              ),
              onDownload: _downloading ? null : _download,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    String title,
    List<String> formats,
    String about,
    JsonObject? publication,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return FhcErrorState(
        title: fhcT(
          context,
          'errors.unableToLoadPublication',
          fallback: 'Unable to load publication',
        ),
        message: _error!,
        onRetry: _load,
      );
    }
    if (publication == null) {
      return FhcEmptyState(
        title: fhcT(
          context,
          'errors.publicationUnavailable',
          fallback: 'Publication unavailable',
        ),
        message: fhcT(
          context,
          'errors.publicationNotFound',
          fallback:
              'This title could not be found in the public Press catalogue.',
        ),
        icon: Icons.menu_book_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverH = (constraints.maxHeight * 0.34).clamp(148.0, 210.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            _BookCover(height: coverH, title: title),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: FhcColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _authorLine(context, publication),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: FhcColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            _MetaRow(publication: publication),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < formats.length; i++)
                  _FormatChip(
                    label: formats[i],
                    selected: _format == i,
                    onTap: () => setState(() => _format = i),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              fhcT(context, 'nav.pressAboutBook', fallback: 'About the Book'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              about,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: FhcColors.muted,
              ),
            ),
          ],
        );
      },
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
              tooltip: fhcT(context, 'common.back', fallback: 'Back'),
            ),
          ),
          const SizedBox(width: FhcSizes.minTap),
          Expanded(
            child: Text(
              fhcT(context, 'nav.pressBook', fallback: 'Book'),
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
              tooltip: favorited
                  ? fhcT(
                      context,
                      'common.removeFavorite',
                      fallback: 'Remove favorite',
                    )
                  : fhcT(context, 'common.favorite', fallback: 'Favorite'),
            ),
          ),
          SizedBox(
            width: FhcSizes.minTap,
            child: IconButton(
              onPressed: onShare,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: fhcT(context, 'common.share', fallback: 'Share'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.height, required this.title});

  final double height;
  final String title;

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
          color: FhcColors.press,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FhcRadius.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: height * 0.28,
                color: FhcColors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.publication});

  final JsonObject publication;

  @override
  Widget build(BuildContext context) {
    final language = '${publication['language'] ?? ''}'.trim();
    final pages = publication['page_count'];
    final availability = '${publication['availability'] ?? ''}'.trim();
    final bits = <String>[
      if (language.isNotEmpty) language.toUpperCase(),
      if (pages is num)
        fhcT(
          context,
          'nav.pressPageCount',
          args: {'count': '$pages'},
          fallback: '$pages pages',
        ),
      if (availability.isNotEmpty) availability,
    ];
    if (bits.isEmpty) return const SizedBox.shrink();
    return Text(
      bits.join(' • '),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: FhcColors.ink,
        height: 1.2,
      ),
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
  const _ActionBar({
    required this.onRead,
    required this.onDownload,
    required this.downloading,
  });

  final VoidCallback onRead;
  final VoidCallback? onDownload;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: FhcPrimaryButton(
              label: fhcT(context, 'nav.pressReadNow', fallback: 'Read Now'),
              color: FhcColors.press,
              onPressed: onRead,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: FhcSizes.buttonHeight,
              child: OutlinedButton(
                onPressed: onDownload,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FhcColors.press,
                  side: const BorderSide(color: FhcColors.press),
                  minimumSize: const Size(0, FhcSizes.buttonHeight),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FhcRadius.button),
                  ),
                ),
                child: Text(
                  downloading
                      ? fhcT(context, 'nav.pressChecking', fallback: 'Checking…')
                      : fhcT(context, 'nav.pressDownload', fallback: 'Download'),
                  style: const TextStyle(
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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../data/livestream_repository.dart';

class LiveFellowshipScreen extends StatefulWidget {
  const LiveFellowshipScreen({super.key, this.repository});

  final LivestreamSource? repository;

  @override
  State<LiveFellowshipScreen> createState() => _LiveFellowshipScreenState();
}

class _LiveFellowshipScreenState extends State<LiveFellowshipScreen> {
  late final LivestreamSource _repo =
      widget.repository ?? LivestreamRepository();

  bool _loading = true;
  String? _error;
  JsonObject? _stream;
  List<JsonObject> _comments = const [];
  final _composer = TextEditingController();
  final _chatScroll = ScrollController();
  Timer? _poll;
  WebViewController? _web;
  bool _sending = false;
  bool _reacting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _composer.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  bool get _embedInWebView {
    if (kIsWeb) return false;
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return !binding.contains('TestWidgetsFlutterBinding');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.getCurrent();
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() {
          _stream = value;
          _loading = false;
        });
        _configurePlayer(value);
        if (value != null) {
          await _refreshComments();
          _poll?.cancel();
          _poll = Timer.periodic(const Duration(seconds: 4), (_) {
            _refreshComments(silent: true);
          });
        }
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _configurePlayer(JsonObject? stream) {
    if (!_embedInWebView) {
      _web = null;
      return;
    }
    final videoId = _videoIdOf(stream);
    if (videoId == null) {
      _web = null;
      return;
    }
    final src =
        'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1&playsinline=1&enablejsapi=1';
    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
  html, body { margin: 0; padding: 0; background: #001823; height: 100%; overflow: hidden; }
  iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe
  src="$src"
  title="Live service"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  allowfullscreen
  referrerpolicy="strict-origin-when-cross-origin"></iframe>
</body>
</html>
''';
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(FhcColors.midnight)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('https://www.youtube.com') ||
                url.startsWith('https://www.youtube-nocookie.com') ||
                url.startsWith('https://www.google.com') ||
                url.startsWith('about:blank') ||
                url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: 'https://www.youtube.com');
    _web = controller;
  }

  static String? _videoIdOf(JsonObject? stream) {
    final external = (stream?['external_id'] as String?)?.trim();
    if (external != null &&
        RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(external)) {
      return external;
    }
    final embed = (stream?['embed_url'] as String?)?.trim() ?? '';
    final match = RegExp(r'/embed/([A-Za-z0-9_-]{11})').firstMatch(embed);
    return match?.group(1);
  }

  Future<void> _refreshComments({bool silent = false}) async {
    final id = (_stream?['id'] as String?)?.trim();
    if (id == null || id.isEmpty) return;
    final result = await _repo.listComments(id);
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        setState(() => _comments = value);
      case AppError(:final failure) when !silent:
        if (failure is! UnauthorizedFailure &&
            failure is! IntegrationUnavailableFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      case AppError():
        break;
    }
  }

  Future<void> _send() async {
    final id = (_stream?['id'] as String?)?.trim();
    final body = _composer.text.trim();
    if (id == null || body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await _repo.postComment(id, body);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case AppSuccess(:final value):
        _composer.clear();
        setState(() => _comments = [..._comments, value]);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_chatScroll.hasClients) return;
          _chatScroll.animateTo(
            _chatScroll.position.maxScrollExtent,
            duration: FhcMotion.standard,
            curve: Curves.easeOut,
          );
        });
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  Future<void> _react() async {
    final id = (_stream?['id'] as String?)?.trim();
    if (id == null || _reacting) return;
    setState(() => _reacting = true);
    final result = await _repo.react(id);
    if (!mounted) return;
    setState(() => _reacting = false);
    if (result case AppSuccess(:final value)) {
      setState(() {
        _stream = {
          ...?_stream,
          'reaction_count':
              value['reaction_count'] ?? _stream?['reaction_count'],
        };
      });
    }
  }

  Future<void> _openExternal() async {
    final url = (_stream?['watch_url'] as String?)?.trim();
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareService() async {
    final title = (_stream?['title'] as String?)?.trim() ?? 'Live service';
    final url = (_stream?['watch_url'] as String?)?.trim() ?? '';
    final text = url.isEmpty ? title : '$title\n$url';
    await fhcShareText(
      context,
      text: text,
      confirmation: fhcT(
        context,
        'online.linkCopied',
        fallback: 'Service link copied.',
      ),
    );
  }

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
      backgroundColor: FhcColors.white,
      darkStatusBar: true,
      statusBarColor: FhcColors.midnight,
      child: Column(
        children: [
          _LiveHeader(onBack: _goBack, onOpenYoutube: _openExternal),
          SizedBox(height: 220, child: _stage()),
          _streamMeta(),
          Expanded(child: _chat()),
          _composerBar(),
          _ActionBar(
            onGive: () => fhcPush(context, FhcRoutes.give),
            onPrayer: () => fhcPush(context, FhcRoutes.prayer),
            onShare: _shareService,
          ),
        ],
      ),
    );
  }

  Widget _stage() {
    if (_loading) {
      return const ColoredBox(
        color: FhcColors.midnight,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: FhcColors.midnight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    final stream = _stream;
    if (stream == null) {
      return ColoredBox(
        color: FhcColors.midnight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              fhcT(
                context,
                'online.noLiveNow',
                fallback:
                    'No live service is on air right now. Check sermons for recent messages.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
    }

    final status = '${stream['status'] ?? ''}'.toLowerCase();
    final thumb = (stream['thumbnail_url'] as String?)?.trim() ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_web != null)
          WebViewWidget(controller: _web!)
        else if (thumb.isNotEmpty)
          Image.network(
            thumb,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: FhcColors.midnight),
          )
        else
          const ColoredBox(color: FhcColors.midnight),
        if (_web == null)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.35),
            child: Center(
              child: FilledButton(
                onPressed: _openExternal,
                style: FilledButton.styleFrom(
                  backgroundColor: FhcColors.green,
                  foregroundColor: FhcColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FhcRadius.sm),
                  ),
                ),
                child: Text(
                  fhcT(
                    context,
                    'online.watchOnYoutube',
                    fallback: 'Watch on YouTube',
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'live' ? FhcColors.red : Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status == 'live'
                  ? 'LIVE'
                  : (status.isEmpty ? 'OFF AIR' : status.toUpperCase()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _streamMeta() {
    final stream = _stream;
    if (stream == null || _loading || _error != null) {
      return const SizedBox.shrink();
    }
    final title = (stream['title'] as String?)?.trim() ?? 'Live service';
    final church = (stream['church_name'] as String?)?.trim() ??
        (stream['subtitle'] as String?)?.trim() ??
        '';
    final host = (stream['host_name'] as String?)?.trim() ?? '';
    final reactions = stream['reaction_count'] ?? 0;
    final subtitle = [
      if (church.isNotEmpty) church,
      if (host.isNotEmpty) host,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(bottom: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: FhcColors.ink,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: FhcColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _reacting ? null : _react,
            style: OutlinedButton.styleFrom(
              foregroundColor: FhcColors.ink,
              side: const BorderSide(color: FhcColors.border),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FhcRadius.sm),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thumb_up_outlined, size: 14),
                const SizedBox(width: 6),
                Text(
                  fhcT(context, 'online.like', fallback: 'Like'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (reactions is num && reactions > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$reactions',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            fhcT(context, 'online.comments', fallback: 'Comments'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Text(
                    fhcT(
                      context,
                      'online.noCommentsYet',
                      fallback: 'No comments yet.',
                    ),
                    style: const TextStyle(color: FhcColors.muted, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  controller: _chatScroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = _comments[index];
                    final name = (item['person_name'] as String?) ?? 'Member';
                    final body = (item['body'] as String?) ?? '';
                    final at = (item['created_at'] as String?) ?? '';
                    final initial = name.trim().isEmpty
                        ? '?'
                        : name.trim().characters.first.toUpperCase();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: FhcColors.mint,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 12,
                              color: FhcColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _timeLabel(at),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: FhcColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: FhcColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _composerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(top: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composer,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: FhcTypography.body,
              decoration: InputDecoration(
                hintText: fhcT(
                  context,
                  'online.writeComment',
                  fallback: 'Write a comment',
                ),
                hintStyle: FhcTypography.hint,
                filled: true,
                fillColor: FhcColors.canvas,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.field),
                  borderSide: const BorderSide(color: FhcColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.field),
                  borderSide: const BorderSide(color: FhcColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.field),
                  borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: FhcColors.green,
                foregroundColor: FhcColors.white,
                minimumSize: const Size(72, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FhcRadius.button),
                ),
              ),
              child: Text(
                _sending
                    ? fhcT(context, 'common.sending', fallback: 'Sending')
                    : fhcT(context, 'common.send', fallback: 'Send'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(String iso) {
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '';
    final h = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final m = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.onBack, required this.onOpenYoutube});

  final VoidCallback onBack;
  final VoidCallback onOpenYoutube;

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
              icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
              tooltip: fhcT(context, 'common.back', fallback: 'Back'),
            ),
          ),
          Expanded(
            child: Text(
              fhcT(context, 'online.liveService', fallback: 'Live service'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: FhcSizes.minTap,
            child: IconButton(
              onPressed: onOpenYoutube,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.open_in_new, size: 20, color: Colors.white),
              tooltip: fhcT(
                context,
                'online.watchOnYoutube',
                fallback: 'Watch on YouTube',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onShare,
    required this.onGive,
    required this.onPrayer,
  });

  final VoidCallback onShare;
  final VoidCallback onGive;
  final VoidCallback onPrayer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: const BoxDecoration(
          color: FhcColors.white,
          border: Border(top: BorderSide(color: FhcColors.border)),
        ),
        child: Row(
          children: [
            _Action(
              icon: Icons.ios_share_outlined,
              label: fhcT(context, 'common.share', fallback: 'Share'),
              onTap: onShare,
            ),
            _Action(
              icon: Icons.volunteer_activism_outlined,
              label: fhcT(context, 'nav.give', fallback: 'Give'),
              onTap: onGive,
            ),
            _Action(
              icon: Icons.menu_book_outlined,
              label: fhcT(context, 'nav.prayer', fallback: 'Prayer'),
              onTap: onPrayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: FhcColors.ink),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FhcColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

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

  final LivestreamRepository? repository;

  @override
  State<LiveFellowshipScreen> createState() => _LiveFellowshipScreenState();
}

class _LiveFellowshipScreenState extends State<LiveFellowshipScreen> {
  late final LivestreamRepository _repo =
      widget.repository ?? LivestreamRepository();

  bool _loading = true;
  String? _error;
  JsonObject? _stream;
  List<JsonObject> _comments = const [];
  final _composer = TextEditingController();
  Timer? _poll;
  WebViewController? _web;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _composer.dispose();
    super.dispose();
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
    final embed = (stream?['embed_url'] as String?)?.trim();
    if (embed == null || embed.isEmpty) {
      _web = null;
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B1220))
      ..loadRequest(Uri.parse(embed));
    _web = controller;
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
        // Chat may require sign-in; keep player usable.
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
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  Future<void> _react() async {
    final id = (_stream?['id'] as String?)?.trim();
    if (id == null) return;
    final result = await _repo.react(id);
    if (!mounted) return;
    if (result case AppSuccess(:final value)) {
      setState(() {
        _stream = {
          ...?_stream,
          'reaction_count': value['reaction_count'] ?? _stream?['reaction_count'],
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

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      darkStatusBar: true,
      statusBarColor: FhcColors.midnight,
      child: Column(
        children: [
          SizedBox(height: 280, child: _stage()),
          Expanded(child: _chat()),
          _composerBar(),
          _ActionBar(
            onGive: () => fhcPush(context, FhcRoutes.give),
            onPrayer: () => fhcPush(context, FhcRoutes.prayer),
            onShare: _openExternal,
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
    final title = (stream['title'] as String?) ?? 'Live';
    final church = (stream['church_name'] as String?) ??
        (stream['subtitle'] as String?) ??
        '';
    final host = (stream['host_name'] as String?) ?? '';
    final viewers = stream['viewer_count'] ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_web != null)
          WebViewWidget(controller: _web!)
        else
          ColoredBox(
            color: FhcColors.midnight,
            child: Center(
              child: FilledButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  fhcT(context, 'online.watchOnYoutube', fallback: 'Watch on YouTube'),
                ),
              ),
            ),
          ),
        Positioned(
          left: 12,
          top: 12,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'live' ? FhcColors.red : Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == 'live' ? 'LIVE' : status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$viewers',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                church.isEmpty ? title : church,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                host.isEmpty ? title : '$title · $host',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
          child: Text(
            fhcT(context, 'online.liveChat', fallback: 'Live Chat'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Text(
                    fhcT(
                      context,
                      'online.beFirstToChat',
                      fallback: 'Be the first to share a word of faith.',
                    ),
                    style: const TextStyle(color: FhcColors.muted, fontSize: 12),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = _comments[index];
                    final name = (item['person_name'] as String?) ?? 'Member';
                    final body = (item['body'] as String?) ?? '';
                    final at = (item['created_at'] as String?) ?? '';
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: FhcColors.mint,
                          child: Text(
                            name.isEmpty ? '?' : name.characters.first,
                            style: const TextStyle(
                              fontSize: 11,
                              color: FhcColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _timeLabel(at),
                          style: const TextStyle(
                            fontSize: 9,
                            color: FhcColors.muted,
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
    final reactions = _stream?['reaction_count'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 12, 9),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _composer,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: fhcT(
                    context,
                    'online.typeMessage',
                    fallback: 'Type a message...',
                  ),
                  filled: true,
                  fillColor: FhcColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send, color: FhcColors.green),
          ),
          IconButton(
            onPressed: _react,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: FhcColors.red, size: 20),
                const SizedBox(width: 4),
                Text('$reactions', style: const TextStyle(fontSize: 11)),
              ],
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Action(icon: Icons.ios_share, label: 'Share', onTap: onShare),
            _Action(icon: Icons.favorite_border, label: 'Give', onTap: onGive),
            _Action(
              icon: Icons.volunteer_activism_outlined,
              label: 'Prayer',
              onTap: onPrayer,
            ),
            _Action(
              icon: Icons.more_horiz,
              label: 'More',
              onTap: () => fhcPush(context, FhcRoutes.media),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: FhcColors.ink),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

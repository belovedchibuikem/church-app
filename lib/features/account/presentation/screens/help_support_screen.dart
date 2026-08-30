import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../content/data/content_repository.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Help & Support loaded from published CMS FAQ (`GET /content/pages/faq`)
/// plus practical contact actions (messages, contact page).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, this.contentRepository});

  final ContentRepository? contentRepository;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  ContentRepository? _content;
  bool _loading = true;
  String? _error;
  String _title = 'Help & Support';
  String? _summary;
  List<_FaqItem> _faqs = const [];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _content ??=
        widget.contentRepository ??
        AppServicesScope.maybeOf(context)?.contentRepository;
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final content = _content;
    if (content == null) {
      setState(() {
        _loading = false;
        _error =
            'Help content requires the public content catalogue.';
        _faqs = _fallbackFaqs(context);
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await content.getContentPage('faq');
    if (!mounted) return;
    switch (result) {
      case AppSuccess(:final value):
        final items = value['items'];
        final faqs = <_FaqItem>[];
        if (items is List) {
          for (final raw in items) {
            if (raw is! Map) continue;
            final kind = '${raw['kind'] ?? ''}'.toLowerCase();
            if (kind.isNotEmpty && kind != 'faq') continue;
            final q =
                (raw['title'] as String?)?.trim() ??
                (raw['q'] as String?)?.trim();
            final a =
                (raw['body'] as String?)?.trim() ??
                (raw['a'] as String?)?.trim();
            if (q == null || q.isEmpty || a == null || a.isEmpty) continue;
            faqs.add(_FaqItem(question: q, answer: a));
          }
        }
        setState(() {
          _title =
              (value['title'] as String?)?.trim().isNotEmpty == true
                  ? (value['title'] as String).trim()
                  : fhcT(context, 'settings.help', fallback: 'Help & Support');
          _summary = (value['summary'] as String?)?.trim();
          _faqs = faqs.isEmpty ? _fallbackFaqs(context) : faqs;
          _loading = false;
        });
      case AppError(:final failure):
        setState(() {
          _error = failure.message;
          _faqs = _fallbackFaqs(context);
          _loading = false;
        });
    }
  }

  List<_FaqItem> _fallbackFaqs(BuildContext context) => [
    _FaqItem(
      question: fhcT(
        context,
        'help.whatIsFhc',
        fallback: 'What is Family House Connect?',
      ),
      answer: fhcT(
        context,
        'help.whatIsFhcAnswer',
        fallback:
            'Family House Connect unites churches, missions, Kingdom training, and resources so every believer can find community, grow, and serve.',
      ),
    ),
    _FaqItem(
      question: fhcT(
        context,
        'help.howToGive',
        fallback: 'How can I give securely?',
      ),
      answer: fhcT(
        context,
        'help.howToGiveAnswer',
        fallback:
            'Open Give to choose an amount and fund. Payments use your church’s activated provider. Receipts appear in your account after sign-in.',
      ),
    ),
  ];

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'help.unableToOpenLink',
              fallback: 'Unable to open that link right now.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: fhcT(context, 'settings.help', fallback: 'Help & Support'),
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                fhcGo(context, FhcRoutes.settings);
              }
            },
          ),
          Expanded(child: _body()),
          const FhcBottomNavigation(selected: 4),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _summary?.isNotEmpty == true
                    ? _summary!
                    : fhcT(
                      context,
                      'help.intro',
                      fallback:
                          'Find answers from our published FAQ, message your church, or reach Family House support.',
                    ),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: FhcColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          FhcSurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: FhcColors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fhcT(
                      context,
                      'help.showingCachedFaq',
                      fallback:
                          'Live FAQ could not be refreshed. Showing helpful defaults.',
                    ),
                    style: const TextStyle(fontSize: 12, color: FhcColors.muted),
                  ),
                ),
                TextButton(onPressed: _load, child: Text(fhcT(context, 'common.retry', fallback: 'Retry'))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          fhcT(context, 'help.getHelp', fallback: 'Get help'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        FhcSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.chat_bubble_outline,
                title: fhcT(context, 'help.messages', fallback: 'Messages'),
                subtitle: fhcT(
                  context,
                  'help.messagesCopy',
                  fallback: 'Open your in-app conversations',
                ),
                onTap: () => fhcPush(context, FhcRoutes.messages),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.mail_outline,
                title: fhcT(context, 'help.contactUs', fallback: 'Contact us'),
                subtitle: fhcT(
                  context,
                  'help.contactUsCopy',
                  fallback: 'Visit the Family House contact page',
                ),
                onTap: () => _openExternal(
                  'https://familyconnect.katakarra.com/contact',
                ),
              ),
              const Divider(height: 1),
              _ActionRow(
                icon: Icons.lock_outline,
                title: fhcT(
                  context,
                  'settings.privacySecurity',
                  fallback: 'Privacy & Security',
                ),
                subtitle: fhcT(
                  context,
                  'help.privacyCopy',
                  fallback: 'Sessions, consents, and data requests',
                ),
                onTap: () => fhcPush(context, '/settings/privacy'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          fhcT(context, 'help.faq', fallback: 'Frequently asked questions'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FhcColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        FhcSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < _faqs.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    title: Text(
                      _faqs[i].question,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FhcColors.ink,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _faqs[i].answer,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: FhcColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FhcSurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fhcT(context, 'settings.about', fallback: 'About Family House Connect'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fhcT(
                  context,
                  'settings.version',
                  args: {'version': '1.0.0'},
                  fallback: 'Version 1.0.0',
                ),
                style: const TextStyle(fontSize: 12, color: FhcColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                fhcT(
                  context,
                  'help.aboutCopy',
                  fallback:
                      'Member experience for churches, mission, giving, and Kingdom training — connected to your Family House account.',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: FhcColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: FhcColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: FhcColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: FhcColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FhcColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

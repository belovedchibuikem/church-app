import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/contracts/mobile_repository_contracts.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

/// Member mentor assignment + optional messaging via [MessageRepository].
class MentorChatScreen extends StatefulWidget {
  const MentorChatScreen({
    super.key,
    this.kcaRepository,
    this.messageRepository,
  });

  final KcaRepository? kcaRepository;
  final MessageRepository? messageRepository;

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  FhcAsyncValue<_MentorInfo> _state = const FhcAsyncValue.loading();
  final _compose = TextEditingController();
  String? _conversationId;
  bool _sending = false;

  KcaRepository? get _repo =>
      widget.kcaRepository ??
      AppServicesScope.maybeOf(context)?.kcaRepository;

  MessageRepository? get _messages =>
      widget.messageRepository ??
      AppServicesScope.maybeOf(context)?.messageRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_state is FhcAsyncLoading) {
      _load();
    }
  }

  @override
  void dispose() {
    _compose.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _state = FhcAsyncValue.unavailable(
          message: fhcT(
            context,
            'member.kca.mentorRequireApi',
            fallback:
                'KCA mentor requires the member curriculum API. '
                'No design fixtures are shown.',
          ),
        );
      });
      return;
    }

    setState(() => _state = const FhcAsyncValue.loading());
    final result = await repo.getMentor();
    if (!mounted) return;

    switch (result) {
      case AppSuccess(:final value):
        final info = _MentorInfo.fromJson(value);
        if (!info.assigned) {
          setState(() {
            _state = FhcAsyncValue.empty(
              message:
                  info.message ??
                  fhcT(
                    context,
                    'member.kca.noMentorAssignedCopy',
                    fallback:
                        'No mentor is currently assigned to your enrollment.',
                  ),
            );
          });
          return;
        }
        setState(() => _state = FhcAsyncValue.data(info));
      case AppError(:final failure):
        setState(() => _state = FhcAsyncValue.error(failure));
    }
  }

  Future<void> _ensureConversation(_MentorInfo mentor) async {
    if (_conversationId != null) return;
    final messages = _messages;
    final personId = mentor.personId;
    if (messages == null || personId == null || personId.isEmpty) return;

    final created = await messages.createConversation({
      'participant_person_ids': [personId],
      'subject': 'KCA Mentor',
    });
    if (created case AppSuccess(:final value)) {
      _conversationId = '${value['id'] ?? ''}'.trim();
      if (_conversationId!.isEmpty) _conversationId = null;
    }
  }

  Future<void> _send(_MentorInfo mentor) async {
    final text = _compose.text.trim();
    if (text.isEmpty || _sending) return;
    final messages = _messages;
    if (messages == null ||
        mentor.personId == null ||
        mentor.personId!.isEmpty) {
      await fhcApiUnavailable(
        context,
        action: fhcT(
          context,
          'member.kca.sendingMentorMessage',
          fallback: 'Sending a mentor message',
        ),
      );
      return;
    }

    setState(() => _sending = true);
    await _ensureConversation(mentor);
    final conversationId = _conversationId;
    if (conversationId == null || conversationId.isEmpty) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fhcT(
              context,
              'member.kca.mentorConversationFailed',
              fallback: 'Could not open a mentor conversation.',
            ),
          ),
        ),
      );
      return;
    }

    final result = await messages.send(conversationId, {
      'body': text,
    });
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case AppSuccess():
        _compose.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fhcT(context, 'member.kca.messageSent', fallback: 'Message sent'),
            ),
          ),
        );
      case AppError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.kca);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          _MentorHeader(onBack: _back, state: _state),
          Expanded(
            child: FhcAsyncBody<_MentorInfo>(
              value: _state,
              onRetry: _load,
              emptyTitle: fhcT(
                context,
                'member.kca.noMentorAssigned',
                fallback: 'No mentor assigned',
              ),
              unavailableTitle: fhcT(
                context,
                'member.kca.mentorUnavailable',
                fallback: 'Mentor unavailable',
              ),
              builder: (context, mentor) {
                final canMessage =
                    mentor.personId != null &&
                    mentor.personId!.isNotEmpty &&
                    _messages != null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    FhcSurfaceCard(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentor.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: FhcColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mentor.startsAt == null
                                ? fhcT(
                                  context,
                                  'member.kca.assignedMentorEnrollment',
                                  fallback:
                                      'Assigned mentor for your enrollment',
                                )
                                : fhcT(
                                  context,
                                  'member.kca.assignedSince',
                                  args: {'date': mentor.startsAt!},
                                  fallback: 'Assigned since {date}',
                                ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: FhcColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!canMessage) ...[
                      const SizedBox(height: 14),
                      FhcUnavailableState(
                        title: fhcT(
                          context,
                          'member.kca.mentorChatUnavailable',
                          fallback: 'Mentor chat unavailable',
                        ),
                        message: fhcT(
                          context,
                          'member.kca.mentorChatNeedPersonId',
                          fallback:
                              'Messaging needs a mentor person_id from the API '
                              'and a bound message repository.',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (_state case FhcAsyncData(:final value))
            _Composer(
              controller: _compose,
              sending: _sending,
              enabled: value.personId != null &&
                  value.personId!.isNotEmpty &&
                  _messages != null,
              onSend: () => _send(value),
            ),
          FhcBottomNavigation(
            selected: 3,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _MentorInfo {
  const _MentorInfo({
    required this.assigned,
    required this.displayName,
    this.startsAt,
    this.message,
    this.personId,
  });

  factory _MentorInfo.fromJson(Map<String, Object?> json) {
    final assigned = json['assigned'] == true;
    final mentor = json['mentor'];
    String name = 'Mentor';
    String? startsAt;
    String? personId;
    if (mentor is Map) {
      final given =
          '${mentor['preferred_name'] ?? mentor['given_name'] ?? 'Mentor'}';
      final family = '${mentor['family_name'] ?? ''}'.trim();
      name = family.isEmpty ? given.trim() : '$given $family'.trim();
      final start = mentor['starts_at'];
      if (start != null) startsAt = '$start';
      final rawId =
          '${mentor['person_id'] ?? mentor['id'] ?? json['person_id'] ?? ''}'
              .trim();
      personId = rawId.isEmpty ? null : rawId;
    } else {
      final rawId = '${json['person_id'] ?? ''}'.trim();
      personId = rawId.isEmpty ? null : rawId;
    }
    return _MentorInfo(
      assigned: assigned,
      displayName: name.isEmpty ? 'Mentor' : name,
      startsAt: startsAt,
      message: json['message'] is String ? json['message'] as String : null,
      personId: personId,
    );
  }

  final bool assigned;
  final String displayName;
  final String? startsAt;
  final String? message;
  final String? personId;
}

class _MentorHeader extends StatelessWidget {
  const _MentorHeader({required this.onBack, required this.state});

  final VoidCallback onBack;
  final FhcAsyncValue<_MentorInfo> state;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      FhcAsyncData(:final value) => value.displayName,
      _ => fhcT(context, 'member.kca.mentor', fallback: 'Mentor'),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(bottom: BorderSide(color: FhcColors.border)),
      ),
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
          const CircleAvatar(
            radius: 18,
            backgroundColor: FhcColors.border,
            child: Icon(Icons.person_outline, color: FhcColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  switch (state) {
                    FhcAsyncData() => fhcT(
                      context,
                      'member.kca.assigned',
                      fallback: 'Assigned',
                    ),
                    FhcAsyncLoading() => fhcT(
                      context,
                      'common.loading',
                      fallback: 'Loading…',
                    ),
                    _ => fhcT(
                      context,
                      'member.kca.notAssigned',
                      fallback: 'Not assigned',
                    ),
                  },
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: switch (state) {
                      FhcAsyncData() => FhcColors.green,
                      _ => FhcColors.muted,
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.sending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FhcColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled && !sending,
                  textInputAction: TextInputAction.send,
                  onSubmitted: enabled ? (_) => onSend() : null,
                  decoration: InputDecoration(
                    hintText: fhcT(
                      context,
                      'member.kca.messageYourMentor',
                      fallback: 'Message your mentor…',
                    ),
                    filled: true,
                    fillColor: FhcColors.canvas,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: FhcColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: FhcColors.border),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled && !sending ? onSend : null,
                icon: Icon(
                  Icons.send_outlined,
                  color: enabled ? FhcColors.green : FhcColors.muted,
                ),
                tooltip: fhcT(context, 'member.kca.send', fallback: 'Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

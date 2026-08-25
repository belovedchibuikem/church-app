import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class MentorChatScreen extends StatelessWidget {
  const MentorChatScreen({super.key});

  static const _messages = <_ChatMessage>[
    _ChatMessage(
      fromMentor: true,
      text: 'Good morning Chibuikem! How are you progressing in Module 8?',
      time: '10:30 AM',
    ),
    _ChatMessage(
      fromMentor: false,
      text:
          'Good morning Pastor! I have watched the video and started my assignment.',
      time: '10:32 AM',
    ),
    _ChatMessage(
      fromMentor: true,
      text: 'Great! Remember to focus on the practical part.',
      time: '10:33 AM',
    ),
    _ChatMessage(
      fromMentor: false,
      text: 'Yes sir, I will submit it before the deadline.',
      time: '10:34 AM',
    ),
    _ChatMessage(
      fromMentor: true,
      text: 'Blessings!',
      time: '10:35 AM',
    ),
  ];

  void _back(BuildContext context) {
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
          _MentorHeader(onBack: () => _back(context)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Bubble(message: _messages[index]),
                );
              },
            ),
          ),
          const _Composer(),
          FhcBottomNavigation(
            selected: 3,
            onSelected: (index) => fhcTab(context, index),
          ),
        ],
      ),
    );
  }
}

class _MentorHeader extends StatelessWidget {
  const _MentorHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
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
              tooltip: 'Back',
            ),
          ),
          const _MentorPhoto(size: 36),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pastor John (Mentor)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Online',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FhcColors.green,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Voice call',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: FhcSizes.minTap,
              minHeight: FhcSizes.minTap,
            ),
            icon: const Icon(
              Icons.call_outlined,
              size: 22,
              color: FhcColors.green,
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Video call',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: FhcSizes.minTap,
              minHeight: FhcSizes.minTap,
            ),
            icon: const Icon(
              Icons.videocam_outlined,
              size: 24,
              color: FhcColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorPhoto extends StatelessWidget {
  const _MentorPhoto({this.size = 36});

  final double size;

  static const _assets = <String>[
    'assets/images/pastor_john_avatar.png',
    'assets/images/mentor_john.png',
    'assets/images/mentor_avatar.png',
  ];

  Widget _leaf() {
    return ColoredBox(
      color: FhcColors.mint,
      child: Icon(Icons.person, color: FhcColors.green, size: size * 0.58),
    );
  }

  Widget _chain(List<String> paths) {
    if (paths.isEmpty) return _leaf();
    return Image.asset(
      paths.first,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _chain(paths.skip(1).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(width: size, height: size, child: _chain(_assets)),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.fromMentor,
    required this.text,
    required this.time,
  });

  final bool fromMentor;
  final String text;
  final String time;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromMentor = message.fromMentor;
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              fromMentor ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: fromMentor ? FhcColors.white : FhcColors.green,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(fromMentor ? 4 : 14),
                bottomRight: Radius.circular(fromMentor ? 14 : 4),
              ),
              border: fromMentor ? Border.all(color: FhcColors.border) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: fromMentor ? FhcColors.ink : FhcColors.white,
                    ),
                  ),
                ),
                if (!fromMentor) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          color: FhcColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: FhcColors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (fromMentor) ...[
            const SizedBox(height: 4),
            Text(
              message.time,
              style: const TextStyle(
                fontSize: 10,
                color: FhcColors.hint,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );

    if (!fromMentor) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _MentorPhoto(size: 24),
        ),
        const SizedBox(width: 8),
        Flexible(child: Align(alignment: Alignment.centerLeft, child: bubble)),
        const SizedBox(width: 32),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(22));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(top: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: FhcColors.white,
                borderRadius: radius,
                border: Border.all(color: FhcColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      style: FhcTypography.body,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: FhcTypography.hint,
                        isDense: true,
                        contentPadding: EdgeInsets.fromLTRB(14, 10, 8, 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Emoji',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      size: 20,
                      color: FhcColors.muted,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Attach',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.attach_file,
                      size: 20,
                      color: FhcColors.muted,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Send',
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: FhcColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: FhcColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

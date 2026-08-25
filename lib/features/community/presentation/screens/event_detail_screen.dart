import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});

  static void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.events);
    }
  }

  static void _register(BuildContext context) {
    fhcPush(context, FhcRoutes.give);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'EVENT DETAILS',
            onBack: () => _goBack(context),
            trailing: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share_outlined, size: 22),
              color: FhcColors.ink,
              tooltip: 'Share',
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _EventHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Annual Convention 2025',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: FhcColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _UpcomingBadge(),
                      const SizedBox(height: 14),
                      const _InfoLine(
                        icon: Icons.calendar_today_outlined,
                        text: 'May 24 – 26, 2025',
                      ),
                      const SizedBox(height: 10),
                      const _InfoLine(
                        icon: Icons.schedule_outlined,
                        text: '9:00 AM',
                      ),
                      const SizedBox(height: 10),
                      const _InfoLine(
                        icon: Icons.place_outlined,
                        text: 'National Stadium, Lagos',
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'About This Event',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FhcColors.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Three days of worship, teaching, and ministry. Come expecting a move of God!',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: FhcColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _RegistrationProgress(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FhcPrimaryButton(
              label: 'Register Now',
              onPressed: () => _register(context),
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _HeroPhoto(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xB3000000)],
              ),
            ),
          ),
          const Positioned(left: 12, top: 12, child: _UpcomingBadge()),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ANNUAL CONVENTION 2025',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FhcColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ONE HOUSE, MANY NATIONS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FhcColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    height: 1.2,
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

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  static const _fallback = ColoredBox(
    color: FhcColors.greenDeep,
    child: Center(child: Icon(Icons.event, size: 56, color: FhcColors.white)),
  );

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/event_convention.png',
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/convention_2025.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/press_new_release_banner.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => _fallback,
            );
          },
        );
      },
    );
  }
}

class _UpcomingBadge extends StatelessWidget {
  const _UpcomingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FhcColors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Upcoming',
        maxLines: 1,
        style: TextStyle(
          color: FhcColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FhcColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegistrationProgress extends StatelessWidget {
  const _RegistrationProgress();

  static const _registered = 2500;
  static const _capacity = 5000;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people_outline, size: 16, color: FhcColors.ink),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                '2.5K Registered',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(
            value: _registered / _capacity,
            minHeight: 8,
            backgroundColor: FhcColors.border,
            valueColor: AlwaysStoppedAnimation(FhcColors.green),
          ),
        ),
        const SizedBox(height: 6),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            '2,500 / 5,000',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: FhcColors.muted, height: 1.2),
          ),
        ),
      ],
    );
  }
}

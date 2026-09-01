import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../fhc_nav.dart';

enum KingdomJourneyKind {
  overview,
  discover,
  joinChurch,
  member,
  grow,
  serve,
  winSouls,
  becomeKca,
  homeChurch,
  multiply,
}

class KingdomJourneyScreen extends StatelessWidget {
  const KingdomJourneyScreen({super.key, required this.kind});
  final KingdomJourneyKind kind;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(kind);
    return WorkflowPage(
      title: 'Kingdom Multiplication Cycle',
      domain: WorkflowDomain.journey,
      showBack: kind != KingdomJourneyKind.overview,
      actionLabel: spec.action,
      onAction: spec.next == null ? null : () => fhcPush(context, spec.next!),
      children: [
        _cycle(spec.stage),
        _heading(spec.title, spec.subtitle),
        ..._content(kind),
      ],
    );
  }

  _JourneySpec _spec(KingdomJourneyKind value) => switch (value) {
    KingdomJourneyKind.overview => const _JourneySpec(
      'Shalom, Glory Samuel',
      'You are on a divine assignment!',
      1,
      'Continue Journey',
      '/journey/discover',
    ),
    KingdomJourneyKind.discover => const _JourneySpec(
      'Discover Family House',
      'Explore the Family House vision and community.',
      1,
      'Join a Church',
      '/journey/join-church',
    ),
    KingdomJourneyKind.joinChurch => const _JourneySpec(
      'Join Church',
      'Connect with a church family physically, at home, or online.',
      2,
      'Join This Church',
      '/journey/member',
    ),
    KingdomJourneyKind.member => const _JourneySpec(
      'Become a Member',
      'Complete your profile and become an active member.',
      2,
      'Continue',
      '/journey/grow',
    ),
    KingdomJourneyKind.grow => const _JourneySpec(
      'Grow Spiritually',
      'Build your relationship with God and grow in character.',
      4,
      null,
      null,
    ),
    KingdomJourneyKind.serve => const _JourneySpec(
      'Serve',
      'Use your gifts to build the church and advance God’s Kingdom.',
      6,
      null,
      null,
    ),
    KingdomJourneyKind.winSouls => const _JourneySpec(
      'Win Souls & Disciple',
      'Reach the lost and help new believers grow in Christ.',
      8,
      null,
      null,
    ),
    KingdomJourneyKind.becomeKca => const _JourneySpec(
      'Become KCA / Become Mentor',
      'Be equipped, empowered and raise others.',
      10,
      'View KCA Progress',
      '/kca/certification',
    ),
    KingdomJourneyKind.homeChurch => const _JourneySpec(
      'Start & Develop Home Church',
      'Start a home church, shepherd souls and develop community.',
      12,
      'Open Home Church',
      '/home-church',
    ),
    KingdomJourneyKind.multiply => const _JourneySpec(
      'Multiply!',
      'A multiplied disciple-making movement.',
      14,
      null,
      null,
    ),
  };

  List<Widget> _content(KingdomJourneyKind value) => switch (value) {
    KingdomJourneyKind.overview => [
      const WorkflowSummary(
        title: 'Current Stage',
        subtitle: 'Discover Family House',
        metrics: [
          ('7%', 'Overall Progress'),
          ('1', 'Milestone'),
          ('14', 'Total'),
        ],
      ),
      const WorkflowSectionTitle('Next Milestone'),
      _rows(const [
        (
          'Join Church',
          'Connect with a church family near you or join online.',
        ),
      ]),
      const WorkflowSectionTitle('My Kingdom Impact'),
      const WorkflowSummary(
        title: 'Your impact so far',
        metrics: [
          ('12', 'Prayer Days'),
          ('3', 'Discipled'),
          ('18', 'Service Hrs'),
          ('5', 'Souls Won'),
        ],
      ),
    ],
    KingdomJourneyKind.discover => [
      const WorkflowSummary(
        title: 'Milestone Unlocked',
        subtitle: 'You have discovered Family House!',
        metrics: [],
      ),
      const WorkflowSectionTitle('Explore Family House'),
      _tiles(const [
        ('Find Local Churches', Icons.location_on_outlined),
        ('Home Churches', Icons.home_work_outlined),
        ('Online Church', Icons.live_tv_outlined),
      ]),
      const WorkflowSectionTitle('Nearby Locations'),
      _rows(const [
        ('Family House Church, Ikeja', '2.4 km'),
        ('Family House Church, Yaba', '4.1 km'),
        ('Family House Church, Lekki', '8.7 km'),
      ]),
    ],
    KingdomJourneyKind.joinChurch => [
      const WorkflowSegments(
        labels: ['Physical Church', 'Home Church', 'Online Church'],
      ),
      const SizedBox(height: 12),
      const WorkflowSummary(
        title: 'Family House Church, Ikeja',
        subtitle: 'Opebi Road, Ikeja, Lagos',
        metrics: [('9:00', 'Sunday'), ('6:00', 'Wednesday')],
        imageAsset: 'assets/images/church_building.png',
      ),
      _rows(const [
        ('Get Directions', 'Open church location'),
        ('Learn More', 'Vision, beliefs and community'),
      ]),
      _notice('Milestone completed: You have joined a church.'),
    ],
    KingdomJourneyKind.member => [
      _profile('Glory Samuel', 'glory.samuel@email.com • Lagos, Nigeria'),
      _details(const [
        ('Church Affiliation', 'Family House Church, Ikeja'),
        ('Membership Status', 'Active Member'),
        ('Membership ID', 'FHC-2025-00156'),
      ]),
      _notice('Milestone completed: You are now a church member!'),
    ],
    KingdomJourneyKind.grow => [
      const WorkflowSegments(
        labels: ['Overview', 'Study Manuals', 'Prayer', 'Training', 'Mentor'],
      ),
      const SizedBox(height: 12),
      const WorkflowSummary(
        title: 'Spiritual Growth Summary',
        metrics: [
          ('72%', 'Growth Score'),
          ('22', 'Consistent Days'),
          ('6', 'Devotions'),
          ('4', 'Trainings'),
        ],
      ),
      const WorkflowSectionTitle('Continue Your Growth'),
      _tiles(const [
        ('Study Manuals', Icons.menu_book_outlined),
        ('Prayer Life', Icons.self_improvement),
        ('Kingdom Training', Icons.school_outlined),
        ('Mentor Sessions', Icons.groups_outlined),
      ]),
    ],
    KingdomJourneyKind.serve => [
      _details(const [
        ('Service Status', 'Active Worker'),
        ('Department', 'Ushering Ministry'),
      ]),
      const WorkflowSectionTitle('My Responsibilities'),
      _checkList(const [
        'Welcome & usher members and guests',
        'Assist during services and events',
        'Maintain order and safety',
      ]),
      const WorkflowSectionTitle('Service Opportunities'),
      _rows(const [
        ('Children’s Ministry', 'Join'),
        ('Media & Tech Team', 'Join'),
        ('Worship Team', 'Join'),
      ]),
    ],
    KingdomJourneyKind.winSouls => [
      const WorkflowSummary(
        title: 'Soul-Winning Impact',
        metrics: [
          ('15', 'Souls Won'),
          ('5', 'Discipled'),
          ('28', 'Follow-ups'),
        ],
      ),
      const WorkflowSectionTitle('Recent Activities'),
      _rows(const [
        ('Shared the gospel with Amaka', 'New Convert'),
        ('Follow-up with Tunde', 'Growing'),
        ('Discipleship session with John', 'On Track'),
      ]),
      const WorkflowSectionTitle('Discipleship Journey'),
      const WorkflowProgress(
        label: 'Connect • Follow Up • Disciple • Integrate',
        value: .75,
        trailing: '3 / 4',
      ),
    ],
    KingdomJourneyKind.becomeKca => [
      _details(const [
        ('KCA Status', 'Certified'),
        ('Certified On', 'May 10, 2025'),
      ]),
      const WorkflowSectionTitle('Mentor Pathway'),
      const WorkflowProgress(
        label: 'Mentor Readiness',
        value: .8,
        trailing: '80%',
      ),
      _checkList(const [
        'Mentor Training • Completed',
        'Character Assessment • Completed',
        'Mentor Practicum • In Progress',
      ]),
      _notice('Next milestone: Become a Mentor and begin mentoring leaders.'),
    ],
    KingdomJourneyKind.homeChurch => [
      const WorkflowSegments(
        labels: ['Overview', 'Meetings', 'Members', 'Reports'],
      ),
      const SizedBox(height: 12),
      const WorkflowSummary(
        title: 'Glory House Fellowship',
        subtitle: 'Ikeja, Lagos • Approved',
        metrics: [
          ('18', 'Members'),
          ('6', 'Meetings'),
          ('7', 'Salvations'),
          ('3', 'Baptisms'),
        ],
        imageAsset: 'assets/images/connect_people.png',
      ),
      const WorkflowProgress(
        label: 'Development Progress',
        value: .65,
        trailing: '65%',
      ),
      _rows(const [('Next Steps', 'Continue discipleship and expand impact.')]),
    ],
    KingdomJourneyKind.multiply => [
      const WorkflowSummary(
        title: 'Multiply!',
        subtitle: 'A Multiplied Disciple-Making Movement • 2 Timothy 2:2',
        metrics: [],
        color: Color(0xFF073E31),
      ),
      const WorkflowSectionTitle('Kingdom Impact Summary'),
      const WorkflowSummary(
        title: 'Cycle Complete',
        metrics: [
          ('2', 'Churches Planted'),
          ('6', 'Leaders Raised'),
          ('12', 'Disciple-makers'),
          ('142', 'Souls Impacted'),
        ],
      ),
      _notice(
        'You have completed the Kingdom Multiplication Cycle! Keep multiplying for generations.',
      ),
    ],
  };

  Widget _cycle(int stage) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          for (var index = 1; index <= 14; index++)
            Expanded(
              child: Container(
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index <= stage ? FhcColors.green : FhcColors.border,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 6),
      Text('$stage of 14 milestones', style: FhcTypography.caption),
    ],
  );
  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: FhcTypography.body),
      ],
    ),
  );
  Widget _rows(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          WorkflowRow(title: value.$1, subtitle: value.$2),
      ],
    ),
  );
  Widget _tiles(List<(String, IconData)> values) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: values.length > 3 ? 2 : 3,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: .9,
    children: [
      for (final value in values)
        WorkflowCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(value.$2, color: FhcColors.green),
              const SizedBox(height: 7),
              Text(
                value.$1,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
    ],
  );
  Widget _notice(String text) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FhcColors.mint,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: FhcColors.green.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: FhcColors.green),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: FhcTypography.body)),
      ],
    ),
  );
  Widget _profile(String name, String subtitle) => WorkflowCard(
    child: Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: FhcColors.mint,
          child: Icon(Icons.person, color: FhcColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(subtitle, style: FhcTypography.caption),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _details(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text(value.$1, style: FhcTypography.caption)),
                Expanded(
                  child: Text(
                    value.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  Widget _checkList(List<String> labels) => WorkflowCard(
    child: Column(
      children: [
        for (final label in labels)
          WorkflowRow(
            title: label,
            leading: Icons.check_circle,
            trailing: const SizedBox.shrink(),
          ),
      ],
    ),
  );
}

class _JourneySpec {
  const _JourneySpec(
    this.title,
    this.subtitle,
    this.stage,
    this.action,
    this.next,
  );
  final String title;
  final String subtitle;
  final int stage;
  final String? action;
  final String? next;
}

import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/async_state.dart';
import '../../../../shared/widgets/workflow_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';
import '../../../maps/presentation/widgets/interactive_church_map.dart';

enum LeadershipContinuationKind {
  membershipRegistration,
  firstTimerRegistration,
  firstTimerJourney,
  convertProfile,
  discipleProgress,
  memberProfile,
  ministryRole,
  ministryHistory,
  evangelismActivity,
  evangelismReport,
  connectChurch,
  referralTracking,
  approvalsQueue,
  approvalDetail,
  leadershipReports,
  alerts,
  missionAi,
  kcaAi,
  pressAi,
  pastoralReports,
  scopeSelector,
  scopeDashboard,
  globalMap,
  mapFilter,
  missionLocation,
  noChurchNearby,
  globalExpansion,
}

class LeadershipContinuationScreen extends StatelessWidget {
  const LeadershipContinuationScreen({super.key, required this.kind});
  final LeadershipContinuationKind kind;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context, kind);
    final showFixtures =
        AppServicesScope.maybeOf(context)?.showUnboundFixtures ?? false;
    if (!showFixtures && _isFixtureDashboard(kind)) {
      return WorkflowPage(
        title: spec.title,
        domain: spec.domain,
        backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
        children: [
          const SizedBox(height: 24),
          FhcUnavailableState(
            title: fhcT(
              context,
              'errors.leadershipMetricsUnavailable',
              fallback: 'Leadership metrics unavailable',
            ),
            message: fhcT(
              context,
              'errors.leadershipMetricsUnavailableCopy',
              fallback:
                  'There is no Laravel KPI endpoint for this dashboard. '
                  'Membership, attendance, and similar totals are not shown.',
            ),
          ),
        ],
      );
    }
    return WorkflowPage(
      title: spec.title,
      domain: spec.domain,
      backTooltip: fhcT(context, 'common.back', fallback: 'Back'),
      actionLabel: spec.action,
      onAction: spec.next == null ? null : () => fhcPush(context, spec.next!),
      children: _content(context, kind),
    );
  }

  bool _isFixtureDashboard(LeadershipContinuationKind value) =>
      value == LeadershipContinuationKind.leadershipReports ||
      value == LeadershipContinuationKind.scopeDashboard;

  _LeadershipSpec _spec(BuildContext context, LeadershipContinuationKind value) =>
      switch (value) {
        LeadershipContinuationKind.membershipRegistration => _LeadershipSpec(
          fhcT(
            context,
            'member.membershipRegistration',
            fallback: 'Membership Registration',
          ),
          WorkflowDomain.church,
          fhcT(context, 'common.continue', fallback: 'Continue'),
          '/first-timer/register',
        ),
        LeadershipContinuationKind.firstTimerRegistration => _LeadershipSpec(
          fhcT(
            context,
            'member.firstTimerRegistration',
            fallback: 'First-Timer Registration',
          ),
          WorkflowDomain.community,
          fhcT(
            context,
            'member.saveFirstTimer',
            fallback: 'Save First-Timer',
          ),
          '/first-timer/journey',
        ),
        LeadershipContinuationKind.firstTimerJourney => _LeadershipSpec(
          fhcT(
            context,
            'member.firstTimerJourney',
            fallback: 'First-Timer Journey',
          ),
          WorkflowDomain.community,
          null,
          null,
        ),
        LeadershipContinuationKind.convertProfile => _LeadershipSpec(
          fhcT(context, 'member.convertProfile', fallback: 'Convert Profile'),
          WorkflowDomain.mission,
          fhcT(context, 'member.messageMentor', fallback: 'Message Mentor'),
          null,
        ),
        LeadershipContinuationKind.discipleProgress => _LeadershipSpec(
          fhcT(
            context,
            'member.discipleProgress',
            fallback: 'Disciple Progress',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.memberProfile => _LeadershipSpec(
          fhcT(context, 'member.memberProfile', fallback: 'Member Profile'),
          WorkflowDomain.community,
          null,
          null,
        ),
        LeadershipContinuationKind.ministryRole => _LeadershipSpec(
          fhcT(
            context,
            'member.ministryRoleProfile',
            fallback: 'Ministry Role Profile',
          ),
          WorkflowDomain.church,
          null,
          null,
        ),
        LeadershipContinuationKind.ministryHistory => _LeadershipSpec(
          fhcT(
            context,
            'member.ministryHistory',
            fallback: 'Ministry History',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.evangelismActivity => _LeadershipSpec(
          fhcT(
            context,
            'member.evangelismActivity',
            fallback: 'Evangelism Activity',
          ),
          WorkflowDomain.mission,
          fhcT(context, 'member.saveActivity', fallback: 'Save Activity'),
          '/evangelism/report',
        ),
        LeadershipContinuationKind.evangelismReport => _LeadershipSpec(
          fhcT(
            context,
            'member.evangelismReport',
            fallback: 'Evangelism Report',
          ),
          WorkflowDomain.mission,
          fhcT(
            context,
            'member.viewDetailedReport',
            fallback: 'View Detailed Report',
          ),
          null,
        ),
        LeadershipContinuationKind.connectChurch => _LeadershipSpec(
          fhcT(context, 'member.connectToChurch', fallback: 'Connect to Church'),
          WorkflowDomain.church,
          null,
          null,
        ),
        LeadershipContinuationKind.referralTracking => _LeadershipSpec(
          fhcT(
            context,
            'member.referralTracking',
            fallback: 'Referral Tracking',
          ),
          WorkflowDomain.church,
          fhcT(context, 'member.logNewContact', fallback: 'Log New Contact'),
          null,
        ),
        LeadershipContinuationKind.approvalsQueue => _LeadershipSpec(
          fhcT(context, 'member.approvalsQueue', fallback: 'Approvals Queue'),
          WorkflowDomain.more,
          fhcT(context, 'common.viewAll', fallback: 'View All'),
          '/leadership/approval',
        ),
        LeadershipContinuationKind.approvalDetail => _LeadershipSpec(
          fhcT(context, 'member.approvalRequest', fallback: 'Approval Request'),
          WorkflowDomain.more,
          null,
          null,
        ),
        LeadershipContinuationKind.leadershipReports => _LeadershipSpec(
          fhcT(
            context,
            'member.leadershipDashboard',
            fallback: 'Leadership Dashboard',
          ),
          WorkflowDomain.more,
          null,
          null,
        ),
        LeadershipContinuationKind.alerts => _LeadershipSpec(
          fhcT(context, 'member.alertsCentre', fallback: 'Alerts Centre'),
          WorkflowDomain.more,
          fhcT(
            context,
            'member.viewResolvedAlerts',
            fallback: 'View Resolved Alerts',
          ),
          null,
        ),
        LeadershipContinuationKind.missionAi => _LeadershipSpec(
          fhcT(
            context,
            'member.missionAiAssistant',
            fallback: 'Mission AI Assistant',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.kcaAi => _LeadershipSpec(
          fhcT(
            context,
            'member.kcaAiStudyAssistant',
            fallback: 'KCA AI Study Assistant',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.pressAi => _LeadershipSpec(
          fhcT(
            context,
            'nav.pressAiAssistant',
            fallback: 'Press AI Assistant',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.pastoralReports => _LeadershipSpec(
          fhcT(
            context,
            'member.pastoralAiReports',
            fallback: 'Pastoral AI Assistant — Reports Mode',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.scopeSelector => _LeadershipSpec(
          fhcT(
            context,
            'member.leadershipScopeSelector',
            fallback: 'Leadership Scope Selector',
          ),
          WorkflowDomain.journey,
          fhcT(context, 'common.continue', fallback: 'Continue'),
          '/leadership/scope-dashboard',
        ),
        LeadershipContinuationKind.scopeDashboard => _LeadershipSpec(
          fhcT(
            context,
            'member.scopeAwareDashboard',
            fallback: 'Scope-Aware Leadership Dashboard',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.globalMap => _LeadershipSpec(
          fhcT(
            context,
            'member.globalFamilyHouseMap',
            fallback: 'Global Family House Map',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.mapFilter => _LeadershipSpec(
          fhcT(
            context,
            'member.mapFilterSearch',
            fallback: 'Map Filter & Search',
          ),
          WorkflowDomain.journey,
          fhcT(context, 'common.applyFilters', fallback: 'Apply Filters'),
          '/map',
        ),
        LeadershipContinuationKind.missionLocation => _LeadershipSpec(
          fhcT(
            context,
            'member.missionLocationDetail',
            fallback: 'Mission Location Detail',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
        LeadershipContinuationKind.noChurchNearby => _LeadershipSpec(
          fhcT(
            context,
            'member.noChurchNearby',
            fallback: 'No Church Nearby?',
          ),
          WorkflowDomain.journey,
          fhcT(
            context,
            'member.exploreYourOptions',
            fallback: 'Explore Your Options',
          ),
          '/global-expansion',
        ),
        LeadershipContinuationKind.globalExpansion => _LeadershipSpec(
          fhcT(
            context,
            'member.chooseYourNextMove',
            fallback: 'Choose Your Next Move',
          ),
          WorkflowDomain.journey,
          null,
          null,
        ),
      };

  List<Widget> _content(
    BuildContext context,
    LeadershipContinuationKind value,
  ) => switch (value) {
    LeadershipContinuationKind.membershipRegistration => [
      WorkflowSegments(
        labels: [
          fhcT(context, 'member.personal', fallback: 'Personal'),
          fhcT(context, 'member.contact', fallback: 'Contact'),
          fhcT(context, 'nav.church', fallback: 'Church'),
          fhcT(context, 'member.review', fallback: 'Review'),
        ],
      ),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.personalInformation',
          fallback: 'Personal Information',
        ),
      ),
      WorkflowField(
        label: fhcT(context, 'member.fullName', fallback: 'Full Name'),
        value: 'John David Osei',
      ),
      WorkflowSegments(
        labels: [
          fhcT(context, 'member.male', fallback: 'Male'),
          fhcT(context, 'member.female', fallback: 'Female'),
        ],
      ),
      const SizedBox(height: 12),
      WorkflowField(
        label: fhcT(context, 'member.dateOfBirth', fallback: 'Date of Birth'),
        value: 'May 12, 1990',
        icon: Icons.calendar_today_outlined,
      ),
      WorkflowField(
        label: fhcT(context, 'member.country', fallback: 'Country'),
        value: 'Ghana',
      ),
      WorkflowField(
        label: fhcT(context, 'common.stateRegion', fallback: 'State / Region'),
        value: 'Greater Accra',
      ),
      WorkflowField(
        label: fhcT(context, 'common.lgaCity', fallback: 'LGA / City'),
        value: 'Accra',
      ),
      WorkflowField(
        label: fhcT(context, 'common.language', fallback: 'Language'),
        value: 'English',
      ),
      WorkflowField(
        label: fhcT(context, 'member.occupation', fallback: 'Occupation'),
        value: 'Teacher',
      ),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.churchAffiliation',
          fallback: 'Church Affiliation',
        ),
      ),
      _rows([
        (
          fhcT(context, 'member.homeChurch', fallback: 'Home Church'),
          'Family House – East Legon',
        ),
        (
          fhcT(context, 'member.membershipType', fallback: 'Membership Type'),
          fhcT(context, 'member.regularMember', fallback: 'Regular Member'),
        ),
      ]),
    ],
    LeadershipContinuationKind.firstTimerRegistration => [
      WorkflowSummary(
        title: fhcT(
          context,
          'member.welcomeToFamilyHouseConnect',
          fallback: 'Welcome to Family House Connect!',
        ),
        subtitle: fhcT(
          context,
          'member.gladYouAreHere',
          fallback: 'We are glad you are here.',
        ),
        metrics: const [],
        imageAsset: 'assets/images/connect_people.png',
      ),
      WorkflowField(
        label: fhcT(context, 'member.fullName', fallback: 'Full Name'),
        value: 'Grace A. Mensah',
      ),
      WorkflowField(
        label: fhcT(
          context,
          'member.phoneWhatsapp',
          fallback: 'Phone / WhatsApp',
        ),
        value: '+233 24 123 4567',
      ),
      WorkflowField(
        label: fhcT(context, 'member.email', fallback: 'Email'),
        value: 'grace.mensah@email.com',
      ),
      WorkflowField(
        label: fhcT(context, 'member.country', fallback: 'Country'),
        value: 'Ghana',
      ),
      WorkflowField(
        label: fhcT(context, 'common.stateRegion', fallback: 'State / Region'),
        value: 'Greater Accra',
      ),
      WorkflowField(
        label: fhcT(context, 'common.lgaCity', fallback: 'LGA / City'),
        value: 'Accra',
      ),
      WorkflowField(
        label: fhcT(
          context,
          'member.howDidYouHear',
          fallback: 'How did you hear about us?',
        ),
        value: fhcT(
          context,
          'member.friendFamily',
          fallback: 'Friend / Family',
        ),
      ),
      WorkflowField(
        label: fhcT(
          context,
          'member.firstVisitDate',
          fallback: 'First Visit Date',
        ),
        value: 'May 24, 2025',
        icon: Icons.calendar_today_outlined,
      ),
      _checkList([
        fhcT(
          context,
          'member.agreeFollowUp',
          fallback: 'I agree to be contacted for follow-up.',
        ),
      ]),
    ],
    LeadershipContinuationKind.firstTimerJourney => [
      _profile(
        'Grace A. Mensah',
        '${fhcT(context, 'member.firstVisit', fallback: 'First Visit')}: May 24, 2025 • ${fhcT(context, 'member.inProgress', fallback: 'In Progress')}',
      ),
      _timeline([
        (
          fhcT(context, 'member.welcome', fallback: 'Welcome'),
          fhcT(
            context,
            'member.visitedChurchOnline',
            fallback: 'Visited Church / Online',
          ),
        ),
        (
          fhcT(context, 'member.contact', fallback: 'Contact'),
          fhcT(
            context,
            'member.initialContactMade',
            fallback: 'Initial contact made',
          ),
        ),
        (
          fhcT(context, 'member.followUp', fallback: 'Follow-up'),
          fhcT(
            context,
            'member.fortyEightHourFollowUp',
            fallback: '48-hour follow-up',
          ),
        ),
        (
          fhcT(context, 'member.convert', fallback: 'Convert'),
          fhcT(
            context,
            'member.savedDecision',
            fallback: 'Saved / Decision',
          ),
        ),
        (
          fhcT(context, 'member.discipleship', fallback: 'Discipleship'),
          fhcT(
            context,
            'member.beingDiscipled',
            fallback: 'Being discipled',
          ),
        ),
        (
          fhcT(context, 'member.memberLabel', fallback: 'Member'),
          fhcT(context, 'member.churchMember', fallback: 'Church member'),
        ),
        (
          fhcT(context, 'member.worker', fallback: 'Worker'),
          fhcT(
            context,
            'member.servingInMinistry',
            fallback: 'Serving in ministry',
          ),
        ),
        (
          fhcT(context, 'member.leader', fallback: 'Leader'),
          fhcT(
            context,
            'member.leadershipTraining',
            fallback: 'Leadership training',
          ),
        ),
      ]),
    ],
    LeadershipContinuationKind.convertProfile => [
      _profile(
        'Samuel K. Boateng',
        '${fhcT(context, 'member.convertedOn', fallback: 'Converted on')} May 19, 2025 • ${fhcT(context, 'member.convert', fallback: 'Convert')}',
      ),
      WorkflowSummary(
        title: fhcT(
          context,
          'member.followUpStatus',
          fallback: 'Follow-up Status',
        ),
        metrics: [
          (
            'Esther Asante',
            fhcT(context, 'member.kcaMentor', fallback: 'Mentor'),
          ),
          (
            fhcT(context, 'member.active', fallback: 'Active'),
            fhcT(context, 'member.followUp', fallback: 'Follow-up'),
          ),
        ],
      ),
      _details([
        (
          fhcT(context, 'member.salvationDate', fallback: 'Salvation Date'),
          'May 18, 2025',
        ),
        (
          fhcT(context, 'member.place', fallback: 'Place'),
          'Family House – Accra',
        ),
        (
          fhcT(context, 'member.baptismInterest', fallback: 'Baptism Interest'),
          fhcT(context, 'common.yes', fallback: 'Yes'),
        ),
      ]),
      _rows([
        (
          fhcT(
            context,
            'member.nextDiscipleshipStep',
            fallback: 'Next Discipleship Step',
          ),
          fhcT(
            context,
            'member.startFoundationDiscipleship',
            fallback: 'Start Foundation Discipleship',
          ),
        ),
      ]),
    ],
    LeadershipContinuationKind.discipleProgress => [
      _profile(
        'Samuel K. Boateng',
        '${fhcT(context, 'member.discipleSince', fallback: 'Disciple since')} May 19, 2025 • ${fhcT(context, 'member.level2', fallback: 'Level 2')}',
      ),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.growthMilestones',
          fallback: 'Growth Milestones',
        ),
      ),
      _tiles([
        (
          fhcT(context, 'member.salvation', fallback: 'Salvation'),
          Icons.favorite,
        ),
        (
          fhcT(context, 'member.baptism', fallback: 'Baptism'),
          Icons.water_drop_outlined,
        ),
        (
          fhcT(context, 'member.membership', fallback: 'Membership'),
          Icons.groups_outlined,
        ),
        (
          fhcT(context, 'member.worker', fallback: 'Worker'),
          Icons.badge_outlined,
        ),
      ]),
      _rows([
        (
          fhcT(context, 'member.bibleStudy', fallback: 'Study Manuals'),
          fhcT(
            context,
            'member.completedOf',
            args: {'done': '4', 'total': '8'},
            fallback: '4 of 8 Completed',
          ),
        ),
        (
          fhcT(context, 'member.prayerLife', fallback: 'Prayer Life'),
          fhcT(
            context,
            'member.completedOf',
            args: {'done': '3', 'total': '7'},
            fallback: '3 of 7 Completed',
          ),
        ),
        (
          fhcT(context, 'member.mentorMeetings', fallback: 'Mentor Meetings'),
          fhcT(
            context,
            'member.completedOf',
            args: {'done': '2', 'total': '4'},
            fallback: '2 of 4 Completed',
          ),
        ),
        (
          fhcT(
            context,
            'member.ministryTraining',
            fallback: 'Ministry Training',
          ),
          fhcT(
            context,
            'member.completedOf',
            args: {'done': '1', 'total': '5'},
            fallback: '1 of 5 Completed',
          ),
        ),
      ]),
      _notice(
        fhcT(
          context,
          'member.nextMilestoneBibleStudies',
          fallback: 'Next milestone: Complete 2 more study manuals.',
        ),
      ),
    ],
    LeadershipContinuationKind.memberProfile => [
      _profile(
        'John David Osei',
        '${fhcT(context, 'member.memberSince', fallback: 'Member since')} Mar 15, 2024 • ${fhcT(context, 'member.memberLabel', fallback: 'Member')}',
      ),
      _details([
        (
          fhcT(context, 'member.gender', fallback: 'Gender'),
          fhcT(context, 'member.male', fallback: 'Male'),
        ),
        (fhcT(context, 'member.dob', fallback: 'DOB'), 'May 12, 1990'),
        (
          fhcT(context, 'member.country', fallback: 'Country'),
          'Ghana',
        ),
        (
          fhcT(context, 'common.stateRegion', fallback: 'State / Region'),
          'Greater Accra',
        ),
        (
          fhcT(context, 'common.lgaCity', fallback: 'LGA / City'),
          'Accra',
        ),
        (fhcT(context, 'member.phone', fallback: 'Phone'), '+233 24 567 8901'),
        (fhcT(context, 'common.language', fallback: 'Language'), 'English'),
        (
          fhcT(context, 'member.occupation', fallback: 'Occupation'),
          'Teacher',
        ),
        (
          fhcT(context, 'nav.church', fallback: 'Church'),
          'Family House – Accra',
        ),
        (
          fhcT(context, 'member.homeChurch', fallback: 'Home Church'),
          'Family House – East Legon',
        ),
        (fhcT(context, 'member.baptised', fallback: 'Baptised'), 'Apr 10, 2024'),
        (
          fhcT(context, 'member.kcaStatus', fallback: 'KCA Status'),
          fhcT(context, 'member.enrolled', fallback: 'Enrolled'),
        ),
      ]),
    ],
    LeadershipContinuationKind.ministryRole => [
      _profile(
        'Mary Johnson',
        '${fhcT(context, 'member.memberSince', fallback: 'Member since')} Jan 20, 2023 • ${fhcT(context, 'member.worker', fallback: 'Worker')}',
      ),
      _details([
        (
          fhcT(context, 'member.role', fallback: 'Role'),
          fhcT(
            context,
            'member.mediaTeamMember',
            fallback: 'Media Team Member',
          ),
        ),
        (
          fhcT(context, 'member.department', fallback: 'Department'),
          fhcT(context, 'member.communications', fallback: 'Communications'),
        ),
        (
          fhcT(context, 'member.serviceStatus', fallback: 'Service Status'),
          fhcT(context, 'member.active', fallback: 'Active'),
        ),
        (fhcT(context, 'member.leader', fallback: 'Leader'), 'Daniel Asante'),
      ]),
      WorkflowSectionTitle(
        fhcT(context, 'member.responsibilities', fallback: 'Responsibilities'),
      ),
      _checkList([
        fhcT(
          context,
          'member.manageSundayVisuals',
          fallback: 'Manage Sunday visuals',
        ),
        fhcT(
          context,
          'member.operateLivestream',
          fallback: 'Operate church livestream',
        ),
        fhcT(
          context,
          'member.createSermonGraphics',
          fallback: 'Create sermon graphics',
        ),
        fhcT(
          context,
          'member.maintainMediaEquipment',
          fallback: 'Maintain media equipment',
        ),
      ]),
      WorkflowSectionTitle(
        fhcT(
          context,
          'member.trainingDevelopment',
          fallback: 'Training & Development',
        ),
      ),
      WorkflowProgress(
        label: fhcT(
          context,
          'member.digitalMediaBasics',
          fallback: 'Digital Media Basics',
        ),
        value: .8,
        trailing: '80%',
      ),
    ],
    LeadershipContinuationKind.ministryHistory => [
      _profile(
        'John David Osei',
        '${fhcT(context, 'member.memberSince', fallback: 'Member since')} Mar 15, 2024',
      ),
      WorkflowSegments(
        labels: [
          fhcT(context, 'member.journey', fallback: 'Journey'),
          fhcT(context, 'member.activities', fallback: 'Activities'),
        ],
      ),
      _timeline([
        (
          fhcT(
            context,
            'member.visitorFirstTimer',
            fallback: 'Visitor / First-Timer',
          ),
          '${fhcT(context, 'member.visited', fallback: 'Visited')} Jan 8, 2023',
        ),
        (
          fhcT(context, 'member.convert', fallback: 'Convert'),
          '${fhcT(context, 'member.saved', fallback: 'Saved')} Jan 15, 2023',
        ),
        (
          fhcT(context, 'member.disciple', fallback: 'Disciple'),
          '${fhcT(context, 'member.discipleshipCompleted', fallback: 'Discipleship completed')} Mar 5, 2023',
        ),
        (
          fhcT(context, 'member.memberLabel', fallback: 'Member'),
          '${fhcT(context, 'member.joined', fallback: 'Joined')} Mar 15, 2023',
        ),
        (
          fhcT(context, 'member.worker', fallback: 'Worker'),
          '${fhcT(context, 'member.becameWorker', fallback: 'Became worker')} Jun 12, 2023',
        ),
        (
          fhcT(context, 'member.kcaMentor', fallback: 'Mentor'),
          '${fhcT(context, 'member.training', fallback: 'Training')} Nov 4, 2023',
        ),
        (
          fhcT(context, 'member.kca', fallback: 'KCA'),
          '${fhcT(context, 'member.enrolled', fallback: 'Enrolled')} Feb 10, 2024',
        ),
        (
          fhcT(
            context,
            'member.ministryActivity',
            fallback: 'Ministry Activity',
          ),
          '${fhcT(context, 'member.prayer', fallback: 'Prayer')} ${fhcT(context, 'member.onDate', fallback: 'on')} May 18, 2025',
        ),
      ]),
    ],
    LeadershipContinuationKind.evangelismActivity => [
      const WorkflowField(label: 'Activity Type', value: 'Street Evangelism'),
      const WorkflowField(label: 'Location', value: 'Madina Market, Accra'),
      const WorkflowField(
        label: 'Date',
        value: 'May 24, 2025',
        icon: Icons.calendar_today_outlined,
      ),
      const WorkflowField(label: 'Time', value: '4:00 PM – 7:00 PM'),
      const WorkflowField(label: 'Team Leader', value: 'Joseph Addo'),
      const WorkflowField(label: 'Team Members', value: '5 members'),
      const WorkflowField(
        label: 'Notes',
        value:
            'Shared tracts, had conversations with many people. Great openness.',
        lines: 5,
      ),
    ],
    LeadershipContinuationKind.evangelismReport => [
      const WorkflowSummary(
        title: 'Evangelism Results • This Week',
        metrics: [
          ('126', 'Souls Contacted'),
          ('18', 'Souls Saved'),
          ('14', 'Converts'),
          ('9', 'Referrals'),
        ],
      ),
      const WorkflowSectionTitle('Follow-up Status'),
      _progressList(const [
        ('Contacted', .38),
        ('In Follow-up', .27),
        ('Responded', .16),
        ('Awaiting Decision', .12),
        ('No Response', .07),
      ]),
      const WorkflowSummary(
        title: 'Team Summary',
        metrics: [('4', 'Teams'), ('18', 'Workers'), ('6', 'Activities')],
      ),
    ],
    LeadershipContinuationKind.connectChurch => [
      _profile('Grace A. Mensah', 'First-Timer • May 24, 2025'),
      _choice(
        'Nearest Conventional Church',
        'Find a Family House church near you.',
        Icons.church_outlined,
      ),
      _choice(
        'Nearest Home Church',
        'Join a home church close to your location.',
        Icons.home_work_outlined,
      ),
      _choice(
        'Online Church',
        'Join an online church community.',
        Icons.live_tv_outlined,
      ),
      _notice('We will assign a mentor and start your follow-up journey.'),
    ],
    LeadershipContinuationKind.referralTracking => [
      _profile('Grace A. Mensah', 'First-Timer • In Follow-up'),
      _details(const [
        ('Referral Status', 'In Follow-up'),
        ('Assigned Church', 'Family House – East Legon'),
        ('Assigned Mentor', 'Esther Asante'),
        ('Next Action', '48-hour follow-up call'),
        ('Due', 'May 24, 2025 • 6:00 PM'),
      ]),
      const WorkflowSectionTitle('Contact History'),
      _timeline(const [
        ('Initial visit recorded', 'May 24 • 10:15 AM'),
        ('Pastor welcome message sent', 'May 24 • 3:30 PM'),
        ('Follow-up call — No response yet', 'May 25 • 9:00 AM'),
      ]),
    ],
    LeadershipContinuationKind.approvalsQueue => [
      const WorkflowSegments(
        labels: ['All', 'Membership', 'Ministry', 'Financial'],
      ),
      _rows(const [
        ('Membership Request', 'John David Osei • 2h • High'),
        ('Worker Activation', 'Mary Johnson • 4h • High'),
        ('Ministry Budget Request', 'Youth Ministry • 1d • Medium'),
        ('Home Church Registration', 'House of Grace • 2d • Medium'),
        ('KCA Enrollment', 'Samuel K. Boateng • 2d • Low'),
        ('Event Approval', 'Crusade – Accra • 3d • Low'),
      ]),
    ],
    LeadershipContinuationKind.approvalDetail => [
      _status('Membership Request', 'High Priority'),
      _profile('John David Osei', 'Requesting membership'),
      _details(const [
        ('Submitted on', 'May 24, 2025 • 8:45 AM'),
        ('Requested by', 'Pastor Daniel Asante'),
        ('Membership Type', 'Regular Member'),
        ('Home Church', 'Family House – East Legon'),
        ('Joined Church', 'May 24, 2025'),
        ('Notes', 'Completed discipleship and faith steps.'),
      ]),
      const WorkflowSectionTitle('Reviewers'),
      _tiles(const [
        ('Approve', Icons.check),
        ('Clarify', Icons.help_outline),
        ('Assign', Icons.person_add_alt),
        ('Reject', Icons.close),
      ]),
    ],
    LeadershipContinuationKind.leadershipReports => [
      const WorkflowField(label: 'Reporting Period', value: 'This Month'),
      _metricGrid(const [
        ('Membership Growth', '+48'),
        ('Attendance (Avg.)', '412'),
        ('First-Timer Conversion', '27%'),
        ('Evangelism (Saved)', '86'),
        ('Home Church Growth', '+12'),
        ('Ministry Performance', '89%'),
      ]),
      _notice(
        'First-timer conversion rate is up by 9%. Keep up the follow-up!',
      ),
    ],
    LeadershipContinuationKind.alerts => [
      const WorkflowSegments(labels: ['All Alerts', 'Unread (5)', 'Settings']),
      _rows(const [
        (
          'First-Timer Not Contacted',
          '12 first-timers not contacted within 48 hours • High',
        ),
        ('Overdue Monthly Report', '5 reports are overdue • Medium'),
        ('Crusade Follow-up Gap', '34 contacts need follow-up • High'),
        ('KCA Intervention Alert', '3 members need intervention • Medium'),
        ('Financial Report Overdue', 'April 2025 report not submitted • High'),
      ]),
    ],
    LeadershipContinuationKind.missionAi => [
      _assistantHeader(
        'Good morning, Pastor Glory 👋',
        'How can I help your mission today?',
      ),
      const WorkflowSectionTitle('Mission Insights'),
      _rows(const [
        ('Crusade follow-up gap', '24 converts not contacted within 7 days'),
        (
          'Souls needing urgent attention',
          '16 souls require immediate pastoral follow-up',
        ),
        (
          'Recommended next actions',
          'Prioritized actions to close gaps and grow impact',
        ),
      ]),
      const WorkflowSectionTitle('Quick Analysis'),
      _tiles(const [
        ('Crusade Analysis', Icons.analytics_outlined),
        ('Follow-up Gaps', Icons.track_changes),
        ('Response Trends', Icons.show_chart),
        ('Mission Health', Icons.health_and_safety_outlined),
      ]),
      _notice('AI assists mission decisions; leaders remain responsible.'),
    ],
    LeadershipContinuationKind.kcaAi => [
      const WorkflowSummary(
        title: 'Current Module',
        subtitle: 'Leadership & Influence • Module 4 • Week 2 of 6',
        metrics: [('60%', 'Progress')],
      ),
      _rows(const [
        (
          'Current Lesson Explanation',
          'AI explains key concepts and applications',
        ),
        ('Practice Questions', '10 questions • 3 completed'),
        ('Study Guidance', 'Study plan, memory verse, prayer points'),
        (
          'Help with Difficult Topics',
          'Get clarity with scripture-based answers',
        ),
      ]),
      _notice(
        'AI supports your learning but does not bypass mentor or admin review.',
      ),
    ],
    LeadershipContinuationKind.pressAi => [
      const WorkflowField(
        label: 'Search',
        value: 'Search resources, topics, authors…',
      ),
      const WorkflowSectionTitle('Top Results'),
      _rows(const [
        ('The Power of Prayer', 'Book • Prayer • EN'),
        ('Faith That Moves Mountains', 'Sermon • Faith • EN'),
        ('Daily Glory Devotional', 'Devotional • Various • EN'),
        ('KCA Leadership Manual', 'KCA Material • Student Guide'),
      ]),
      const WorkflowSectionTitle('Suggested Metadata'),
      _details(const [
        ('Title', 'Walking in Kingdom Authority'),
        ('Category', 'Book / Leadership'),
        ('Language', 'English'),
        ('Keywords', 'Kingdom, Authority, Faith, Leadership'),
      ]),
    ],
    LeadershipContinuationKind.pastoralReports => [
      const WorkflowSegments(
        labels: ['Summary', 'Trends', 'Insights', 'Follow-ups'],
      ),
      const WorkflowSectionTitle('Key Report Insights'),
      _rows(const [
        ('Rising Attendance', 'Overall attendance up 15% vs last month'),
        ('First-Timer Conversion Rate', '8.6% converted to members'),
        ('Home Church at Risk', '2 home churches show declining engagement'),
        (
          'Branch Needing Follow-up',
          '3 branches need pastoral follow-up this week',
        ),
      ]),
      _rows(const [
        (
          'Auto-Generated Follow-up List',
          '24 people require follow-up actions',
        ),
      ]),
      _notice(
        'AI assists leadership and does not make pastoral or governance decisions.',
      ),
    ],
    LeadershipContinuationKind.scopeSelector => [
      _details(const [
        (
          'Current Selection',
          'Global > Africa > Nigeria > Lagos State > Lagos Mainland Area',
        ),
      ]),
      const WorkflowSectionTitle('Select Scope Level'),
      _choiceList(const [
        'Global',
        'Country',
        'Region / State',
        'Local Area',
        'Church',
        'Home Church',
      ], 3),
    ],
    LeadershipContinuationKind.scopeDashboard => [
      _details(const [
        (
          'Scope',
          'Global > Africa > Nigeria > Lagos State > Lagos Mainland Area',
        ),
        ('Data as of', 'May 9, 2025'),
      ]),
      _metricGrid(const [
        ('Members', '12,584'),
        ('Home Churches', '186'),
        ('KCA Students', '2,304'),
        ('Souls Won', '3,862'),
        ('Mission Projects', '28'),
        ('Online Attendees', '5,248'),
      ]),
      const WorkflowSectionTitle('Alerts'),
      _rows(const [
        ('2 branches reporting declining attendance', 'Review'),
        ('24 converts not contacted in 7 days', 'Review'),
      ]),
      const WorkflowSectionTitle('Pending Approvals'),
      _rows(const [
        ('Home Church Registration', '3'),
        ('KCA Student Enrollments', '2'),
      ]),
    ],
    LeadershipContinuationKind.globalMap => [
      _mapCard(),
      const WorkflowSectionTitle('Nearby Highlights'),
      _rows(const [
        ('Lagos Mainland Area', '186 Home Churches • 12.6K Members • 2 km'),
        ('Agejunle Home Churches', '24 Home Churches • 1.2K Members • 6 km'),
        ('Surulere Conventional Church', '1.1K Members • 7 km'),
      ]),
    ],
    LeadershipContinuationKind.mapFilter => [
      const WorkflowField(
        label: 'Search',
        value: 'Search city, country, region…',
      ),
      const WorkflowSectionTitle('Active Filters'),
      const WorkflowSegments(
        labels: ['Africa', 'Home Churches', 'Within 50 km'],
      ),
      const WorkflowSectionTitle('Church Type'),
      _choiceList(const ['Conventional', 'Home', 'Online', 'Mission'], 1),
      const WorkflowSectionTitle('Distance'),
      const WorkflowSegments(labels: ['10 km', '25 km', '50 km', '100 km']),
      const WorkflowSectionTitle('Meeting Time'),
      const WorkflowSegments(
        labels: ['Any Time', 'Morning', 'Afternoon', 'Evening'],
      ),
      _rows(const [
        ('Country', 'Any'),
        ('Language', 'Any'),
        ('Ministry Focus', 'Any'),
      ]),
    ],
    LeadershipContinuationKind.missionLocation => [
      const WorkflowSummary(
        title: 'Hope Africa Mission — Nairobi',
        subtitle: 'Mission Location',
        metrics: [],
        imageAsset: 'assets/images/mission_banner.png',
      ),
      const WorkflowSummary(
        title: 'Mission Overview',
        metrics: [
          ('1,248', 'Souls Reached'),
          ('36', 'Home Churches'),
          ('12', 'Active Leaders'),
          ('842', 'Monthly Attendees'),
        ],
      ),
      _rows(const [
        ('Nairobi Outreach Crusade', 'May 24–25, 2025 • 4:00 PM Daily'),
        ('Pastor David Mwangi', '+254 712 345 678'),
        ('Follow-up Status', '64 converts require follow-up'),
        ('Connected Churches', 'Nairobi East Home Church'),
      ]),
      _tiles(const [
        ('Directions', Icons.directions),
        ('Share', Icons.share_outlined),
        ('Pray', Icons.self_improvement),
      ]),
    ],
    LeadershipContinuationKind.noChurchNearby => [
      const SizedBox(height: 40),
      const Center(
        child: Icon(Icons.public, size: 100, color: FhcColors.green),
      ),
      const SizedBox(height: 20),
      const Text(
        'Your journey can still begin.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      const Text(
        'Start your church in your home, join online church, connect with a pastor, or begin KCA.',
        textAlign: TextAlign.center,
        style: FhcTypography.body,
      ),
    ],
    LeadershipContinuationKind.globalExpansion => [
      _rows(const [
        ('Start a Church in Your Home', 'Become a light in your community.'),
        ('Join Online Church', 'Worship and connect virtually.'),
        ('Connect to Pastor / Mentor', 'Get guidance and encouragement.'),
        ('KCA', 'Study, grow and become a Kingdom Agent.'),
        ('Digital Publications', 'Books, sermons, devotionals & more.'),
      ]),
      const WorkflowSummary(
        title: 'You are part of a global family.',
        subtitle: 'The Kingdom is everywhere!',
        metrics: [],
      ),
    ],
  };

  Widget _profile(String name, String subtitle) => WorkflowCard(
    child: Row(
      children: [
        const CircleAvatar(
          radius: 28,
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
  Widget _rows(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          WorkflowRow(title: value.$1, subtitle: value.$2),
      ],
    ),
  );
  Widget _details(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
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
  Widget _timeline(List<(String, String)> values) => WorkflowCard(
    child: Column(
      children: [
        for (var index = 0; index < values.length; index++)
          WorkflowRow(
            title: values[index].$1,
            subtitle: values[index].$2,
            leading:
                index < 3 ? Icons.check_circle : Icons.radio_button_unchecked,
            accent: index < 3 ? FhcColors.green : FhcColors.muted,
            trailing: const SizedBox.shrink(),
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
            leading: Icons.check,
            trailing: const SizedBox.shrink(),
          ),
      ],
    ),
  );
  Widget _tiles(List<(String, IconData)> values) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: values.length > 3 ? 2 : values.length,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.25,
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
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FhcColors.mint,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: FhcColors.green),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: FhcTypography.body)),
      ],
    ),
  );
  Widget _choice(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: WorkflowCard(
      child: WorkflowRow(title: title, subtitle: subtitle, leading: icon),
    ),
  );
  Widget _progressList(List<(String, double)> values) => WorkflowCard(
    child: Column(
      children: [
        for (final value in values)
          WorkflowProgress(
            label: value.$1,
            value: value.$2,
            trailing: '${(value.$2 * 100).round()}%',
          ),
      ],
    ),
  );
  Widget _status(String title, String subtitle) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FhcColors.orange.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        const Icon(Icons.priority_high, color: FhcColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
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
  Widget _metricGrid(List<(String, String)> values) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.55,
    children: [
      for (final value in values)
        WorkflowCard(
          color: FhcColors.mint,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.$2,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.greenDark,
                ),
              ),
              Text(
                value.$1,
                textAlign: TextAlign.center,
                style: FhcTypography.caption,
              ),
            ],
          ),
        ),
    ],
  );
  Widget _assistantHeader(String title, String subtitle) => WorkflowCard(
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: FhcColors.mint,
          child: Icon(Icons.smart_toy_outlined, color: FhcColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
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
  Widget _choiceList(List<String> labels, int selected) => WorkflowCard(
    child: Column(
      children: [
        for (var index = 0; index < labels.length; index++)
          WorkflowRow(
            title: labels[index],
            leading:
                index == selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
            trailing: const SizedBox.shrink(),
            accent: FhcColors.green,
          ),
      ],
    ),
  );
  Widget _mapCard() => const InteractiveChurchMap(height: 300);
}

class _LeadershipSpec {
  const _LeadershipSpec(this.title, this.domain, this.action, this.next);
  final String title;
  final WorkflowDomain domain;
  final String? action;
  final String? next;
}

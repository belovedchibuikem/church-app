import 'package:flutter/material.dart';

abstract final class FhcRoutes {
  static const splash = '/splash';
  static const hub = '/hub';
  static const modules = '/modules';
  static const discover = '/discover';
  static const messages = '/messages';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static const churches = '/churches';
  static const church = '/church';
  static const churchHome = '/church/home';
  static const churchAdmin = '/church/admin';
  static const churchDetail = '/church/detail';
  static const churchMembers = '/church/members';
  static const churchGroups = '/church/groups';
  static const churchAnnouncements = '/church/announcements';
  static const churchMinistries = '/church/ministries';
  static const churchDocuments = '/church/documents';
  static const churchSettings = '/church/settings';
  static const homeChurch = '/home-church';
  static const homeChurchStart = '/home-church/start';
  static const homeChurchStart2 = '/home-church/start/2';
  static const homeChurchStart3 = '/home-church/start/3';
  static const homeChurchStart4 = '/home-church/start/4';
  static const homeChurchApplications = '/home-church/applications';
  static const homeChurchProgress = '/home-church/progress';

  static const mission = '/mission';
  static const crusade = '/mission/crusade';
  static const souls = '/mission/souls';

  static const kca = '/kca';
  static const kcaGate = '/kca/gate';
  static const kcaEnroll = '/kca/enroll';
  static const kcaModules = '/kca/modules';
  static const kcaModule = '/kca/module';
  static const kcaLesson = '/kca/lesson';
  static const kcaAssignments = '/kca/assignments';
  static const kcaMentor = '/kca/mentor';

  static const press = '/press';
  static const pressBook = '/press/book';

  static const events = '/events';
  static const eventDetail = '/events/detail';
  static const prayer = '/prayer';
  static const prayerNew = '/prayer/new';
  static const give = '/give';
  static const giveHistory = '/give/history';
  static const live = '/fellowship/live';
  static const sermons = '/sermons';
  static const groups = '/groups';
  static const bible = '/bible';
  static const media = '/media';

  static const tabs = <String>[hub, modules, discover, messages, profile];
}

void fhcGo(BuildContext context, String route) =>
    Navigator.of(context).pushReplacementNamed(route);

void fhcPush(BuildContext context, String route) =>
    Navigator.of(context).pushNamed(route);

void fhcTab(BuildContext context, int index) {
  if (index < 0 || index >= FhcRoutes.tabs.length) return;
  fhcGo(context, FhcRoutes.tabs[index]);
}

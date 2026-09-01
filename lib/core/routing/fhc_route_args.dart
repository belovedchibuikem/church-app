import 'package:flutter/widgets.dart';

/// Typed route arguments that preserve entity IDs across canonicalization.
///
/// Deep links such as `/discover/church/{ulid}` resolve to the `/church/detail`
/// screen template while keeping `{ulid}` available to loaders and guards.
@immutable
final class FhcRouteArgs {
  const FhcRouteArgs({
    this.entityId,
    this.secondaryId,
    this.extra,
  });

  /// Primary resource id (church, event, crusade, payment, etc.).
  final String? entityId;

  /// Optional nested id (e.g. assignment under a module).
  final String? secondaryId;

  /// Caller-supplied arguments merged from [RouteSettings.arguments].
  final Object? extra;

  bool get hasEntityId => entityId != null && entityId!.isNotEmpty;

  static FhcRouteArgs? maybeOf(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return from(args);
  }

  static FhcRouteArgs? from(Object? arguments) {
    if (arguments is FhcRouteArgs) return arguments;
    if (arguments is String && arguments.trim().isNotEmpty) {
      return FhcRouteArgs(entityId: arguments.trim(), extra: arguments);
    }
    if (arguments is Map) {
      final id = arguments['entityId'] ?? arguments['id'];
      if (id is String && id.isNotEmpty) {
        return FhcRouteArgs(
          entityId: id,
          secondaryId: arguments['secondaryId'] as String?,
          extra: arguments,
        );
      }
    }
    return null;
  }

  /// Reads the entity id from route args, falling back to parsing [routeName].
  static String? entityIdOf(
    BuildContext context, {
    String? routeName,
  }) {
    final fromArgs = maybeOf(context)?.entityId;
    if (fromArgs != null && fromArgs.isNotEmpty) return fromArgs;
    final name = routeName ?? ModalRoute.of(context)?.settings.name;
    if (name == null) return null;
    return resolveCanonicalRoute(name).entityId;
  }
}

/// Result of mapping a requested deep-link path to a registered screen route
/// without dropping the entity ULID/slug.
@immutable
final class CanonicalRoute {
  const CanonicalRoute({
    required this.canonical,
    this.entityId,
    this.secondaryId,
  });

  final String canonical;
  final String? entityId;
  final String? secondaryId;
}

/// Maps aliases and parameterized paths to registered screen templates while
/// preserving entity IDs for detail loaders.
CanonicalRoute resolveCanonicalRoute(String requestedRoute) {
  final pathOnly = requestedRoute.split('?').first;
  final alias = switch (pathOnly) {
    '/onboarding' => '/onboarding/discover',
    '/setup/language' || '/setup/location' => '/language',
    '/auth/login' => '/sign-in',
    '/auth/register' => '/sign-up',
    '/auth/recovery' || '/forgot-password' => '/forgot-password',
    '/reset-password' => '/reset-password',
    '/auth/verify-phone' => '/verify-phone',
    '/auth/mfa' => '/2fa',
    '/setup/role' => '/role-selection',
    '/home' => '/hub',
    '/discover/churches' => '/discover',
    '/discover/map' => '/map',
    '/home-church/dashboard' => '/home-church',
    '/online-church/live' => '/fellowship/live',
    '/online-church/sermons' => '/sermons',
    '/online-church/bible-study' => '/press/devotionals',
    '/online-church/prayer' => '/prayer',
    '/mission/crusades' => '/mission/crusade',
    '/mission/follow-up' => '/mission/souls',
    '/kca/application' => '/kca/enroll',
    '/kca/dashboard' => '/kca',
    '/press/library' => '/press',
    '/press/player' => '/press/audio',
    '/press/downloads' => '/downloads',
    '/giving' => '/give',
    '/payments' => '/payments/history',
    '/settings/security' => '/settings/sessions',
    '/settings/preferences' => '/settings/communications',
    _ => null,
  };
  if (alias != null) return CanonicalRoute(canonical: alias);

  final segments = pathOnly
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  CanonicalRoute? parameterized(List<String> parts) {
    if (parts.length >= 3 && parts[0] == 'discover' && parts[1] == 'church') {
      return CanonicalRoute(canonical: '/church/detail', entityId: parts[2]);
    }
    if (parts.length >= 3 && parts[0] == 'church' && parts[1] == 'detail') {
      return CanonicalRoute(canonical: '/church/detail', entityId: parts[2]);
    }
    if (parts.length >= 3 &&
        parts[0] == 'discover' &&
        parts[1] == 'home-church') {
      return CanonicalRoute(canonical: '/home-church', entityId: parts[2]);
    }
    if (parts.length >= 3 && parts[0] == 'discover' && parts[1] == 'mission') {
      return CanonicalRoute(
        canonical: '/map/mission-location',
        entityId: parts[2],
      );
    }
    if (parts.length >= 3 && parts[0] == 'mission' && parts[1] == 'crusade') {
      return CanonicalRoute(
        canonical: '/mission/crusade',
        entityId: parts[2],
      );
    }
    if (parts.length >= 3 && parts[0] == 'mission' && parts[1] == 'soul') {
      return CanonicalRoute(
        canonical: '/mission/souls/profile',
        entityId: parts[2],
      );
    }
    if (parts.length >= 3 && parts[0] == 'kca' && parts[1] == 'lesson') {
      return CanonicalRoute(canonical: '/kca/lesson', entityId: parts[2]);
    }
    if (parts.length >= 3 && parts[0] == 'kca' && parts[1] == 'chapter') {
      return CanonicalRoute(canonical: '/kca/chapter', entityId: parts[2]);
    }
    if (parts.length >= 3 && parts[0] == 'kca' && parts[1] == 'module') {
      return CanonicalRoute(canonical: '/kca/module', entityId: parts[2]);
    }
    if (parts.length >= 3 && parts[0] == 'kca' && parts[1] == 'assignment') {
      return CanonicalRoute(
        canonical: '/kca/assignments',
        entityId: parts[2],
      );
    }
    if (parts.length >= 3 &&
        parts[0] == 'press' &&
        parts[1] == 'publication') {
      return CanonicalRoute(canonical: '/press/resource', entityId: parts[2]);
    }
    if (parts.length >= 3 && parts[0] == 'press' && parts[1] == 'book') {
      return CanonicalRoute(canonical: '/press/book', entityId: parts[2]);
    }
    if (parts.isNotEmpty && parts[0] == 'events') {
      if (parts.length == 1) {
        return const CanonicalRoute(canonical: '/events');
      }
      if (parts.length >= 3 && parts[2] == 'register') {
        return CanonicalRoute(canonical: '/events/register', entityId: parts[1]);
      }
      if (parts.length >= 3 && parts[2] == 'ticket') {
        return CanonicalRoute(canonical: '/events/tickets', entityId: parts[1]);
      }
      // Exact registered paths without an entity segment.
      if (parts.length == 2 &&
          const {
            'detail',
            'register',
            'payment',
            'tickets',
            'attendance',
            'feedback',
          }.contains(parts[1])) {
        return CanonicalRoute(canonical: '/events/${parts[1]}');
      }
      return CanonicalRoute(canonical: '/events/detail', entityId: parts[1]);
    }
    if (parts.isNotEmpty && parts[0] == 'payments') {
      if (parts.length >= 3 && parts[2] == 'receipt') {
        return CanonicalRoute(
          canonical: '/payments/receipt',
          entityId: parts[1],
        );
      }
      if (parts.length == 2 &&
          const {
            'receipt',
            'history',
            'transaction',
            'pending',
            'refund',
            'dispute',
            'processing',
            'success',
            'failed',
          }.contains(parts[1])) {
        return CanonicalRoute(canonical: '/payments/${parts[1]}');
      }
      if (parts.length >= 3 && parts[1] == 'receipt' && parts[2] == 'share') {
        return const CanonicalRoute(canonical: '/payments/receipt/share');
      }
      if (parts.length >= 2) {
        return CanonicalRoute(
          canonical: '/payments/transaction',
          entityId: parts[1],
        );
      }
    }
    if (parts.isNotEmpty && parts[0] == 'bible') {
      if (parts.length == 1) {
        return const CanonicalRoute(canonical: '/bible');
      }
      if (parts[1] == 'plans') {
        return const CanonicalRoute(canonical: '/bible/plans');
      }
      if (parts[1] == 'read' && parts.length >= 3) {
        return CanonicalRoute(
          canonical: '/bible/read',
          entityId: parts.length > 2 ? parts[2] : null,
          secondaryId: parts.length > 3 ? parts[3] : null,
        );
      }
      if (parts.length >= 3) {
        return CanonicalRoute(
          canonical: '/bible/read',
          entityId: parts[1],
          secondaryId: parts[2],
        );
      }
    }
    if (parts.length >= 2 && parts[0] == 'messages') {
      return CanonicalRoute(canonical: '/messages', entityId: parts[1]);
    }
    return null;
  }

  final match = parameterized(segments);
  if (match != null) return match;

  return CanonicalRoute(canonical: pathOnly);
}

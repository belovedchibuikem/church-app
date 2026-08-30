import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/di/app_services_scope.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/launch/app_launch_scope.dart';
import '../../../../shared/widgets/fhc_brand_logo.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

/// Branded launch gate. The progress bar fills, then the next screen opens
/// on its own — no tap required.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _started = false;
  bool _routing = false;
  String? _nextRoute;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    final store = AppLaunchScope.maybeOf(context);
    final duration =
        store?.splashDuration ?? const Duration(milliseconds: 1800);

    // Resolve the destination while the bar fills so we do not stall at 100%.
    unawaited(_resolveNextRoute());

    if (duration == Duration.zero) {
      await _resolveNextRoute();
      await _goNext();
      return;
    }

    _progress.duration = duration;
    _fallback = Timer(duration + const Duration(milliseconds: 200), _goNext);
    await _progress.forward();
    await _goNext();
  }

  Future<void> _resolveNextRoute() async {
    if (_nextRoute != null) return;
    final launch = AppLaunchScope.maybeOf(context);
    if (launch != null && !launch.isHydrated) {
      await launch.hydrate();
    }
    if (!mounted) return;

    final services = AppServicesScope.maybeOf(context);
    var hasSession = false;
    final auth = services?.authRepository;
    final tokenStore = services?.tokenStore;

    if (tokenStore != null) {
      try {
        final access = await tokenStore.readAccessToken();
        final refresh = await tokenStore.readRefreshToken();
        final hadTokens =
            (access != null && access.isNotEmpty) ||
            (refresh != null && refresh.isNotEmpty);

        if (auth != null && refresh != null && refresh.isNotEmpty) {
          // Refresh before routing so PermissionGuard does not treat an
          // expired access token as signed-out while refresh remains valid.
          final restored = await auth.restoreSession();
          if (!mounted) return;
          switch (restored) {
            case AppSuccess():
              hasSession = true;
            case AppError(:final failure):
              // Network/server errors must not wipe a still-valid local session.
              hasSession =
                  hadTokens && failure is! UnauthorizedFailure;
          }
        } else {
          hasSession = hadTokens;
        }

        if (hasSession) {
          await services?.authorizationGateway.prefetchCapabilities();
        }
      } catch (_) {
        hasSession = false;
      }
    }

    if (!mounted) return;
    _nextRoute =
        launch?.nextRoute(hasSession: hasSession) ?? '/onboarding/discover';
  }

  Future<void> _goNext() async {
    if (_routing || !mounted) return;
    _routing = true;
    _fallback?.cancel();
    if (_nextRoute == null) {
      await _resolveNextRoute();
    }
    if (!mounted) return;
    fhcReset(context, _nextRoute ?? '/onboarding/discover');
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 3),
            const FhcBrandLogo(size: 168, hero: true),
            const SizedBox(height: 22),
            Text(
              fhcT(context, 'mobile.familyHouse', fallback: 'FAMILY HOUSE'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FhcColors.navy,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.05,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fhcT(context, 'mobile.connect', fallback: 'CONNECT'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FhcColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              fhcT(
                context,
                'splash.churchName',
                fallback: "The Family House of God Int'l",
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FhcColors.teal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fhcT(
                context,
                'splash.tagline',
                fallback: 'Reaching the World With the Love of Christ',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FhcColors.muted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const Spacer(flex: 2),
            AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                return Column(
                  children: [
                    Text(
                      fhcT(context, 'common.loading', fallback: 'Loading…'),
                      style: const TextStyle(
                        color: FhcColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progress.value.clamp(0.08, 1),
                        minHeight: 3,
                        backgroundColor: FhcColors.gold.withValues(alpha: 0.16),
                        color: FhcColors.gold,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

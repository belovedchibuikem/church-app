import 'package:flutter/material.dart';

import '../../core/design_system/fhc_tokens.dart';
import '../../core/l10n/locale_scope.dart';
import 'offline_controller.dart';

final class OfflineScope extends InheritedNotifier<OfflineController> {
  const OfflineScope({
    super.key,
    required OfflineController controller,
    required super.child,
  }) : super(notifier: controller);

  static OfflineController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OfflineScope>()?.notifier;
  }
}

class OfflineBannerHost extends StatelessWidget {
  const OfflineBannerHost({
    super.key,
    required this.child,
    this.enabled = true,
    this.navigatorKey,
  });

  final Widget child;
  final bool enabled;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final controller = OfflineScope.maybeOf(context);
    if (!enabled || controller == null) return child;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.showOfflineBanner) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: FhcColors.navy,
                child: SafeArea(
                  bottom: false,
                  child: InkWell(
                    onTap: () {
                      navigatorKey?.currentState?.pushNamed('/offline');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            color: FhcColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.pendingCount > 0
                                  ? fhcT(
                                    context,
                                    'account.offlineBannerQueued',
                                    fallback:
                                        'You’re offline. ${controller.pendingCount} item(s) waiting to sync.',
                                  )
                                  : fhcT(
                                    context,
                                    'account.offlineBanner',
                                    fallback:
                                        'You’re offline. Downloaded content stays available.',
                                  ),
                              style: const TextStyle(
                                color: FhcColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            fhcT(
                              context,
                              'account.view',
                              fallback: 'View',
                            ),
                            style: const TextStyle(
                              color: FhcColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

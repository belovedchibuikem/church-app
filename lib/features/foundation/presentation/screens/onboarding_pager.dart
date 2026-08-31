import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../onboarding_actions.dart';
import 'onboarding_connect_screen.dart';
import 'onboarding_discover_screen.dart';
import 'onboarding_multiply_screen.dart';

class OnboardingPager extends StatefulWidget {
  const OnboardingPager({super.key, this.initialPage = 0});

  final int initialPage;

  static const routes = [
    '/onboarding/discover',
    '/onboarding/connect',
    '/onboarding/multiply',
  ];

  @override
  State<OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<OnboardingPager> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, 2);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final next = page.clamp(0, 2);
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_page >= 2) {
      fhcCompleteOnboarding(context);
      return;
    }
    _goTo(_page + 1);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              key: const ValueKey('onboarding-page-view'),
              controller: _controller,
              onPageChanged: (index) => setState(() => _page = index),
              children: const [
                OnboardingDiscoverScreen(embedded: true),
                OnboardingConnectScreen(embedded: true),
                OnboardingMultiplyScreen(embedded: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => fhcCompleteOnboarding(context),
                    style: TextButton.styleFrom(
                      foregroundColor: FhcColors.muted,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      fhcT(context, 'common.skip', fallback: 'Skip'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: FhcColors.muted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (var i = 0; i < 3; i++)
                    Semantics(
                      button: true,
                      selected: i == _page,
                      label: fhcT(
                        context,
                        'onboarding.slideNumber',
                        args: {'number': '${i + 1}'},
                        fallback: 'Onboarding slide {number}',
                      ),
                      child: GestureDetector(
                        key: ValueKey('onboarding-dot-$i'),
                        onTap: () => _goTo(i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 12,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: i == _page ? 9 : 7,
                            height: i == _page ? 9 : 7,
                            decoration: BoxDecoration(
                              color: i == _page ? FhcColors.green : FhcColors.border,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: _next,
                    tooltip: fhcT(context, 'common.next', fallback: 'Next'),
                    style: IconButton.styleFrom(
                      backgroundColor: FhcColors.green,
                      foregroundColor: FhcColors.white,
                      minimumSize: const Size(52, 52),
                      maximumSize: const Size(52, 52),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

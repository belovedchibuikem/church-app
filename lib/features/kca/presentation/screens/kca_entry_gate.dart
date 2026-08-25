import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class KcaEntryGate extends StatelessWidget {
  const KcaEntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          FhcTopBar(title: 'KCA', onBack: () => fhcGo(context, FhcRoutes.hub)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(Icons.school, size: 64, color: FhcColors.kca),
                  const SizedBox(height: 16),
                  const Text(
                    'Kingdom Change Agents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: FhcColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enroll to begin the journey, or continue if you are already a student.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: FhcColors.muted,
                    ),
                  ),
                  const Spacer(),
                  FhcPrimaryButton(
                    label: 'Enroll Now',
                    color: FhcColors.kca,
                    onPressed: () => fhcGo(context, FhcRoutes.kcaEnroll),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => fhcGo(context, FhcRoutes.kca),
                    style: TextButton.styleFrom(
                      foregroundColor: FhcColors.kca,
                      minimumSize: const Size(88, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Continue to dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

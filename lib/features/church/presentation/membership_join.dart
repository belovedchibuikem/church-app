import 'package:flutter/material.dart';

import '../../../../core/api/app_failure.dart';
import '../../../../core/l10n/locale_scope.dart';

bool isMembershipTransferRequired(AppFailure failure) {
  return failure is ConflictFailure &&
      (failure.code == 'MEMBERSHIP_TRANSFER_REQUIRED' ||
          failure.message.toLowerCase().contains('confirm to move'));
}

Future<bool> confirmMembershipTransfer(
  BuildContext context,
  AppFailure failure,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          fhcT(
            context,
            'church.confirmTransferTitle',
            fallback: 'Move your membership?',
          ),
        ),
        content: Text(
          failure.message.isNotEmpty
              ? failure.message
              : fhcT(
                  context,
                  'church.confirmTransferBody',
                  fallback:
                      'You already belong to another church. Confirm to move your membership. Home church and conventional church memberships are kept separately.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(fhcT(context, 'common.cancel', fallback: 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              fhcT(context, 'church.confirmTransfer', fallback: 'Confirm & join'),
            ),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

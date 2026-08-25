import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../../../foundation/presentation/fhc_nav.dart';

class GivingHistoryScreen extends StatelessWidget {
  const GivingHistoryScreen({super.key});

  static const _gifts = <_Gift>[
    _Gift(
      category: 'Tithes & Offering',
      date: 'May 20, 2025',
      amount: 'N20,000',
      icon: Icons.volunteer_activism_outlined,
    ),
    _Gift(
      category: 'Building Fund',
      date: 'May 13, 2025',
      amount: 'N15,000',
      icon: Icons.apartment_outlined,
    ),
    _Gift(
      category: 'Tithes & Offering',
      date: 'May 6, 2025',
      amount: 'N20,000',
      icon: Icons.volunteer_activism_outlined,
    ),
    _Gift(
      category: 'Missions',
      date: 'Apr 29, 2025',
      amount: 'N10,000',
      icon: Icons.public,
    ),
    _Gift(
      category: 'Tithes & Offering',
      date: 'Apr 22, 2025',
      amount: 'N20,000',
      icon: Icons.volunteer_activism_outlined,
    ),
  ];

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      fhcGo(context, FhcRoutes.give);
    }
  }

  void _openReceipt(BuildContext context) {
    fhcPush(context, FhcRoutes.give);
  }

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.canvas,
      child: Column(
        children: [
          FhcTopBar(
            title: 'Giving History',
            onBack: () => _goBack(context),
            trailing: const _AllTimeTrailing(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                const _SummaryCard(),
                const SizedBox(height: 14),
                FhcSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < _gifts.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: FhcColors.border),
                        _GiftRow(
                          gift: _gifts[i],
                          onReceipt: () => _openReceipt(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FhcBottomNavigation(selected: 1),
        ],
      ),
    );
  }
}

class _Gift {
  const _Gift({
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
  });

  final String category;
  final String date;
  final String amount;
  final IconData icon;
}

class _AllTimeTrailing extends StatelessWidget {
  const _AllTimeTrailing();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'All Time',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All Time',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: FhcColors.muted,
                height: 1.1,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: FhcColors.muted),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FhcRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FhcColors.green, FhcColors.greenDark],
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Given',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FhcColors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'N125,000',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.white,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '12 Transactions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: FhcColors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FhcRadius.sm),
              border: Border.all(
                color: FhcColors.white.withValues(alpha: 0.55),
              ),
            ),
            child: const Icon(
              Icons.card_giftcard_outlined,
              color: FhcColors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRow extends StatelessWidget {
  const _GiftRow({required this.gift, required this.onReceipt});

  final _Gift gift;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FhcColors.mint,
              borderRadius: BorderRadius.circular(FhcRadius.sm),
            ),
            child: Icon(gift.icon, color: FhcColors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  gift.date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: FhcColors.muted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            gift.amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FhcColors.ink,
              height: 1.2,
            ),
          ),
          SizedBox(
            width: FhcSizes.minTap,
            height: FhcSizes.minTap,
            child: IconButton(
              onPressed: onReceipt,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              color: FhcColors.muted,
              tooltip: 'Receipt',
            ),
          ),
        ],
      ),
    );
  }
}

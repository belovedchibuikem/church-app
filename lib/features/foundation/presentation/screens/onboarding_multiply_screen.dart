import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class OnboardingMultiplyScreen extends StatelessWidget {
  const OnboardingMultiplyScreen({super.key});

  static const _photoAsset = 'assets/images/multiply_home.png';

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Text(
            'MULTIPLY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: FhcColors.greenDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Start a Church\nin Your Home',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 1.12,
                fontWeight: FontWeight.w700,
                color: FhcColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You can begin gathering people in the name of '
              'Jesus right where you are. We will guide, support '
              'and equip you every step of the way.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: FhcColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _LivingRoomPhoto(asset: _photoAsset),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x66000000),
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                const Center(child: _GoldLogoOverlay()),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          () => fhcGo(context, FhcRoutes.homeChurchStart),
                      style: FilledButton.styleFrom(
                        backgroundColor: FhcColors.green,
                        foregroundColor: FhcColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FhcRadius.button),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'START A CHURCH IN YOUR HOME',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.35,
                            color: FhcColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: _MultiplyFooter(),
          ),
        ],
      ),
    );
  }
}

class _LivingRoomPhoto extends StatelessWidget {
  const _LivingRoomPhoto({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.12),
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF4A3428)),
    );
  }
}

class _GoldLogoOverlay extends StatelessWidget {
  const _GoldLogoOverlay();

  @override
  Widget build(BuildContext context) {
    const size = 92.0;
    return const IgnorePointer(
      child: Opacity(
        opacity: 0.78,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            size: Size.square(size),
            painter: _GoldHouseLogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _GoldHouseLogoPainter extends CustomPainter {
  const _GoldHouseLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke =
        Paint()
          ..color = FhcColors.gold.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.062
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    canvas.drawCircle(Offset(cx, h / 2), w * 0.46, stroke);

    final roofRun = w * 0.28;
    final peak = Offset(cx, h * 0.22);
    final leftEave = Offset(cx - roofRun, h * 0.42);
    final rightEave = Offset(cx + roofRun, h * 0.42);
    final floorY = h * 0.78;
    final house =
        Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(rightEave.dx, rightEave.dy)
          ..lineTo(rightEave.dx, floorY)
          ..lineTo(leftEave.dx, floorY)
          ..lineTo(leftEave.dx, leftEave.dy)
          ..close();
    canvas.drawPath(house, stroke);
    canvas.drawLine(Offset(cx, h * 0.48), Offset(cx, h * 0.70), stroke);
    canvas.drawLine(
      Offset(cx - w * 0.10, h * 0.56),
      Offset(cx + w * 0.10, h * 0.56),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MultiplyFooter extends StatelessWidget {
  const _MultiplyFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          TextButton(
            onPressed: () => fhcGo(context, '/language'),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: FhcColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          for (var i = 0; i < 4; i++)
            Container(
              width: i == 2 ? 9 : 7,
              height: i == 2 ? 9 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              decoration: BoxDecoration(
                color: i == 2 ? FhcColors.green : FhcColors.border,
                shape: BoxShape.circle,
              ),
            ),
          const Spacer(),
          IconButton.filled(
            onPressed: () => fhcGo(context, FhcRoutes.homeChurchStart),
            style: IconButton.styleFrom(
              backgroundColor: FhcColors.green,
              foregroundColor: FhcColors.white,
              minimumSize: const Size(52, 52),
              maximumSize: const Size(52, 52),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_forward, size: 22),
          ),
        ],
      ),
    );
  }
}

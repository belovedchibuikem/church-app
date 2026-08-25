import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.midnight,
      darkStatusBar: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ExcludeSemantics(child: _SplashMapBackdrop()),
          const ExcludeSemantics(child: _SplashForeground()),
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Continue to onboarding',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => fhcGo(context, '/onboarding/discover'),
                child: const ColoredBox(color: Color(0x00000000)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleImage extends StatefulWidget {
  const _BundleImage({
    required this.asset,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  final String asset;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  @override
  State<_BundleImage> createState() => _BundleImageState();
}

class _BundleImageState extends State<_BundleImage> {
  static final Map<String, bool> _present = {};
  bool? _available;

  @override
  void initState() {
    super.initState();
    final cached = _present[widget.asset];
    if (cached != null) {
      _available = cached;
      return;
    }
    _probe();
  }

  Future<void> _probe() async {
    var available = false;
    try {
      await rootBundle.load(widget.asset);
      available = true;
    } catch (_) {
      available = false;
    }
    _present[widget.asset] = available;
    if (mounted) {
      setState(() => _available = available);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) {
      return widget.fallback;
    }
    return Image.asset(
      widget.asset,
      fit: widget.fit,
      alignment: widget.alignment,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, __, ___) => widget.fallback,
    );
  }
}

class _SplashMapBackdrop extends StatelessWidget {
  const _SplashMapBackdrop();

  static const _asset = 'assets/images/splash_map.png';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.42;
    const fallback = CustomPaint(
      painter: _WorldMapPainter(),
      child: SizedBox.expand(),
    );
    final map = _BundleImage(
      asset: _asset,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      fallback: fallback,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            map,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00001823),
                    Color(0x66001823),
                    FhcColors.midnight,
                  ],
                  stops: [0.42, 0.78, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashForeground extends StatelessWidget {
  const _SplashForeground();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: _BrandBlock()),
          ),
        ),
        _LoadingFooter(),
        SizedBox(height: 28),
      ],
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FhcLogo(size: 96),
        SizedBox(height: 18),
        Text(
          'FAMILY HOUSE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.05,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'CONNECT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FhcColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: 9,
          ),
        ),
        SizedBox(height: 34),
        Text(
          'One House. Many Nations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'One Kingdom. One Mission.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        SizedBox(height: 22),
        Text(
          'Matthew 28:19-20 (KJV)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FhcColors.gold,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FhcLogo extends StatelessWidget {
  const _FhcLogo({required this.size});

  final double size;
  static const _asset = 'assets/images/fhc_logo.png';

  @override
  Widget build(BuildContext context) {
    final mark = _BundleImage(
      asset: _asset,
      width: size,
      height: size,
      fallback: CustomPaint(
        size: Size.square(size),
        painter: const _HouseCrossLogoPainter(),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FhcColors.gold.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: mark,
      ),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Loading...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 156,
          height: 3,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: FhcColors.gold.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Container(
            width: 56,
            height: 3,
            decoration: BoxDecoration(
              color: FhcColors.gold,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

class _HouseCrossLogoPainter extends CustomPainter {
  const _HouseCrossLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke =
        Paint()
          ..color = FhcColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.068
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final roofRun = w * 0.40;
    final roofRise = roofRun * math.tan(math.pi / 5.2);
    final peak = Offset(cx, h * 0.08);
    final leftEave = Offset(cx - roofRun, peak.dy + roofRise);
    final rightEave = Offset(cx + roofRun, peak.dy + roofRise);
    final floorY = h * 0.90;
    final house =
        Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(rightEave.dx, rightEave.dy)
          ..lineTo(rightEave.dx, floorY)
          ..lineTo(leftEave.dx, floorY)
          ..lineTo(leftEave.dx, leftEave.dy)
          ..close();
    canvas.drawPath(house, stroke);

    final crossTop = Offset(cx, h * 0.46);
    final crossBottom = Offset(cx, h * 0.78);
    final arm = w / (2 * math.sqrt(2));
    canvas.drawLine(crossTop, crossBottom, stroke);
    canvas.drawLine(
      Offset(cx - arm * 0.46, h * 0.58),
      Offset(cx + arm * 0.46, h * 0.58),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WorldMapPainter extends CustomPainter {
  const _WorldMapPainter();

  static const _nodes = <Offset>[
    Offset(0.08, 0.22),
    Offset(0.14, 0.30),
    Offset(0.18, 0.18),
    Offset(0.22, 0.36),
    Offset(0.27, 0.26),
    Offset(0.30, 0.48),
    Offset(0.24, 0.58),
    Offset(0.33, 0.70),
    Offset(0.29, 0.82),
    Offset(0.42, 0.20),
    Offset(0.48, 0.28),
    Offset(0.54, 0.18),
    Offset(0.52, 0.40),
    Offset(0.46, 0.50),
    Offset(0.56, 0.56),
    Offset(0.50, 0.68),
    Offset(0.58, 0.78),
    Offset(0.64, 0.24),
    Offset(0.70, 0.16),
    Offset(0.76, 0.28),
    Offset(0.82, 0.20),
    Offset(0.88, 0.32),
    Offset(0.72, 0.42),
    Offset(0.80, 0.48),
    Offset(0.68, 0.58),
    Offset(0.86, 0.62),
    Offset(0.78, 0.72),
    Offset(0.90, 0.78),
    Offset(0.60, 0.36),
    Offset(0.38, 0.34),
  ];

  static const _routes = <(int, int)>[
    (0, 1),
    (1, 2),
    (1, 3),
    (2, 4),
    (3, 4),
    (3, 5),
    (5, 6),
    (6, 7),
    (7, 8),
    (4, 9),
    (9, 10),
    (10, 11),
    (10, 12),
    (12, 13),
    (12, 14),
    (13, 15),
    (14, 16),
    (11, 17),
    (17, 18),
    (18, 19),
    (19, 20),
    (20, 21),
    (17, 22),
    (19, 23),
    (22, 24),
    (23, 25),
    (24, 26),
    (25, 27),
    (12, 28),
    (4, 29),
    (29, 10),
    (5, 13),
    (14, 24),
    (3, 29),
    (21, 23),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final glow =
        Paint()
          ..color = FhcColors.gold.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final line =
        Paint()
          ..color = FhcColors.gold.withValues(alpha: 0.22)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke;
    final hub = Paint()..color = FhcColors.gold.withValues(alpha: 0.55);
    final dot = Paint()..color = FhcColors.gold.withValues(alpha: 0.34);

    Offset point(int i) =>
        Offset(_nodes[i].dx * size.width, _nodes[i].dy * size.height);

    for (final route in _routes) {
      canvas.drawLine(point(route.$1), point(route.$2), line);
    }
    for (var i = 0; i < _nodes.length; i++) {
      final p = point(i);
      final isHub = i == 4 || i == 10 || i == 19 || i == 5 || i == 22;
      final halo = (isHub ? 6.4 : 3.8) + math.sin(i * 0.85) * 0.8;
      canvas.drawCircle(p, halo, glow);
      canvas.drawCircle(p, isHub ? 2.4 : 1.35, isHub ? hub : dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

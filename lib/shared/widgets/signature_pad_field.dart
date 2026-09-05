import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/design_system/fhc_tokens.dart';

class SignaturePadField extends StatefulWidget {
  const SignaturePadField({
    super.key,
    required this.label,
    this.onChanged,
    this.hintText = 'Draw your signature inside the box.',
    this.height = 140,
  });

  final String label;
  final ValueChanged<Uint8List?>? onChanged;
  final String hintText;
  final double height;

  @override
  State<SignaturePadField> createState() => _SignaturePadFieldState();
}

class _SignaturePadFieldState extends State<SignaturePadField> {
  final List<Offset?> _points = <Offset?>[];
  Size _paintSize = Size.zero;

  bool get _hasInk => _points.any((point) => point != null);

  Future<void> _emitSignature() async {
    final listener = widget.onChanged;
    if (listener == null) return;
    if (!_hasInk || _paintSize.width <= 0 || _paintSize.height <= 0) {
      listener(null);
      return;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Rect.fromLTWH(0, 0, _paintSize.width, _paintSize.height);
    canvas.drawRect(bounds, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < _points.length - 1; i++) {
      final current = _points[i];
      final next = _points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }

    final image = await recorder
        .endRecording()
        .toImage(_paintSize.width.ceil(), _paintSize.height.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    listener(byteData?.buffer.asUint8List());
  }

  void _clear() {
    setState(_points.clear);
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: FhcTypography.label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FhcColors.border),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  _paintSize = Size(
                    constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
                    widget.height,
                  );
                  return GestureDetector(
                    onPanStart: (details) => setState(() {
                      _points.add(details.localPosition);
                    }),
                    onPanUpdate: (details) => setState(() {
                      _points.add(details.localPosition);
                    }),
                    onPanEnd: (_) {
                      setState(() => _points.add(null));
                      _emitSignature();
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(_points),
                      size: _paintSize,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.hintText,
                        style: FhcTypography.caption,
                      ),
                    ),
                    TextButton(
                      onPressed: _hasInk ? _clear : null,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), background);

    final line = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

import 'package:flutter/material.dart';

import '../theme.dart';

/// Playful flat illustration: a little sage car, a peach scooter,
/// sun and clouds — drawn with shapes, no images needed.
class TravelIllustration extends StatelessWidget {
  const TravelIllustration({super.key, this.height = 190});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _TravelPainter()),
    );
  }
}

class _TravelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sun
    final sun = Paint()..color = HopColors.peach;
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), 26, sun);
    final sunCore = Paint()..color = const Color(0xFFF2B880);
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), 17, sunCore);

    // Clouds
    final cloud = Paint()..color = Colors.white;
    _cloud(canvas, Offset(w * 0.16, h * 0.18), 26, cloud);
    _cloud(canvas, Offset(w * 0.55, h * 0.10), 20, cloud);

    // Ground line
    final ground = Paint()
      ..color = HopColors.sageLight
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.06, h * 0.82), Offset(w * 0.94, h * 0.82),
        ground);
    // Dashes on the road
    final dash = Paint()
      ..color = HopColors.peachDeep
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = w * (0.12 + i * 0.2);
      canvas.drawLine(Offset(x, h * 0.90), Offset(x + 18, h * 0.90), dash);
    }

    // Car
    _car(canvas, Offset(w * 0.30, h * 0.62), w * 0.34);
    // Scooter
    _scooter(canvas, Offset(w * 0.68, h * 0.64), w * 0.20);

    // Little people dots (passengers waving)
    final person = Paint()..color = HopColors.ink;
    canvas.drawCircle(Offset(w * 0.24, h * 0.52), 5, person);
    canvas.drawCircle(Offset(w * 0.76, h * 0.50), 5, person);
  }

  void _cloud(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(Offset(c.dx - r * 0.9, c.dy + r * 0.25), r * 0.7, paint);
    canvas.drawCircle(Offset(c.dx + r * 0.9, c.dy + r * 0.25), r * 0.7, paint);
  }

  void _car(Canvas canvas, Offset origin, double width) {
    final body = Paint()..color = HopColors.sage;
    final bodyH = width * 0.32;
    final bodyW = width;
    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - bodyW / 2, origin.dy, bodyW, bodyH),
        const Radius.circular(14));
    canvas.drawRRect(bodyRect, body);
    // Cabin
    final cabin = Paint()..color = HopColors.sageLight;
    final cabinRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - bodyW * 0.28, origin.dy - bodyH * 0.62,
            bodyW * 0.56, bodyH * 0.66),
        const Radius.circular(12));
    canvas.drawRRect(cabinRect, cabin);
    // Windows
    final window = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(origin.dx - bodyW * 0.20, origin.dy - bodyH * 0.5,
                bodyW * 0.18, bodyH * 0.42),
            const Radius.circular(6)),
        window);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(origin.dx + bodyW * 0.02, origin.dy - bodyH * 0.5,
                bodyW * 0.18, bodyH * 0.42),
            const Radius.circular(6)),
        window);
    // Wheels
    final wheel = Paint()..color = HopColors.ink;
    final hub = Paint()..color = Colors.white;
    for (final dx in [-bodyW * 0.28, bodyW * 0.28]) {
      canvas.drawCircle(
          Offset(origin.dx + dx, origin.dy + bodyH), bodyH * 0.32, wheel);
      canvas.drawCircle(
          Offset(origin.dx + dx, origin.dy + bodyH), bodyH * 0.14, hub);
    }
  }

  void _scooter(Canvas canvas, Offset origin, double width) {
    final body = Paint()
      ..color = HopColors.peachDeep
      ..strokeWidth = width * 0.09
      ..strokeCap = StrokeCap.round;
    // Deck
    canvas.drawLine(Offset(origin.dx - width * 0.45, origin.dy + width * 0.28),
        Offset(origin.dx + width * 0.30, origin.dy + width * 0.28), body);
    // Front fork
    canvas.drawLine(Offset(origin.dx + width * 0.30, origin.dy + width * 0.28),
        Offset(origin.dx + width * 0.42, origin.dy - width * 0.25), body);
    // Handlebar
    canvas.drawLine(Offset(origin.dx + width * 0.30, origin.dy - width * 0.25),
        Offset(origin.dx + width * 0.55, origin.dy - width * 0.25), body);
    // Seat
    final seat = Paint()..color = HopColors.ink;
    canvas.drawLine(Offset(origin.dx - width * 0.42, origin.dy - width * 0.05),
        Offset(origin.dx - width * 0.12, origin.dy - width * 0.05),
        seat..strokeWidth = width * 0.08);
    // Wheels
    final wheel = Paint()..color = HopColors.ink;
    canvas.drawCircle(
        Offset(origin.dx - width * 0.38, origin.dy + width * 0.32),
        width * 0.13,
        wheel);
    canvas.drawCircle(
        Offset(origin.dx + width * 0.38, origin.dy + width * 0.32),
        width * 0.13,
        wheel);
    final hub = Paint()..color = Colors.white;
    canvas.drawCircle(
        Offset(origin.dx - width * 0.38, origin.dy + width * 0.32),
        width * 0.05,
        hub);
    canvas.drawCircle(
        Offset(origin.dx + width * 0.38, origin.dy + width * 0.32),
        width * 0.05,
        hub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

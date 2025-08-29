import 'dart:math' as math;

import 'package:flutter/material.dart';

class MyAppPainter extends StatelessWidget {
  const MyAppPainter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(),
        backgroundColor: const Color(0xFFECE6DF),
        body: Center(
          child: SizedBox(
            width: 360,
            height: 360,
            child: CustomPaint(
              painter: BadgePainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = math.min(size.width, size.height) * 0.46; // outer radius

    // ---------- 1) Scalloped (gear) edge ----------
    _drawGearEdge(canvas, center, baseR, baseR - 16,
        teeth: 84,
        outerColor: const Color(0xFF1A1A1A),
        innerColor: const Color(0xFF1A1A1A));

    // Thin outer stroke
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withOpacity(0.85);
    canvas.drawCircle(center, baseR - 2, stroke);

    // ---------- 2) Inner badge (dark to warm radial) ----------
    final innerR = baseR - 22;
    final inner = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: const [
          Color(0xFF121212),
          Color(0xFF1C1C1C),
          Color(0xFF2A1E12),
          Color(0xFF3B2A18),
          Color(0xFF4B3218),
        ],
        stops: const [0.0, 0.35, 0.6, 0.82, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: innerR));
    canvas.drawCircle(center, innerR, inner);

    // Ring accents
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, innerR * 0.98, ringPaint);
    canvas.drawCircle(center, innerR * 0.82,
        ringPaint..color = Colors.white.withOpacity(0.5));

    // ---------- 3) Radial spokes ----------
    _drawRadialSpokes(canvas, center, innerR * 0.96, innerR * 0.70,
        count: 120, strokeWidth: 1.2, color: Colors.white.withOpacity(0.9));

    // ---------- 4) Dotted ring ----------
    _drawDashes(canvas, center,
        radius: innerR * 0.64,
        dashLen: 3,
        gap: 3.5,
        width: 1.4,
        color: Colors.white.withOpacity(0.85));

    // ---------- 5) Top star ----------
    final starR = innerR * 0.10;
    final starCenter = center + Offset(0, -innerR * 0.44);
    final starPath = _starPath(starCenter, starR, 5, rotate: -math.pi / 2);
    final starPaint = Paint()..color = const Color(0xFFD2A24B);
    canvas.drawPath(starPath, starPaint);
    canvas.drawPath(
      starPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withOpacity(0.6),
    );

    // ---------- 6) Center banner ----------
    final bannerHeight = innerR * 0.42;
    final bannerRect = RRect.fromLTRBR(
      center.dx - innerR * 1.05,
      center.dy - bannerHeight / 2,
      center.dx + innerR * 1.05,
      center.dy + bannerHeight / 2,
      Radius.circular(bannerHeight * 0.35),
    );
    final bannerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFF111111),
          Color(0xFF0D0D0D),
          Color(0xFF111111),
        ],
      ).createShader(bannerRect.outerRect);
    canvas.drawRRect(bannerRect, bannerPaint);

    // Banner stroke
    canvas.drawRRect(
      bannerRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withOpacity(0.9),
    );

    // ---------- 7) Text: BRAND NAME ----------
    _drawText(
      canvas,
      text: 'BRAND NAME',
      center: center.translate(0, -2),
      maxWidth: innerR * 1.7,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 44,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        height: 1.0,
      ),
      shadow: const Shadow(
          blurRadius: 2, offset: Offset(0, 2), color: Colors.black54),
    );

    // ---------- 8) Bottom chip with EST. 1989 ----------
    final bottomArcR = innerR * 0.46;
    final bottomChip = Path()
      ..addArc(Rect.fromCircle(center: center, radius: bottomArcR),
          math.pi * 0.10, math.pi * 0.80)
      ..lineTo(center.dx + bottomArcR * math.cos(math.pi * 0.90),
          center.dy + bottomArcR * math.sin(math.pi * 0.90))
      ..lineTo(center.dx - bottomArcR * math.cos(math.pi * 0.90),
          center.dy + bottomArcR * math.sin(math.pi * 0.90))
      ..close();

    final chipPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF121212), Color(0xFF090909)],
      ).createShader(Rect.fromCircle(center: center, radius: bottomArcR));
    canvas.drawPath(bottomChip, chipPaint);
    canvas.drawPath(
      bottomChip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withOpacity(0.6),
    );

    _drawText(
      canvas,
      text: 'EST. 1989',
      center: center.translate(0, innerR * 0.18),
      maxWidth: innerR * 0.9,
      style: const TextStyle(
        color: Color(0xFFD2A24B),
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        height: 1.0,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  // ----------------- helpers -----------------
  void _drawGearEdge(Canvas canvas, Offset c, double outerR, double innerR,
      {required int teeth,
      required Color outerColor,
      required Color innerColor}) {
    final path = Path();
    final steps = teeth * 2; // out-in-out-in
    for (int i = 0; i <= steps; i++) {
      final t = i / steps * math.pi * 2;
      final r = i.isEven ? outerR : innerR;
      final p = Offset(c.dx + r * math.cos(t), c.dy + r * math.sin(t));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final paint = Paint()..color = outerColor;
    canvas.drawPath(path, paint);

    // subtle inner bevel
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withOpacity(0.15);
    canvas.drawCircle(c, innerR + 2, bevel);
  }

  void _drawRadialSpokes(Canvas canvas, Offset c, double rOuter, double rInner,
      {required int count, required double strokeWidth, required Color color}) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < count; i++) {
      final a = (math.pi * 2) * (i / count);
      final o =
          Offset(c.dx + rInner * math.cos(a), c.dy + rInner * math.sin(a));
      final iPt =
          Offset(c.dx + rOuter * math.cos(a), c.dy + rOuter * math.sin(a));
      canvas.drawLine(o, iPt, p);
    }
  }

  void _drawDashes(Canvas canvas, Offset c,
      {required double radius,
      required double dashLen,
      required double gap,
      required double width,
      required Color color}) {
    final total = (2 * math.pi * radius) / (dashLen + gap);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < total.floor(); i++) {
      final a0 = (i * (dashLen + gap)) / radius;
      final a1 = (i * (dashLen + gap) + dashLen) / radius;
      final p0 =
          Offset(c.dx + radius * math.cos(a0), c.dy + radius * math.sin(a0));
      final p1 =
          Offset(c.dx + radius * math.cos(a1), c.dy + radius * math.sin(a1));
      canvas.drawLine(p0, p1, paint);
    }
  }

  Path _starPath(Offset c, double r, int points, {double rotate = 0}) {
    final path = Path();
    final innerR = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rr = isOuter ? r : innerR;
      final a = rotate + (math.pi / points) * i;
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawText(Canvas canvas,
      {required String text,
      required Offset center,
      required double maxWidth,
      required TextStyle style,
      Shadow? shadow}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(shadows: shadow != null ? [shadow] : null),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    final pos = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, pos);
  }
}

class MyAppPainter2 extends StatelessWidget {
  const MyAppPainter2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(),
        backgroundColor: const Color(0xFFECE6DF),
        body: Center(
          child: SizedBox(
            width: 360,
            height: 360,
            child: CustomPaint(
              painter: QualityBadgePainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class QualityBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    // Outer orange circle
    final outerPaint = Paint()..color = const Color(0xFFF7B52C);
    canvas.drawCircle(center, radius, outerPaint);

    // Inner cream circle
    final innerPaint = Paint()..color = const Color(0xFFF2F0E6);
    canvas.drawCircle(center, radius * 0.88, innerPaint);

    // Text: HIGH QUALITY (arc top)
    _drawArcText(canvas,
        text: "HIGH QUALITY",
        center: center,
        radius: radius * 0.70,
        startAngle: -math.pi * 5 / 6,
        sweepAngle: math.pi * 2 / 3,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0D2C36),
          letterSpacing: 1.5,
        ));

    // Text: GUARANTEED (arc bottom)
    _drawArcText(canvas,
        text: "GUARANTEED",
        center: center,
        radius: radius * 0.70,
        startAngle: math.pi / 6,
        sweepAngle: math.pi * 2 / 3,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0D2C36),
          letterSpacing: 1.5,
        ));

    // Small text EST. and 1949
    _drawText(canvas,
        text: "EST.",
        center: Offset(center.dx - radius * 0.5, center.dy - 10),
        maxWidth: 60,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D2C36),
        ));

    _drawText(canvas,
        text: "1949",
        center: Offset(center.dx + radius * 0.5, center.dy - 10),
        maxWidth: 60,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D2C36),
        ));

    // Big number 89
    _drawText(canvas,
        text: "89",
        center: center.translate(0, 10),
        maxWidth: radius * 1.2,
        style: const TextStyle(
          fontSize: 100,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0D2C36),
          height: 1.0,
        ));

    // Small hat icon (simulate with arc + oval)
    final hatPaint = Paint()..color = const Color(0xFF0D2C36);
    final hatRect = Rect.fromCenter(
        center: center.translate(0, -radius * 0.25), width: 50, height: 18);
    canvas.drawOval(hatRect, hatPaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: center.translate(0, -radius * 0.29), width: 36, height: 20),
        0,
        math.pi,
        true,
        hatPaint);

    // 3 stars under number
    final starR = 10.0;
    for (int i = -1; i <= 1; i++) {
      final starPath =
          _starPath(center.translate(i * 40.0, radius * 0.28), starR, 5);
      canvas.drawPath(starPath, hatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void _drawText(Canvas canvas,
      {required String text,
      required Offset center,
      required double maxWidth,
      required TextStyle style}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final pos = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, pos);
  }

  void _drawArcText(Canvas canvas,
      {required String text,
      required Offset center,
      required double radius,
      required double startAngle,
      required double sweepAngle,
      required TextStyle style}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final totalAngle = sweepAngle;
    final charAngle = totalAngle / text.length;
    for (int i = 0; i < text.length; i++) {
      final angle = startAngle + charAngle * i + charAngle / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 2);
      textPainter.text = TextSpan(text: text[i], style: style);
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  Path _starPath(Offset c, double r, int points) {
    final path = Path();
    final innerR = r * 0.5;
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rr = isOuter ? r : innerR;
      final a = -math.pi / 2 + (math.pi / points) * i;
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }
}

class MyAppPainter3 extends StatelessWidget {
  const MyAppPainter3({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5E9DD),
        body: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: CustomPaint(
              painter: RetroBadgePainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class RetroBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // ---------- Outer scalloped edge ----------
    final scallopOuter = Paint()..color = const Color(0xFF184A63);
    final scallopPath = Path();
    const scallops = 32;
    for (int i = 0; i < scallops; i++) {
      final angle1 = (2 * math.pi / scallops) * i;
      final angle2 = (2 * math.pi / scallops) * (i + 1);
      final p1 = Offset(center.dx + radius * math.cos(angle1),
          center.dy + radius * math.sin(angle1));
      final p2 = Offset(center.dx + radius * math.cos(angle2),
          center.dy + radius * math.sin(angle2));
      if (i == 0) scallopPath.moveTo(p1.dx, p1.dy);
      scallopPath.quadraticBezierTo(center.dx, center.dy, p2.dx, p2.dy);
    }
    scallopPath.close();
    canvas.drawPath(scallopPath, scallopOuter);

    // Inner circle orange
    final innerCirclePaint = Paint()..color = const Color(0xFFF0A868);
    canvas.drawCircle(center, radius * 0.75, innerCirclePaint);

    // Circle border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFF184A63);
    canvas.drawCircle(center, radius * 0.75, borderPaint);

    // Banner background
    final bannerHeight = radius * 0.5;
    final bannerRect = Rect.fromCenter(
        center: center, width: radius * 2.4, height: bannerHeight);
    final bannerRRect = RRect.fromRectAndRadius(bannerRect, Radius.circular(8));
    final bannerPaint = Paint()..color = const Color(0xFF184A63);
    canvas.drawRRect(bannerRRect, bannerPaint);

    // Banner small side triangles
    final leftTri = Path()
      ..moveTo(bannerRect.left, bannerRect.top)
      ..lineTo(bannerRect.left - 30, center.dy)
      ..lineTo(bannerRect.left, bannerRect.bottom)
      ..close();
    canvas.drawPath(leftTri, bannerPaint);

    final rightTri = Path()
      ..moveTo(bannerRect.right, bannerRect.top)
      ..lineTo(bannerRect.right + 30, center.dy)
      ..lineTo(bannerRect.right, bannerRect.bottom)
      ..close();
    canvas.drawPath(rightTri, bannerPaint);

    // Banner text: FIND BADE
    _drawText(canvas,
        text: "FIND BADE",
        center: center,
        maxWidth: radius * 2,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ));

    // Top curved text: LBFIPAER HETVE
    _drawArcText(canvas,
        text: "LBFIPAER HETVE",
        center: center,
        radius: radius * 0.7,
        startAngle: -math.pi * 2 / 3,
        sweepAngle: math.pi * 1.3,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF184A63),
        ));

    // Bottom curved text: BEANGGE
    _drawArcText(canvas,
        text: "BEANGGE",
        center: center,
        radius: radius * 0.7,
        startAngle: math.pi / 4,
        sweepAngle: math.pi / 2,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF184A63),
        ));

    // Central Y shape (green)
    final yPaint = Paint()..color = const Color(0xFF2C7C74);
    final pathY = Path();
    pathY.moveTo(center.dx, center.dy - 40);
    pathY.lineTo(center.dx - 20, center.dy - 10);
    pathY.lineTo(center.dx - 8, center.dy);
    pathY.lineTo(center.dx, center.dy - 20);
    pathY.lineTo(center.dx + 8, center.dy);
    pathY.lineTo(center.dx + 20, center.dy - 10);
    pathY.close();
    canvas.drawPath(pathY, yPaint);

    // Stars inside banner
    final starPaint = Paint()..color = Colors.white;
    final leftStar = _starPath(center.translate(-radius * 0.9, 0), 8, 5);
    final rightStar = _starPath(center.translate(radius * 0.9, 0), 8, 5);
    canvas.drawPath(leftStar, starPaint);
    canvas.drawPath(rightStar, starPaint);

    // Star below circle
    final bottomStar = _starPath(center.translate(0, radius * 0.55), 10, 5);
    canvas.drawPath(bottomStar, Paint()..color = const Color(0xFF184A63));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void _drawText(Canvas canvas,
      {required String text,
      required Offset center,
      required double maxWidth,
      required TextStyle style}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final pos = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    tp.paint(canvas, pos);
  }

  void _drawArcText(Canvas canvas,
      {required String text,
      required Offset center,
      required double radius,
      required double startAngle,
      required double sweepAngle,
      required TextStyle style}) {
    final totalAngle = sweepAngle;
    final charAngle = totalAngle / text.length;
    for (int i = 0; i < text.length; i++) {
      final angle = startAngle + charAngle * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(text: text[i], style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  Path _starPath(Offset c, double r, int points) {
    final path = Path();
    final innerR = r * 0.5;
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final rr = isOuter ? r : innerR;
      final a = -math.pi / 2 + (math.pi / points) * i;
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }
}

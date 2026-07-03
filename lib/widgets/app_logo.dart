import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FormaiLogoMark extends StatelessWidget {
  const FormaiLogoMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _LogoMarkPainter());
  }
}

class _LogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = size.width * 0.11;

    void drawSegment(Offset start, Offset end) {
      canvas.drawLine(start, end, paint);
    }

    drawSegment(
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.45, size.height * 0.49),
    );
    drawSegment(
      Offset(size.width * 0.31, size.height * 0.18),
      Offset(size.width * 0.22, size.height * 0.27),
    );
    drawSegment(
      Offset(size.width * 0.40, size.height * 0.40),
      Offset(size.width * 0.49, size.height * 0.31),
    );

    drawSegment(
      Offset(size.width * 0.56, size.height * 0.59),
      Offset(size.width * 0.84, size.height * 0.87),
    );
    drawSegment(
      Offset(size.width * 0.70, size.height * 0.54),
      Offset(size.width * 0.58, size.height * 0.66),
    );
    drawSegment(
      Offset(size.width * 0.80, size.height * 0.74),
      Offset(size.width * 0.91, size.height * 0.63),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FormaiWordmark extends StatelessWidget {
  const FormaiWordmark({
    super.key,
    this.size = 20,
    this.color = AppColors.limeAlt,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'FORMAI',
      style: TextStyle(
        color: color,
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
        height: 1.4,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class AppBarPainter extends CustomPainter {
  final Color borderColor;
  final AppThemeMode mode;

  AppBarPainter({required this.borderColor, required this.mode});

  @override
  /// Pinta el app bar con gradiente y borde curvo
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: mode == AppThemeMode.dark
            ? [
                Colors.blue.shade900.withOpacity(0.6),
                Colors.blue.shade900.withOpacity(0.2),
              ]
            : [
                Colors.white.withOpacity(0.9),
                Colors.blue.shade300.withOpacity(0.6),
              ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(size.width, size.height, size.width - 20, size.height)
      ..lineTo(20, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 20)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = mode == AppThemeMode.dark
            ? Colors.black.withOpacity(0.5)
            : Colors.transparent,
    );

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(0, size.height - 20)
      ..quadraticBezierTo(0, size.height, 20, size.height)
      ..lineTo(size.width - 20, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - 20,
      );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class NavBarPainter extends CustomPainter {
  final Color borderColor;
  final AppThemeMode mode;

  NavBarPainter({required this.borderColor, required this.mode});

  @override
  /// Pinta el nav bar con gradiente y borde superior
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(0, 0, 20, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = mode == AppThemeMode.dark
            ? Colors.black.withOpacity(0.5)
            : Colors.transparent,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: mode == AppThemeMode.dark
            ? [
                Colors.blue.shade900.withOpacity(0.2),
                Colors.blue.shade900.withOpacity(0.6),
              ]
            : [
                Colors.blue.shade300.withOpacity(0.6),
                Colors.white.withOpacity(0.9),
              ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(0, 0, 20, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class CircularVisualizer extends StatefulWidget {
  final double size;
  final bool isPlaying;
  final Gradient? gradient;
  final Color? color;
  final AppThemeMode mode;

  const CircularVisualizer({
    super.key,
    required this.size,
    required this.isPlaying,
    this.gradient,
    this.color,
    required this.mode,
  });

  @override
  State<CircularVisualizer> createState() => _CircularVisualizerState();
}

class _CircularVisualizerState extends State<CircularVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int barCount = 70;
  List<double> _heights = [];
  List<double> _targetHeights = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _heights = List.generate(barCount, (_) => 5.0);
    _targetHeights = List.generate(barCount, (_) => 5.0);

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))
      ..addListener(() {
        if (mounted) {
          setState(() {
            for (int i = 0; i < barCount; i++) {
               _heights[i] += (_targetHeights[i] - _heights[i]) * 0.4;
            }
          });
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _generateNewHeights();
          _controller.forward(from: 0.0);
        }
      });

    if (widget.isPlaying) _controller.forward();
  }

  void _generateNewHeights() {
    for (int i = 0; i < barCount; i++) {
      if (widget.isPlaying) {
         _targetHeights[i] = 5.0 + _random.nextDouble() * 25.0;
      } else {
         _targetHeights[i] = 5.0; // Idle state
      }
    }
  }

  @override
  void didUpdateWidget(CircularVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _generateNewHeights();
        _controller.forward(from: 0.0);
      } else {
        _generateNewHeights(); 
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _CircularVisualizerPainter(
        heights: _heights,
        baseColor: widget.color ?? Colors.blue,
        gradient: widget.gradient,
      ),
    );
  }
}

class _CircularVisualizerPainter extends CustomPainter {
  final List<double> heights;
  final Color baseColor;
  final Gradient? gradient;

  _CircularVisualizerPainter({
    required this.heights,
    required this.baseColor,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 60) / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    } else {
      paint.color = baseColor;
    }

    final double angleStep = (2 * math.pi) / heights.length;

    for (int i = 0; i < heights.length; i++) {
      final angle = i * angleStep;
      final startOffset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final extendRadius = radius + heights[i];
      final endOffset = Offset(
        center.dx + extendRadius * math.cos(angle),
        center.dy + extendRadius * math.sin(angle),
      );
      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularVisualizerPainter oldDelegate) => true;
}

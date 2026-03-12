// Copyright © 2026 Brayan Medrano - MG Music
// Widget enfocable para TV con soporte de control remoto

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class TvFocusableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final FocusNode? focusNode;
  final bool isSelected;
  final FocusOnKeyEventCallback? onKeyEvent;
  final Color? selectedColor;
  final double focusBorderWidth;

  const TvFocusableItem({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.onKeyEvent,
    this.borderRadius = 12.0,
    this.isSelected = false,
    this.selectedColor,
    this.focusBorderWidth = 4.0,
  });

  @override
  State<TvFocusableItem> createState() => _TvFocusableItemState();
}

class _TvFocusableItemState extends State<TvFocusableItem> {
  bool _isFocused = false;
  Timer? _longPressTimer;

  @override
  /// Cancela temporizadores y libera recursos
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  /// Construye el contenedor enfocable y maneja eventos de teclado
  Widget build(BuildContext context) {
    final mode = context.read<ThemeService>().mode;
    final invertedMode =
        mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        if (widget.onKeyEvent != null) {
          final result = widget.onKeyEvent!(node, event);
          if (result != KeyEventResult.ignored) {
            return result;
          }
        }

        final isSelectKey =
            event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA ||
            event.logicalKey == LogicalKeyboardKey.space;

        if (isSelectKey) {
          if (event is KeyDownEvent) {
            if (_longPressTimer == null) {
              _longPressTimer = Timer(const Duration(milliseconds: 500), () {
                _longPressTimer = null;
                widget.onLongPress?.call();
              });
            }
            return KeyEventResult.handled;
          } else if (event is KeyUpEvent) {
            if (_longPressTimer != null) {
              _longPressTimer!.cancel();
              _longPressTimer = null;
              widget.onTap?.call();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (widget.selectedColor ?? Colors.blue.shade900)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlueMid.withOpacity(0.12),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              if (_isFocused)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GradientBorderPainter(
                        gradient: AppGradients.of(
                          invertedMode,
                          GradientDirection.centerOut,
                        ),
                        radius: widget.borderRadius,
                        width: widget.focusBorderWidth,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final LinearGradient gradient;
  final double radius;
  final double width;

  _GradientBorderPainter({
    required this.gradient,
    required this.radius,
    required this.width,
  });

  @override
  /// Dibuja el borde degradado sin afectar el layout
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  /// Determina si se debe repintar según cambios en propiedades
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.radius != radius ||
        oldDelegate.width != width;
  }
}

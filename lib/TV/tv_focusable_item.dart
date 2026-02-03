// Copyright © 2026 Brayan Medrano - MG Music
// Widget enfocable para TV con soporte de control remoto

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget enfocable con soporte para navegación por control remoto
class TvFocusableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final FocusNode? focusNode;
  final bool isSelected;
  final FocusOnKeyEventCallback? onKeyEvent;

  const TvFocusableItem({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.onKeyEvent,
    this.borderRadius = 12.0,
    this.isSelected = false,
  });

  @override
  State<TvFocusableItem> createState() => _TvFocusableItemState();
}

class _TvFocusableItemState extends State<TvFocusableItem> {
  bool _isFocused = false;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.blue.shade900 : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: _isFocused
              ? Border.all(color: Colors.blue, width: 4)
              : Border.all(color: Colors.transparent, width: 4),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 2,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

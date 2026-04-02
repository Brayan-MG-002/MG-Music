// Copyright © 2026 Brayan Medrano - MG Music
// Componentes para la transición animada entre temas del sistema, incluyendo un contenedor de fondo y un botón de alternancia con efectos visuales.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_service.dart';

class AnimatedThemeSwitcher extends StatelessWidget {
  final Widget child;
  const AnimatedThemeSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDark;
    final bgColor = AppColors.scaffoldBg(themeService.mode);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: bgColor, end: bgColor),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, color, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          color: isDark ? Colors.black : const Color(0xFFCBD5E1),
          child: child,
        );
      },
    );
  }
}

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToggle(ThemeService service) async {
    _controller.forward(from: 0.0);
    await service.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ThemeService>();
    final isDark = service.isDark;

    return GestureDetector(
      onTap: () => _handleToggle(service),
      child: ScaleTransition(
        scale: _scale,
        child: RotationTransition(
          turns: _rotation,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: isDark ? Colors.amber : Colors.blue.shade800,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

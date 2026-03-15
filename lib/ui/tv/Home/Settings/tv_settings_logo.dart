// Copyright © 2026 Brayan Medrano - MG Music
// Logo interactivo para la configuración TV

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';

class TvSettingsLogo extends StatefulWidget {
  const TvSettingsLogo({super.key});

  @override
  State<TvSettingsLogo> createState() => _TvSettingsLogoState();
}

class _TvSettingsLogoState extends State<TvSettingsLogo>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _wobbleController;
  late AnimationController _pulseController;
  Timer? _holdTimer;
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  Color _neonColor = Colors.blue.shade900;

  @override
  /// Inicializa controladores y se suscribe a cambios de canción
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _borderController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _audioManager.currentSongNotifier.addListener(_checkCurrentSong);
    _checkCurrentSong();
  }

  void _checkCurrentSong() {
    final song = _audioManager.currentSongNotifier.value;
    _updateColor(song?.artwork);
    if (song != null && AdoHandler.isAdo(song)) {
      _borderController.forward();
    } else {
      _borderController.reverse();
    }
  }

  /// Actualiza el color neón a partir de la carátula actual
  Future<void> _updateColor(Uint8List? artwork) async {
    if (artwork == null) {
      if (mounted) setState(() => _neonColor = Colors.blue.shade900);
      return;
    }
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(MemoryImage(artwork), width: 100, height: 100),
        maximumColorCount: 5,
      );
      if (mounted) {
        setState(() {
          _neonColor = generator.dominantColor?.color ?? Colors.blue.shade900;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _neonColor = Colors.blue.shade900);
    }
  }

  @override
  /// Libera controladores y timers
  void dispose() {
    _audioManager.currentSongNotifier.removeListener(_checkCurrentSong);
    _borderController.dispose();
    _wobbleController.dispose();
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  /// Inicia el gesto de mantener pulsado para reproducir Ado aleatorio
  void _startHold() {
    if (_holdTimer != null) return;
    final adoSongs = _audioManager.playlist
        .where((s) => AdoHandler.isAdo(s))
        .toList();
    if (adoSongs.isEmpty) return;
    _wobbleController.repeat(reverse: true);
    _holdTimer = Timer(const Duration(milliseconds: 2500), () {
      _resetHold();
      final randomSong = adoSongs[math.Random().nextInt(adoSongs.length)];
      _audioManager.playWithFade(randomSong, _audioManager.playlist);
    });
  }

  /// Resetea el gesto de mantener pulsado
  void _resetHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _wobbleController.stop();
    _wobbleController.reset();
  }

  /// Maneja eventos de teclado para mantener/soltar
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isSelect =
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space;
    if (isSelect) {
      if (event is KeyDownEvent) {
        _startHold();
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        _resetHold();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  /// Construye el logo interactivo con borde animado y pulso
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    return Listener(
      onPointerDown: (_) => _startHold(),
      onPointerUp: (_) => _resetHold(),
      onPointerCancel: (_) => _resetHold(),
      child: TvFocusableItem(
        onTap: () {},
        onKeyEvent: _onKeyEvent,
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.linear,
                tween: ColorTween(begin: Colors.blue.shade900, end: _neonColor),
                builder: (context, animatedColor, _) {
                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _borderController,
                      _wobbleController,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      double rotation = 0;
                      if (_wobbleController.isAnimating) {
                        rotation =
                            math.sin(_wobbleController.value * math.pi * 2) *
                            0.05;
                      }
                      double scale = 1.0;
                      if (_pulseController.isAnimating) {
                        scale = 1.0 + (_pulseController.value * 0.1);
                      }
                      return Transform.rotate(
                        angle: rotation,
                        child: CustomPaint(
                          foregroundPainter: _LogoBorderPainter(
                            progress: _borderController.value,
                            color: animatedColor ?? Colors.blue.shade900,
                            glowOpacity: _pulseController.value,
                          ),
                          child: Transform.scale(
                            scale: scale,
                            child: Image.asset('assets/MG-I-T.png', width: 120),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'MG Music',
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'v1.1.1',
                style: TextStyle(color: AppColors.textSecondary(mode)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowOpacity;

  _LogoBorderPainter({
    required this.progress,
    required this.color,
    this.glowOpacity = 0.0,
  });

  @override
  /// Dibuja el borde circular con efecto glow
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) + 15;

    if (glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(glowOpacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 + (glowOpacity * 2.0)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  /// Determina si debe repintarse por cambios en props
  bool shouldRepaint(_LogoBorderPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.glowOpacity != glowOpacity;
}

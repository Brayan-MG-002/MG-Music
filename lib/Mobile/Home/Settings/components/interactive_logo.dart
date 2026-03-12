import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:typed_data';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';

class InteractiveLogo extends StatefulWidget {
  const InteractiveLogo({super.key});

  @override
  State<InteractiveLogo> createState() => _InteractiveLogoState();
}

class _InteractiveLogoState extends State<InteractiveLogo>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _wobbleController;
  late AnimationController _pulseController;
  Timer? _holdTimer;
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  Color _neonColor = Colors.blue.shade900;
  bool _isAdo = false;

  @override
  /// Inicializa controladores y escucha cambios de canción
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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

    final isAdo = song != null && AdoHandler.isAdo(song);
    if (_isAdo != isAdo) {
      setState(() => _isAdo = isAdo);
    }

    if (isAdo) {
      _borderController.forward();
    } else {
      _borderController.reverse();
    }
  }

  /// Actualiza el color neón en base al artwork
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

  /// Inicia el gesto de mantener presionado para reproducir Ado aleatorio
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

  void _resetHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _wobbleController.stop();
    _wobbleController.reset();
  }

  @override
  /// Construye el logo interactivo con borde y texto reactivo
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return GestureDetector(
      onLongPressDown: (_) => _startHold(),
      onLongPressUp: _resetHold,
      onLongPressCancel: _resetHold,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                        math.sin(_wobbleController.value * math.pi * 2) * 0.05;
                  }
                  double scale = 1.0;
                  if (_pulseController.isAnimating) {
                    scale = 1.0 + (_pulseController.value * 0.1);
                  }

                  return Transform.rotate(
                    angle: rotation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isAdo
                            ? RadialGradient(
                                colors: [
                                  (animatedColor ?? Colors.blue.shade900)
                                      .withOpacity(0.5),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              )
                            : null,
                      ),
                      child: CustomPaint(
                        foregroundPainter: LogoBorderPainter(
                          progress: _borderController.value,
                          color: animatedColor ?? Colors.blue.shade900,
                          glowOpacity: _pulseController.value,
                        ),
                        child: Transform.scale(
                          scale: scale,
                          child: Image.asset('assets/MG-I-T.png', width: 120),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 600),
            tween: ColorTween(begin: Colors.blue.shade900, end: _neonColor),
            builder: (context, animatedNeonColor, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 1000),
                switchInCurve: const Interval(
                  0.5,
                  1.0,
                  curve: Curves.elasticOut,
                ),
                switchOutCurve: const Interval(0.0, 0.5, curve: Curves.easeIn),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _isAdo
                    ? RichText(
                        key: const ValueKey('ado_text'),
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Music ',
                              style: TextStyle(
                                color: AppColors.textPrimary(mode),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'Ado',
                              style: TextStyle(
                                color: animatedNeonColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: (animatedNeonColor ?? Colors.blue)
                                        .withOpacity(0.8),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        'MG Music',
                        key: const ValueKey('mg_text'),
                        style: TextStyle(
                          color: AppColors.textPrimary(mode),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
          Text(
            'Versión 1.1.0',
            style: TextStyle(color: AppColors.textSecondary(mode)),
          ),
        ],
      ),
    );
  }
}

class LogoBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowOpacity;

  LogoBorderPainter({
    required this.progress,
    required this.color,
    this.glowOpacity = 0.0,
  });

  @override
  /// Dibuja el borde circular con glow animado
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
  /// Determina si debe repintarse
  bool shouldRepaint(LogoBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.glowOpacity != glowOpacity;
}

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

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
  bool _isAdo = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
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

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  void dispose() {
    _audioManager.currentSongNotifier.removeListener(_checkCurrentSong);
    _borderController.dispose();
    _wobbleController.dispose();
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final mode = theme.mode;
    final dynamicColor = AppColors.primaryBlueMid;

    return GestureDetector(
      onLongPressDown: (_) => _startHold(),
      onLongPressUp: _resetHold,
      onLongPressCancel: _resetHold,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              _borderController,
              _wobbleController,
              _pulseController,
            ]),
            builder: (context, child) {
              double rotation = 0;
              if (_wobbleController.isAnimating) {
                rotation = math.sin(_wobbleController.value * math.pi * 2) * 0.05;
              }
              double scale = 1.0;
              if (_pulseController.isAnimating) {
                scale = 1.0 + (_pulseController.value * 0.1);
              }

              return RepaintBoundary(
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isAdo
                          ? RadialGradient(
                              colors: [
                                dynamicColor.withOpacity(0.5),
                                Colors.transparent,
                              ],
                              radius: 0.8.r,
                            )
                          : null,
                    ),
                    child: CustomPaint(
                      foregroundPainter: LogoBorderPainter(
                        progress: _borderController.value,
                        color: dynamicColor,
                        glowOpacity: _pulseController.value,
                      ),
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                ),
              );
            },
            child: Image.asset(
              'assets/MG-I-T.png',
              width: ResponsiveService.screenHeight < 650 ? 90.r : 120.r,
            ),
          ),
          SizedBox(height: ResponsiveService.screenHeight < 650 ? 10.h : 20.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
            switchInCurve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
            switchOutCurve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
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
                            fontSize: ResponsiveService.screenHeight < 650 ? 22.sp : 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Ado',
                          style: TextStyle(
                            color: dynamicColor,
                            fontSize: ResponsiveService.screenHeight < 650 ? 22.sp : 28.sp,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: dynamicColor.withOpacity(0.8),
                                blurRadius: 15.r,
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
                      fontSize: ResponsiveService.screenHeight < 650 ? 22.sp : 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          Text(
            _appVersion.isEmpty ? 'Versión ...' : 'Versión $_appVersion',
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 12.sp,
            ),
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
      ..strokeWidth = 2.0.w
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
  bool shouldRepaint(LogoBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.glowOpacity != glowOpacity;
}

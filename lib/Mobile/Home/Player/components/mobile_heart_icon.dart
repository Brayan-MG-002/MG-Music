// m:\MG Proyect\MG Music\MG Music\lib\Mobile\Home\Player\components\mobile_heart_icon.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:palette_generator/palette_generator.dart';

class MobileHeartIcon extends StatefulWidget {
  final bool isFavorite;
  final bool isAdo;
  final VoidCallback onTap;
  final LocalSong? song;

  const MobileHeartIcon({
    super.key,
    required this.isFavorite,
    required this.isAdo,
    required this.onTap,
    this.song,
  });

  @override
  State<MobileHeartIcon> createState() => _MobileHeartIconState();
}

class _MobileHeartIconState extends State<MobileHeartIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _explosionController;
  late AnimationController _normalBumpController;

  Timer? _shakeTimer;
  Timer? _adoActivationTimer;
  bool _adoAnimationsActive = false;
  Color? _dominantColor;
  Color? _secondaryColor;
  bool _particlesActive = false;
  final math.Random _random = math.Random();

  @override
  /// Inicializa controladores y programa activación de animaciones
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _explosionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _particlesActive = false);
      }
    });

    _normalBumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _startAdoActivationDelay();
  }

  /// Activa animaciones de Ado con breve retardo
  void _startAdoActivationDelay() {
    _adoActivationTimer?.cancel();
    _adoAnimationsActive = false;

    if (widget.isAdo) {
      _adoActivationTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _adoAnimationsActive = true;
          });
          _extractDominantColor();
          _setupAnimations();
        }
      });
      if (widget.isFavorite) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _extractDominantColor();
      _setupAnimations();
    }
  }

  /// Configura animaciones según si es Ado y favorito
  void _setupAnimations() {
    if (widget.isAdo && _adoAnimationsActive) {
      _pulseController.repeat(reverse: true);
      _startRandomShake();
    } else if (!widget.isAdo && widget.isFavorite) {
      _pulseController.repeat(reverse: true);
    }
  }

  /// Inicia una sacudida en intervalos aleatorios
  void _startRandomShake() {
    _shakeTimer?.cancel();
    if (!mounted || !widget.isAdo) return;

    final delay = 3 + _random.nextInt(6);
    _shakeTimer = Timer(Duration(seconds: delay), () {
      if (mounted) {
        _shakeController.forward(from: 0.0);
        _startRandomShake();
      }
    });
  }

  /// Obtiene colores dominantes del artwork para efectos
  Future<void> _extractDominantColor() async {
    if (!widget.isAdo) return;

    if (widget.song?.artwork != null) {
      try {
        final imageProvider = MemoryImage(widget.song!.artwork!);
        final palette = await PaletteGenerator.fromImageProvider(
          imageProvider,
          maximumColorCount: 10,
        );
        if (mounted) {
          setState(() {
            _dominantColor =
                palette.dominantColor?.color ?? palette.vibrantColor?.color;
            _secondaryColor =
                palette.lightVibrantColor?.color ??
                palette.darkVibrantColor?.color ??
                Colors.blueAccent;
          });

        }
      } catch (e) {
        debugPrint("Color extraction failed: $e");
      }
    } else {
    }
  }

  @override
  /// Resetea y dispara animaciones según cambios de props
  void didUpdateWidget(MobileHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.song?.id != widget.song?.id) {
      _dominantColor = null;
      _adoAnimationsActive = false;
      _pulseController.stop();
      _pulseController.reset();
      _shakeTimer?.cancel();
      _shakeController.stop();
      _explosionController.stop();
      _particlesActive = false;

      _startAdoActivationDelay();
    } else if (oldWidget.isFavorite != widget.isFavorite) {
      if (!oldWidget.isFavorite && widget.isFavorite) {
        if (widget.isAdo && _adoAnimationsActive) {
          setState(() => _particlesActive = true);
          _explosionController.forward(from: 0.0);
        } else {
          _normalBumpController.forward(from: 0.0);
          if (!_pulseController.isAnimating)
            _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  /// Libera timers y controladores
  void dispose() {
    _adoActivationTimer?.cancel();
    _shakeTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    _explosionController.dispose();
    _normalBumpController.dispose();
    super.dispose();
  }

  @override
  /// Construye el ícono de favorito con animaciones (Ado y estándar)
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    final bool isAdoActive = widget.isAdo && _adoAnimationsActive;
    final adoBaseColor = _dominantColor ?? AppColors.primaryBlueMid;
    final favoriteColor = isAdoActive ? adoBaseColor : Colors.redAccent;
    final idleColor = AppColors.textSecondary(mode);
    final isAdoFav = isAdoActive && widget.isFavorite;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Capa de Partículas (Solo Ado)
            if (_particlesActive && isAdoActive)
              ...List.generate(6, (index) {
                final angle = (index * 60) * math.pi / 180;
                final cachedCos = math.cos(angle);
                final cachedSin = math.sin(angle);

                return AnimatedBuilder(
                  animation: _explosionController,
                  builder: (context, child) {
                    final t = Curves.easeOutCubic.transform(
                      _explosionController.value,
                    );
                    final distance = 75.0 * t;
                    final opacity = 1.0 - t;
                    final dX = cachedCos * distance;
                    final dY = cachedSin * distance;

                    return Transform.translate(
                      offset: Offset(dX, dY),
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.7 + (0.3 * (1 - t)),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    Ionicons.heart,
                    color: adoBaseColor.withOpacity(0.8),
                    size: 20,
                  ),
                );
              }),

            // Ícono Principal
            AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController,
                _shakeController,
                _explosionController,
                _normalBumpController,
              ]),
              builder: (context, child) {
                double scale = 1.0;
                double offsetX = 0.0;
                double rotate = 0.0;

                // 1. Transformaciones Normales
                if (!isAdoActive) {
                  if (_normalBumpController.isAnimating) {
                    final t = _normalBumpController.value;
                    final bump =
                        math.sin(t * math.pi) *
                        Curves.easeOutCubic.transform(t);
                    scale = 1.0 + (bump * 0.4);
                  } else if (widget.isFavorite) {
                    final t = Curves.easeInOutCubic.transform(
                      _pulseController.value,
                    );
                    scale = 1.0 + (t * 0.15);
                  }
                }

                // 2. Transformaciones Ado
                if (isAdoActive) {
                  final t = Curves.easeInOutCubic.transform(
                    _pulseController.value,
                  );
                  scale = 1.0 + (t * 0.25);

                  if (_shakeController.isAnimating) {
                    final tShake = _shakeController.value;
                    offsetX = math.sin(tShake * math.pi * 4) * 1.5;
                    rotate = math.sin(tShake * math.pi * 4) * 0.04;

                    if (widget.isFavorite) {
                      scale += math.sin(tShake * math.pi) * 0.08;
                    }
                  }

                  if (_explosionController.isAnimating) {
                    final tExplode = _explosionController.value;
                    final bounce =
                        math.sin(tExplode * math.pi) *
                        Curves.elasticOut.transform(tExplode);
                    scale = 1.0 + (bounce * 0.5);

                    final shakeIntensity = 1.0 - tExplode;
                    rotate +=
                        (math.sin(tExplode * math.pi * 10) * 0.15) *
                        shakeIntensity;
                  }
                }

                Widget heartIcon = Icon(
                  widget.isFavorite ? Ionicons.heart : Ionicons.heart_outline,
                  color: widget.isFavorite
                      ? (isAdoActive ? Colors.white : favoriteColor)
                      : idleColor,
                  size: 26,
                );

                if (isAdoFav) {
                  final color1 = adoBaseColor;
                  final color2 = _secondaryColor ?? AppColors.primaryBlueLight;

                  // Gradiente animado optimizado
                  final t = _pulseController.value;
                  heartIcon = ShaderMask(
                    shaderCallback: (Rect bounds) {
                      final offset = t * math.pi;
                      final xOffset = math.cos(offset) * 0.5;
                      final yOffset = math.sin(offset) * 0.5;

                      return LinearGradient(
                        colors: [color1, color2, color1],
                        stops: const [0.0, 0.8, 2.0],
                        begin: Alignment(-1.5 + xOffset, -1.5 + yOffset),
                        end: Alignment(1.5 + xOffset, 1.5 + yOffset),
                      ).createShader(bounds);
                    },
                    child: heartIcon,
                  );

                  // Resplandor exterior (optimizado a 1 sola sombra liviana)
                  heartIcon = Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color2.withOpacity(0.5),
                          blurRadius: 12.0,
                          spreadRadius: 1.0,
                        ),
                      ],
                    ),
                    child: heartIcon,
                  );

                  // Delineado azul optimizado
                  heartIcon = Stack(
                    alignment: Alignment.center,
                    children: [
                      heartIcon,
                      Icon(
                        Ionicons.heart_outline,
                        color: Colors.blueAccent.withOpacity(0.35),
                        size: 26,
                      ),
                    ],
                  );
                }

                return Transform.translate(
                  offset: Offset(offsetX, 0),
                  child: Transform.rotate(
                    angle: rotate,
                    child: Transform.scale(scale: scale, child: heartIcon),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

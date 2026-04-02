// m:\MG Proyect\MG Music\MG Music\lib\Mobile\Home\Player\components\mobile_heart_icon.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

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
  late AnimationController _colorTransitionController;

  Timer? _shakeTimer;
  Timer? _adoActivationTimer;
  bool _adoAnimationsActive = false;
  bool _particlesActive = false;
  final math.Random _random = math.Random();

  @override
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

    _colorTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.isFavorite) {
      _colorTransitionController.value = 1.0;
    }

    _startAdoActivationDelay();
  }

  void _startAdoActivationDelay() {
    _adoActivationTimer?.cancel();
    _adoAnimationsActive = false;

    if (widget.isAdo) {
      _adoActivationTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _adoAnimationsActive = true);
          _setupAnimations();
        }
      });
      if (widget.isFavorite) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _setupAnimations();
    }
  }

  void _setupAnimations() {
    if (widget.isAdo && _adoAnimationsActive) {
      _pulseController.repeat(reverse: true);
      _startRandomShake();
    } else if (!widget.isAdo && widget.isFavorite) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startRandomShake() {
    _shakeTimer?.cancel();
    if (!mounted || !widget.isAdo) return;

    final delay = 4 + _random.nextInt(5);
    _shakeTimer = Timer(Duration(seconds: delay), () {
      if (mounted) {
        _shakeController.forward(from: 0.0);
        _startRandomShake();
      }
    });
  }

  @override
  void didUpdateWidget(MobileHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.song?.id != widget.song?.id) {
      _adoAnimationsActive = false;
      _pulseController.stop();
      _pulseController.reset();
      _shakeTimer?.cancel();
      _shakeController.stop();
      _explosionController.stop();
      _particlesActive = false;
      
      if (widget.isFavorite) {
        _colorTransitionController.value = 1.0;
      } else {
        _colorTransitionController.value = 0.0;
      }

      _startAdoActivationDelay();
    } else if (oldWidget.isFavorite != widget.isFavorite) {
      if (widget.isFavorite) {
        _colorTransitionController.forward();
        if (widget.isAdo && _adoAnimationsActive) {
          setState(() => _particlesActive = true);
          _explosionController.forward(from: 0.0);
        } else {
          _normalBumpController.forward(from: 0.0);
          if (!_pulseController.isAnimating)
            _pulseController.repeat(reverse: true);
        }
      } else {
        _colorTransitionController.reverse();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _adoActivationTimer?.cancel();
    _shakeTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    _explosionController.dispose();
    _normalBumpController.dispose();
    _colorTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final bool isAdoActive = widget.isAdo && _adoAnimationsActive;
    
    // Colores base de Ado desde ThemeService/AppColors (dinámicos)
    final dynamicColor = AppColors.primaryBlueMid;
    final dynamicLight = AppColors.primaryBlueLight;
    
    // Color principal de la app (azul estático para estado idle)
    const staticBlue = Color(0xFF1565C0);
    final idleColor = isAdoActive ? staticBlue : AppColors.textSecondary(mode);
    final favoriteSolidColor = isAdoActive ? dynamicColor : Colors.redAccent;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Capa de Partículas (Solo Ado al agregar favorito)
            if (_particlesActive && isAdoActive)
              ...List.generate(6, (index) {
                final angle = (index * 60) * math.pi / 180;
                final cachedCos = math.cos(angle);
                final cachedSin = math.sin(angle);

                return AnimatedBuilder(
                  animation: _explosionController,
                  builder: (context, child) {
                    final t = Curves.easeOutCubic.transform(_explosionController.value);
                    final distance = 75.0.w * t;
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
                    color: dynamicColor.withOpacity(0.8),
                    size: 20.r,
                  ),
                );
              }),

            // Ícono Principal con transiciones y efectos
            AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController,
                _shakeController,
                _explosionController,
                _normalBumpController,
                _colorTransitionController,
              ]),
              builder: (context, _) {
                double scale = 1.0;
                double offsetX = 0.0;
                double rotate = 0.0;
                final transition = Curves.easeInOut.transform(_colorTransitionController.value);

                // 1. Transformaciones Normales
                if (!isAdoActive) {
                  if (_normalBumpController.isAnimating) {
                    final t = _normalBumpController.value;
                    final bump = math.sin(t * math.pi) * Curves.easeOutCubic.transform(t);
                    scale = 1.0 + (bump * 0.4);
                  } else if (widget.isFavorite) {
                    final t = Curves.easeInOutCubic.transform(_pulseController.value);
                    scale = 1.0 + (t * 0.15);
                  }
                } else {
                  // 2. Transformaciones Ado (Pulso y sacudidas)
                  final tPulse = Curves.easeInOutCubic.transform(_pulseController.value);
                  scale = 1.0 + (tPulse * 0.22); // Pulso ligeramente más suave para ser "premium"

                  if (_shakeController.isAnimating) {
                    final tShake = _shakeController.value;
                    offsetX = math.sin(tShake * math.pi * 4) * 1.5.w;
                    rotate = math.sin(tShake * math.pi * 4) * 0.03;
                    if (widget.isFavorite) scale += math.sin(tShake * math.pi) * 0.06;
                  }

                  if (_explosionController.isAnimating) {
                    final tExplode = _explosionController.value;
                    final bounce = math.sin(tExplode * math.pi) * Curves.elasticOut.transform(tExplode);
                    scale = 1.0 + (bounce * 0.45);
                    rotate += (math.sin(tExplode * math.pi * 10) * 0.12) * (1.0 - tExplode);
                  }
                }

                // Color animado entre Idle y Favorite
                final currentColor = Color.lerp(idleColor, favoriteSolidColor, transition)!;

                Widget heartIcon = Icon(
                  widget.isFavorite ? Ionicons.heart : Ionicons.heart_outline,
                  color: isAdoActive ? Colors.white : currentColor,
                  size: 26.r,
                );

                if (isAdoActive) {
                   // Efecto de Gradiente dinámico si es Ado y tiene transición activa
                   if (transition > 0.01) {
                     final pulseT = _pulseController.value;
                     heartIcon = ShaderMask(
                       blendMode: BlendMode.srcIn,
                       shaderCallback: (Rect bounds) {
                         final offset = pulseT * math.pi;
                         final xOffset = math.cos(offset) * 0.4;
                         final yOffset = math.sin(offset) * 0.4;

                         // Mezclamos el color base con el gradiente basado en la animación de transición
                         return LinearGradient(
                           colors: [
                             Color.lerp(staticBlue, dynamicColor, transition)!,
                             Color.lerp(staticBlue, dynamicLight, transition)!,
                             Color.lerp(staticBlue, dynamicColor, transition)!,
                           ],
                           stops: const [0.0, 0.5, 1.0],
                           begin: Alignment(-1.2 + xOffset, -1.2 + yOffset),
                           end: Alignment(1.2 + xOffset, 1.2 + yOffset),
                         ).createShader(bounds);
                       },
                       child: Icon(
                         Ionicons.heart,
                         color: Colors.white,
                         size: 26.r,
                       ),
                     );
                   }

                   // Brillo y Delineado para Ado (Solo si está marcado o transicionando)
                   if (transition > 0.05) {
                     heartIcon = Stack(
                       alignment: Alignment.center,
                       children: [
                         // Resplandor optimizado
                         Container(
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(
                                 color: dynamicLight.withOpacity(0.4 * transition),
                                 blurRadius: (12.0 + (_pulseController.value * 8)).r,
                                 spreadRadius: 1.0.r,
                               ),
                             ],
                           ),
                           child: heartIcon,
                         ),
                         // Delineado sutil
                         Icon(
                           Ionicons.heart_outline,
                           color: Colors.blueAccent.withOpacity(0.25 * transition),
                           size: 26.r,
                         ),
                       ],
                     );
                   }
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

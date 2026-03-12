// Copyright © 2026 Brayan Medrano - MG Music
// Reproductor a pantalla completa Mobile

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'components/mobile_player_artwork.dart';
import 'components/mobile_player_actions.dart';
import 'components/mobile_player_controls.dart';
import 'components/sleep_timer_badge.dart';

class MobileFullPlayer extends StatefulWidget {
  const MobileFullPlayer({super.key});

  @override
  State<MobileFullPlayer> createState() => _MobileFullPlayerState();
}

class _MobileFullPlayerState extends State<MobileFullPlayer> {
  final manager = AudioPlayerManager();
  int? _lastSongId;
  bool _isSlideLeft = true;

  @override
  /// Inicializa escucha de cambio de canción para animaciones
  void initState() {
    super.initState();
    _lastSongId = manager.currentSongNotifier.value?.id;
    manager.currentSongNotifier.addListener(_onSongChanged);
  }

  @override
  /// Libera listener de cambios
  void dispose() {
    manager.currentSongNotifier.removeListener(_onSongChanged);
    super.dispose();
  }

  /// Determina dirección de transición entre carátulas/títulos
  void _onSongChanged() {
    final song = manager.currentSongNotifier.value;
    if (song != null && song.id != _lastSongId) {
      final playlist = manager.playlist;
      final oldIndex = playlist.indexWhere((s) => s.id == _lastSongId);
      final newIndex = playlist.indexWhere((s) => s.id == song.id);

      bool slideLeft = true;
      if (oldIndex != -1 && newIndex != -1) {
        if (oldIndex == playlist.length - 1 && newIndex == 0) {
          slideLeft = true;
        } else if (oldIndex == 0 && newIndex == playlist.length - 1) {
          slideLeft = false;
        } else {
          slideLeft = newIndex > oldIndex;
        }
      }
      if (mounted) {
        setState(() {
          _isSlideLeft = slideLeft;
          _lastSongId = song.id;
        });
      }
    }
  }

  @override
  /// Construye el reproductor a pantalla completa
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SleepTimerBadge(),
        centerTitle: true,
      ),
      body: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 250),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: ScaleAnimation(
                  scale: 0.5,
                  curve: Curves.elasticOut,
                  child: FadeInAnimation(child: widget),
                ),
              ),
              children: [
                ValueListenableBuilder<LocalSong?>(
                  valueListenable: manager.currentSongNotifier,
                  builder: (context, song, _) {
                    if (song == null) return const SizedBox.shrink();
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final dx = _isSlideLeft ? 1.0 : -1.0;
                        final isIncoming = child.key == ValueKey(song.id);
                        final offset = isIncoming
                            ? Tween<Offset>(
                                begin: Offset(dx, 0.0),
                                end: Offset.zero,
                              ).animate(animation)
                            : Tween<Offset>(
                                begin: Offset(-dx, 0.0),
                                end: Offset.zero,
                              ).animate(animation);

                        return SlideTransition(
                          position: offset,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: MobilePlayerArtwork(
                        key: ValueKey(song.id),
                        song: song,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                ValueListenableBuilder<LocalSong?>(
                  valueListenable: manager.currentSongNotifier,
                  builder: (context, song, _) {
                    if (song == null) return const SizedBox.shrink();
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final dx = _isSlideLeft ? 1.0 : -1.0;
                        final isIncoming =
                            child.key == ValueKey('text_${song.id}');
                        final offset = isIncoming
                            ? Tween<Offset>(
                                begin: Offset(dx, 0.0),
                                end: Offset.zero,
                              ).animate(animation)
                            : Tween<Offset>(
                                begin: Offset(-dx, 0.0),
                                end: Offset.zero,
                              ).animate(animation);

                        return SlideTransition(
                          position: offset,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey('text_${song.id}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              song.title,
                              style: TextStyle(
                                color: AppColors.textPrimary(mode),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              song.artist,
                              style: TextStyle(
                                color: AppColors.textSecondary(mode),
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                ValueListenableBuilder<LocalSong?>(
                  valueListenable: manager.currentSongNotifier,
                  builder: (context, song, _) {
                    if (song == null) return const SizedBox.shrink();
                    return MobilePlayerActions(manager: manager, song: song);
                  },
                ),
                const SizedBox(height: 10),

                RepaintBoundary(
                  child: _MobilePlayerProgressBar(manager: manager, mode: mode),
                ),
                const SizedBox(height: 10),

                MobilePlayerControls(manager: manager),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobilePlayerProgressBar extends StatelessWidget {
  final AudioPlayerManager manager;
  final AppThemeMode mode;

  const _MobilePlayerProgressBar({required this.manager, required this.mode});

  @override
  /// Barra de progreso animada con slider temático
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: manager.positionNotifier,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: manager.durationNotifier,
          builder: (context, duration, _) {
            final posMs = position.inMilliseconds.toDouble();
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: posMs, end: posMs),
              builder: (context, animValue, _) {
                final currentMax = duration.inMilliseconds.toDouble();
                final safeMax = math.max(currentMax, animValue);

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackShape: _GradientSliderTrackShape(mode: mode),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16.0,
                        ),
                        inactiveTrackColor: mode == AppThemeMode.dark
                            ? Colors.white24
                            : Colors.black12,
                        thumbColor: AppColors.textPrimary(mode),
                      ),
                      child: Slider(
                        value: animValue.clamp(
                          0.0,
                          safeMax > 0 ? safeMax : 1.0,
                        ),
                        min: 0.0,
                        max: safeMax > 0 ? safeMax : 1.0,
                        onChanged: (value) {
                          manager.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(
                              Duration(milliseconds: animValue.toInt()),
                            ),
                            style: TextStyle(
                              color: AppColors.textSecondary(mode),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: AppColors.textSecondary(mode),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Formatea duración en hh:mm:ss o mm:ss según corresponda
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }
}

/// A custom slider track shape that paints a gradient on the active part.
class _GradientSliderTrackShape extends RectangularSliderTrackShape {
  final AppThemeMode mode;
  const _GradientSliderTrackShape({required this.mode});

  @override
  /// Pinta la pista del slider con gradiente activo y borde fino
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    Offset? secondaryOffset,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Paint for the inactive part
    final inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor!;

    // Paint for the active part with a gradient
    final activePaint = Paint()
      ..shader = AppGradients.of(
        mode,
        GradientDirection.leftRight,
      ).createShader(trackRect);

    // Paint for the border of the active part (super thin)
    final borderPaint = Paint()
      ..color = AppColors.themeBorder(mode).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    // Draw inactive track (the part after the thumb)
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        thumbCenter.dx,
        trackRect.top,
        trackRect.right,
        trackRect.bottom,
        topRight: trackRadius,
        bottomRight: trackRadius,
      ),
      inactivePaint,
    );

    // Draw active track (the part before the thumb)
    final activeRRect = RRect.fromLTRBAndCorners(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
      topLeft: trackRadius,
      bottomLeft: trackRadius,
    );

    context.canvas.drawRRect(activeRRect, activePaint);

    // Draw the thin border around the active track
    context.canvas.drawRRect(activeRRect, borderPaint);
  }
}

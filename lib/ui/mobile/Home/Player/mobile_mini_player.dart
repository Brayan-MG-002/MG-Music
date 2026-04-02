// Copyright © 2026 Brayan Medrano - MG Music
// Mini reproductor Mobile

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/mobile/Home/Player/mobile_full_player.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class MobileMiniPlayer extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showVisualizer;
  final bool isSpecialExpanded;

  const MobileMiniPlayer({
    super.key, 
    this.onTap, 
    this.showVisualizer = false,
    this.isSpecialExpanded = false,
  });

  @override
  State<MobileMiniPlayer> createState() => _MobileMiniPlayerState();
}

class _MobileMiniPlayerState extends State<MobileMiniPlayer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  int? _lastSongId;
  bool _isSlideLeft = true;

  @override
  /// Inicializa controladores y escucha cambios de canción
  void initState() {
    super.initState();
    final manager = AudioPlayerManager();
    _lastSongId = manager.currentSongNotifier.value?.id;
    manager.currentSongNotifier.addListener(_onSongChanged);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  /// Libera listeners y controladores
  void dispose() {
    final manager = AudioPlayerManager();
    manager.currentSongNotifier.removeListener(_onSongChanged);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSongChanged() {
    final manager = AudioPlayerManager();
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
  /// Construye el mini reproductor con carátula, texto y controles
  Widget build(BuildContext context) {
    final manager = AudioPlayerManager();
    final mode = context.watch<ThemeService>().mode;

    return ValueListenableBuilder<LocalSong?>(
      valueListenable: manager.currentSongNotifier,
      builder: (context, song, _) {
        if (song == null) {
          return Center(
            child: Image.asset('assets/MG-I-T.png', width: 30.r, height: 30.r),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: manager.isPlayingNotifier,
          builder: (context, isPlaying, _) {
            final isAdo = AdoHandler.isAdo(song);
            if (isAdo && isPlaying) {
              if (!_pulseController.isAnimating) {
                _pulseController.repeat(reverse: true);
              }
            } else {
              _pulseController.stop();
              _pulseController.reset();
            }

            if (isPlaying) {
              if (!_controller.isAnimating) _controller.repeat();
            } else {
              if (_controller.isAnimating) _controller.stop();
            }

            return AnimationConfiguration.synchronized(
              duration: const Duration(milliseconds: 800),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: ScaleAnimation(
                  scale: 0.5,
                  curve: Curves.elasticOut,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () async {
                          if (widget.onTap != null) {
                            await Future.delayed(
                              const Duration(milliseconds: 200),
                            );
                            widget.onTap!();
                          } else {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const MobileFullPlayer(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                transitionDuration: const Duration(
                                  milliseconds: 400,
                                ),
                              ),
                            );
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 0) {
                            manager.previous();
                          } else if (details.primaryVelocity! < 0) {
                            manager.next();
                          }
                        },
                        child: Container(
                          height: (AdoHandler.isAdo(song) ? 58.0 : 50.0).h
                              .clamp(40.0, 75.0),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: AppColors.primaryBlueMid,
                              width: 1.5, // Fixed width for clear visibility
                            ),
                            boxShadow: isAdo
                                ? [
                                    BoxShadow(
                                      color: AppColors.adoGlow(mode)
                                          .withOpacity(
                                            0.4 * _pulseController.value,
                                          ),
                                      blurRadius: 8 * _pulseController.value,
                                      spreadRadius: 1 * _pulseController.value,
                                    ),
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                        child: widget.isSpecialExpanded
                            ? _buildSpecialTitleMode(song, mode)
                            : widget.showVisualizer
                                ? _buildVisualizer(mode)
                                : _buildSongInfo(song, isPlaying, manager, mode),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construye la fila de información de la canción y controles básicos
  Widget _buildSongInfo(
    LocalSong song,
    bool isPlaying,
    AudioPlayerManager manager,
    AppThemeMode mode,
  ) {
    return Row(
      key: const ValueKey('songInfo'),
      children: [
        AnimatedSwitcher(
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
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: RotationTransition(
            key: ValueKey(song.id),
            turns: _controller,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.themeBorder(mode).withOpacity(0.5),
                  width: 0.8.w,
                ),
              ),
              child: ClipOval(
                child: song.artwork != null
                    ? Image.memory(
                        song.artwork!,
                        width: 32.r,
                        height: 32.r,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/MG-I-T.png',
                        width: 32.r,
                        height: 32.r,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final dx = _isSlideLeft ? 1.0 : -1.0;
              final isIncoming = child.key == ValueKey('text_${song.id}');
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
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Column(
              key: ValueKey('text_${song.id}'),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary(mode),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                  ),
                ),
                ValueListenableBuilder<Duration>(
                  valueListenable: manager.positionNotifier,
                  builder: (context, position, _) {
                    final posMs = position.inMilliseconds.toDouble();
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: posMs, end: posMs),
                      builder: (context, animValue, _) {
                        final pos = Duration(milliseconds: animValue.toInt());
                        final m = pos.inMinutes;
                        final s = (pos.inSeconds % 60).toString().padLeft(
                          2,
                          '0',
                        );
                        return Text(
                          "$m:$s",
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 9.sp,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(isPlaying ? Ionicons.pause : Ionicons.play),
          iconSize: (widget.isSpecialExpanded ? 16 : 18).r,
          color: AppColors.icon(mode),
          onPressed: manager.togglePlayPause,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: (widget.isSpecialExpanded ? 28 : 32).w,
            minHeight: (widget.isSpecialExpanded ? 28 : 32).h,
          ),
        ),
        IconButton(
          icon: const Icon(Ionicons.play_skip_forward),
          iconSize: (widget.isSpecialExpanded ? 16 : 18).r,
          color: AppColors.icon(mode),
          onPressed: manager.next,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: (widget.isSpecialExpanded ? 28 : 32).w,
            minHeight: (widget.isSpecialExpanded ? 28 : 32).h,
          ),
        ),
      ],
    );
  }

  /// Construye visualizador simple de barras animadas
  Widget _buildVisualizer(AppThemeMode mode) {
    return SizedBox(
      key: const ValueKey('visualizer'),
      height: 36.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              final noise =
                  math.sin(t * 40 + index) * math.cos(t * 25 + index * 2) +
                  math.sin(t * 15 + index * 0.5);
              final normalized = noise.abs();
              final height = (8.0 + 20.0 * normalized).h;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                width: 3.w,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.visualizerColor(mode),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  /// Construye info centrada de título y artista para el modo especial
  Widget _buildSpecialTitleMode(LocalSong song, AppThemeMode mode) {
    return Container(
      key: const ValueKey('special_title_mode'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(mode),
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

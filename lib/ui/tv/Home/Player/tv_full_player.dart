// Copyright © 2026 Brayan Medrano - MG Music
// Reproductor a pantalla completa para la interfaz de TV, con visualizador, controles avanzados y gestión de lista de reproducción.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:animations_plus/animations_plus.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/logic/tv_full_player_logic.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/playlist_action_service.dart';
import 'package:mg_music/services/ui/song_context_menu_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/ui/mobile/Home/EditSong/edit_song_page.dart';
import 'package:mg_music/ui/tv/Home/Player/tv_full_player_timebar.dart';

class TvFullPlayer extends StatefulWidget {
  const TvFullPlayer({super.key});

  @override
  State<TvFullPlayer> createState() => _TvFullPlayerState();
}

class _TvFullPlayerState extends State<TvFullPlayer> {
  late final TvFullPlayerLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = TvFullPlayerLogic();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerManager = AudioPlayerManager();
    final mode = context.watch<ThemeService>().mode;

    return ValueListenableBuilder<LocalSong?>(
      valueListenable: playerManager.currentSongNotifier,
      builder: (context, currentSong, child) {
        if (currentSong == null) {
          return const Center(
            child: Text(
              "No hay canción seleccionada",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ValueListenableBuilder<List<LocalSong>>(
          valueListenable: playerManager.activePlaylistNotifier,
          builder: (context, activePlaylist, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_logic.scrollController.hasClients) {
                final index = activePlaylist.indexWhere(
                  (s) => s.id == currentSong.id,
                );
                if (index >= 0) {
                  final itemHeight = _logic.itemHeight;
                  const containerHeight = 400.0;
                  final offset =
                      (index * itemHeight) -
                      (containerHeight / 2) +
                      (itemHeight / 2);
                  final maxScroll =
                      _logic.scrollController.position.maxScrollExtent;
                  _logic.scrollController.animateTo(
                    offset.clamp(0.0, maxScroll),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                }
              }
            });

            return SimpleFadeAnimation(
              duration: const Duration(milliseconds: 350),
              child: SimpleSlideAnimation(
                duration: const Duration(milliseconds: 350),
                direction: SlideDirection.up,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 100,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: playerManager.showVisualizerNotifier,
                        builder: (context, showVisualizer, _) {
                          if (!showVisualizer) return const SizedBox.shrink();
                          return _MusicVisualizer(
                            isPlayingNotifier: playerManager.isPlayingNotifier,
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                TvFullPlayerTimeBar(
                                  playerManager: playerManager,
                                  logic: _logic,
                                  mode: mode,
                                ),
                                _SongInfoSection(
                                  currentSong: currentSong,
                                  playerManager: playerManager,
                                  mode: mode,
                                ),
                                _PlaybackControlsSection(
                                  playerManager: playerManager,
                                  mode: mode,
                                ),
                                _PlaylistSection(
                                  playerManager: playerManager,
                                  logic: _logic,
                                  mode: mode,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


class _SongInfoSection extends StatelessWidget {
  final LocalSong currentSong;
  final AudioPlayerManager playerManager;
  final AppThemeMode mode;

  const _SongInfoSection({
    required this.currentSong,
    required this.playerManager,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TvFocusableItem(
              onTap: () {},
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 750),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: ClipRRect(
                  key: ValueKey<int>(currentSong.id),
                  borderRadius: BorderRadius.circular(20),
                  child: currentSong.artwork != null
                      ? Image.memory(
                          currentSong.artwork!,
                          width: 200,
                          height: 200,
                          cacheWidth: 400,
                          cacheHeight: 400,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/MG-I-T.png',
                          width: 200,
                          height: 200,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentSong.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              currentSong.artist,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(mode),
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: playerManager.isShuffleModeNotifier,
                  builder: (context, isShuffle, _) {
                    return _buildIconButton(
                      Ionicons.shuffle,
                      isShuffle
                          ? AppColors.primaryBlueMid
                          : AppColors.textPrimary(mode),
                      playerManager.toggleShuffleMode,
                    );
                  },
                ),
                const SizedBox(width: 10),
                _buildIconButton(
                  Ionicons.timer_outline,
                  AppColors.textPrimary(mode),
                  () => GlobalModalService.showSleepTimerDialog(context),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<List<String>>(
                  valueListenable: FavoritesManager().favoritePathsNotifier,
                  builder: (context, favoritePaths, _) {
                    final isFavorite = favoritePaths.contains(currentSong.path);
                    final isAdo = currentSong.artist.toLowerCase().contains(
                      'ado',
                    );

                    return _AdoHeartIcon(
                      isFavorite: isFavorite,
                      isAdo: isAdo,
                      onTap: () =>
                          FavoritesManager().toggleFavorite(currentSong),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _buildIconButton(
                  Ionicons.add_circle_outline,
                  AppColors.textPrimary(mode),
                  () => PlaylistActionService.showAddToPlaylistDialog(
                    context,
                    currentSong,
                  ),
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<LoopMode>(
                  valueListenable: playerManager.loopModeNotifier,
                  builder: (context, loopMode, _) {
                    final isRepeatOne = loopMode == LoopMode.one;
                    return _buildIconButton(
                      Ionicons.repeat,
                      isRepeatOne
                          ? AppColors.primaryBlueMid
                          : AppColors.textPrimary(mode),
                      playerManager.toggleLoopMode,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return TvFocusableItem(
      borderRadius: 50,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _AdoHeartIcon extends StatefulWidget {
  final bool isFavorite;
  final bool isAdo;
  final VoidCallback onTap;

  const _AdoHeartIcon({
    required this.isFavorite,
    required this.isAdo,
    required this.onTap,
  });

  @override
  State<_AdoHeartIcon> createState() => _AdoHeartIconState();
}

class _AdoHeartIconState extends State<_AdoHeartIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _addEffectController;
  late AnimationController _neonController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _addEffectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _updateState(false);
  }

  @override
  void didUpdateWidget(_AdoHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateState(oldWidget.isFavorite);
  }

  void _updateState(bool wasFavorite) {
    if (widget.isAdo) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.isAdo && widget.isFavorite) {
      _neonController.forward();
    } else {
      _neonController.reverse();
    }

    if (widget.isAdo && widget.isFavorite && !wasFavorite) {
      _addEffectController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _addEffectController.dispose();
    _neonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusableItem(
      borderRadius: 50,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _addEffectController,
            _neonController,
          ]),
          builder: (context, child) {
            double scale = 1.0;
            if (widget.isAdo) {
              scale = 1.0 + (_pulseController.value * 0.2);
            }

            double offsetX = 0.0;
            if (_addEffectController.isAnimating) {
              final t = _addEffectController.value;
              scale += (math.sin(t * math.pi) * 0.3);
              offsetX = math.sin(t * math.pi * 4) * 5.0 * (1 - t);
            }

            final icon = widget.isFavorite
                ? Ionicons.heart
                : Ionicons.heart_outline;
            Color color = Colors.white;
            if (widget.isFavorite) {
              color = widget.isAdo ? AppColors.primaryBlue : Colors.red;
            }

            List<Shadow> shadows = [];
            if (_neonController.value > 0) {
              final opacity = _neonController.value;
              shadows = [
                Shadow(
                  color: AppColors.primaryBlue.withOpacity(0.8 * opacity),
                  blurRadius: 15.0,
                ),
                Shadow(
                  color: Colors.blue.withOpacity(0.5 * opacity),
                  blurRadius: 25.0,
                ),
              ];
            }

            return Transform.translate(
              offset: Offset(offsetX, 0),
              child: Transform.scale(
                scale: scale,
                child: Icon(icon, color: color, size: 24, shadows: shadows),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlaybackControlsSection extends StatelessWidget {
  final AudioPlayerManager playerManager;
  final AppThemeMode mode;

  const _PlaybackControlsSection({
    required this.playerManager,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPlayerButton(
            Ionicons.chevron_up,
            () => playerManager.previous(),
            size: 30,
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<bool>(
            valueListenable: playerManager.isPlayingNotifier,
            builder: (context, isPlaying, _) {
              return TvFocusableItem(
                borderRadius: 50,
                onTap: playerManager.togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mode == AppThemeMode.dark
                          ? [AppColors.primaryBlue, Colors.black]
                          : [AppColors.primaryBlueMid, Colors.white],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Ionicons.pause : Ionicons.play,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildPlayerButton(
            Ionicons.chevron_down,
            () => playerManager.next(),
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerButton(
    IconData icon,
    VoidCallback onTap, {
    double size = 24,
  }) {
    return TvFocusableItem(
      borderRadius: 50,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(icon, color: AppColors.textPrimary(mode), size: size),
      ),
    );
  }
}

class _PlaylistSection extends StatelessWidget {
  final AudioPlayerManager playerManager;
  final TvFullPlayerLogic logic;
  final AppThemeMode mode;

  const _PlaylistSection({
    required this.playerManager,
    required this.logic,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Center(
        child: Container(
          height: 400,
          margin: const EdgeInsets.only(right: 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.sidebarGradient(mode),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListView.builder(
            controller: logic.scrollController,
            padding: EdgeInsets.zero,
            itemExtent: logic.itemHeight,
            itemCount: playerManager.playlist.length,
            itemBuilder: (context, index) {
              final song = playerManager.playlist[index];
              final isCurrent =
                  song.id == playerManager.currentSongNotifier.value?.id;
              return TvFocusableItem(
                borderRadius: 10,
                onTap: () {
                  playerManager.playSong(song, playerManager.playlist);
                },
                onLongPress: () {
                  SongContextMenuService.showOptions(
                    context,
                    song,
                    isTv: true,
                    onEditSong: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditSongPage(song: song)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryBlue.withOpacity(0.6)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isCurrent
                        ? Border.all(color: AppColors.primaryBlueMid.withOpacity(0.3))
                        : null,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Icon(
                            Ionicons.musical_note,
                            color: AppColors.primaryBlueMid,
                            size: 18,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.textPrimary(mode)
                                : AppColors.textSecondary(mode),
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isCurrent ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MusicVisualizer extends StatefulWidget {
  final ValueNotifier<bool> isPlayingNotifier;

  const _MusicVisualizer({
    required this.isPlayingNotifier,
  });

  @override
  State<_MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<_MusicVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _heightsController;
  List<double> _barHeights = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.filled(48, 5.0);

    _heightsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _heightsController.addListener(_updateHeights);
  }

  void _updateHeights() {
    if (widget.isPlayingNotifier.value) {
      final bool kick = _random.nextDouble() < 0.08;
      for (int i = 0; i < _barHeights.length; i++) {
        final double gravity = (i < 12) ? 2.0 : 4.0;
        _barHeights[i] = math.max(5.0, _barHeights[i] - gravity);
        double impulseProbability = 0.0;
        double maxImpulseHeight = 0.0;

        if (i < 12) {
          impulseProbability = kick ? 0.95 : 0.05;
          maxImpulseHeight = 100.0;
        } else if (i < 32) {
          impulseProbability = 0.04;
          maxImpulseHeight = 60.0;
        } else {
          impulseProbability = 0.07;
          maxImpulseHeight = 45.0;
        }

        if (_random.nextDouble() < impulseProbability) {
          final double newHeight =
              10.0 + _random.nextDouble() * (maxImpulseHeight - 10.0);
          if (newHeight > _barHeights[i]) {
            _barHeights[i] = newHeight;
          }
        }
      }
    } else {
      bool allBarsAtMinimum = true;
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = math.max(5.0, _barHeights[i] - 3.0);
        if (_barHeights[i] > 5.0) allBarsAtMinimum = false;
      }
      if (allBarsAtMinimum && _heightsController.isAnimating) {
        _heightsController.stop();
      }
    }
  }

  @override
  void dispose() {
    _heightsController.removeListener(_updateHeights);
    _heightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>(); // Escuchar cambios globales de color
    final color = AppColors.primaryBlueMid;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        if (isPlaying && !_heightsController.isAnimating) {
          _heightsController.repeat();
        }
        return AnimatedBuilder(
          animation: _heightsController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _VisualizerPainter(
                heights: _barHeights,
                color: color,
              ),
            );
          },
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final List<double> heights;
  final Color color;
  final Paint _paint;

  _VisualizerPainter({required this.heights, required this.color})
    : _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    const double barWidth = 8.0;
    const double barSpacing = 4.0;
    final double totalWidth =
        (barWidth * heights.length) + (barSpacing * (heights.length - 1));
    double startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < heights.length; i++) {
      final double barHeight = heights[i].clamp(0.0, size.height);
      if (barHeight <= 5.0) continue;

      final Rect rect = Rect.fromLTWH(
        startX + i * (barWidth + barSpacing),
        size.height - barHeight,
        barWidth,
        barHeight,
      );

      _paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color.withOpacity(0.8), color.withOpacity(0.1)],
      ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}

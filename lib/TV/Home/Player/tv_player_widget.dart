// Copyright © 2026 Brayan Medrano - MG Music
// Widget reproductor compacto TV

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:animations_plus/animations_plus.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:provider/provider.dart';

class TvPlayerWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const TvPlayerWidget({super.key, this.onTap});

  @override
  /// Construye el mini reproductor con carátula, progreso y controles
  Widget build(BuildContext context) {
    final playerManager = AudioPlayerManager();
    final mode = context.watch<ThemeService>().mode;

    return ValueListenableBuilder<LocalSong?>(
      valueListenable: playerManager.currentSongNotifier,
      builder: (context, currentSong, child) {
        if (currentSong == null) {
          return const SizedBox.shrink(); // Si no hay canción, espacio vacío (sin Spacer/Expanded)
        }

        return SimpleFadeAnimation(
          duration: const Duration(milliseconds: 300),
          child: SimpleSlideAnimation(
            duration: const Duration(milliseconds: 300),
            direction: SlideDirection.up,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.songItemGradient(mode),
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.themeBorder(mode)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TvFocusableItem(
                      onTap: onTap,
                      borderRadius: 15,
                      child: Row(
                        children: [
                          RotatingArtwork(
                            artwork: currentSong.artwork,
                            isPlayingNotifier: playerManager.isPlayingNotifier,
                            size: 50,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ValueListenableBuilder<Duration>(
                                  valueListenable:
                                      playerManager.positionNotifier,
                                  builder: (context, position, _) {
                                    final duration =
                                        playerManager.durationNotifier.value;
                                    final double progress =
                                        (duration.inMilliseconds > 0)
                                            ? position.inMilliseconds /
                                                duration.inMilliseconds
                                            : 0.0;
                                    return Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor:
                                              progress.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: mode ==
                                                        AppThemeMode.dark
                                                    ? [
                                                        Colors.blue.shade900,
                                                        Colors.black
                                                      ]
                                                    : [
                                                        Colors.blue.shade500,
                                                        Colors.white
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<bool>(
                    valueListenable: playerManager.isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      return TvFocusableItem(
                        borderRadius: 50,
                        onTap: playerManager.togglePlayPause,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            isPlaying ? Ionicons.pause : Ionicons.play,
                            color: AppColors.textPrimary(mode),
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  TvFocusableItem(
                    borderRadius: 50,
                    onTap: playerManager.next,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Ionicons.play_skip_forward,
                        color: AppColors.textPrimary(mode),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RotatingArtwork extends StatefulWidget {
  final Uint8List? artwork;
  final ValueNotifier<bool> isPlayingNotifier;
  final double size;

  const RotatingArtwork({
    super.key,
    required this.artwork,
    required this.isPlayingNotifier,
    this.size = 50,
  });

  @override
  State<RotatingArtwork> createState() => _RotatingArtworkState();
}

class _RotatingArtworkState extends State<RotatingArtwork>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  /// Inicializa el controlador y sincroniza con el estado de reproducción
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Gira lento
    );

    widget.isPlayingNotifier.addListener(_checkPlaybackState);
    _checkPlaybackState();
  }

  @override
  /// Libera recursos y quita listeners
  void dispose() {
    widget.isPlayingNotifier.removeListener(_checkPlaybackState);
    _controller.dispose();
    super.dispose();
  }

  void _checkPlaybackState() {
    if (widget.isPlayingNotifier.value) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  /// Dibuja la carátula con rotación animada
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          widget.size / 2,
        ), // Círculo perfecto dinámico
        child: widget.artwork != null
            ? Image.memory(
                widget.artwork!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/MG-I-T.png',
                width: widget.size,
                height: widget.size,
              ),
      ),
    );
  }
}

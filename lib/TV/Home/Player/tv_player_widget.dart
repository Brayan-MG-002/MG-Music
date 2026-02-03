// Copyright © 2026 Brayan Medrano - MG Music
// Widget reproductor compacto TV

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

class TvPlayerWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const TvPlayerWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final playerManager = AudioPlayerManager();

    return ValueListenableBuilder<LocalSong?>(
      valueListenable: playerManager.currentSongNotifier,
      builder: (context, currentSong, child) {
        if (currentSong == null) {
          return const SizedBox.shrink(); // Si no hay canción, espacio vacío (sin Spacer/Expanded)
        }

        // Modo Mini Reproductor Normal
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // Zona Principal: Info y Carátula (Expande el player)
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ValueListenableBuilder<Duration>(
                              valueListenable: playerManager.positionNotifier,
                              builder: (context, position, _) {
                                final duration =
                                    playerManager.durationNotifier.value;
                                final double progress =
                                    (duration.inMilliseconds > 0)
                                    ? position.inMilliseconds /
                                          duration.inMilliseconds
                                    : 0.0;
                                return LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey.shade800,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                  minHeight: 3,
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
              // Botón Play/Pause Independiente
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
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              // Botón Siguiente Independiente
              TvFocusableItem(
                borderRadius: 50,
                onTap: playerManager.next,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Ionicons.play_skip_forward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
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
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Gira lento
    );

    widget.isPlayingNotifier.addListener(_checkPlaybackState);
    // Verificar el estado inicial inmediatamente por si ya está sonando al volver
    _checkPlaybackState();
  }

  @override
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

// Copyright © 2026 Brayan Medrano - MG Music
// Mini reproductor Mobile

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Mobile/Home/Player/mobile_full_player.dart';

class MobileMiniPlayer extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showVisualizer;

  const MobileMiniPlayer({super.key, this.onTap, this.showVisualizer = false});

  @override
  State<MobileMiniPlayer> createState() => _MobileMiniPlayerState();
}

class _MobileMiniPlayerState extends State<MobileMiniPlayer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = AudioPlayerManager();
    return ValueListenableBuilder<LocalSong?>(
      valueListenable: manager.currentSongNotifier,
      builder: (context, song, _) {
        // Si no hay canción, mostramos el logo o un placeholder
        if (song == null) {
          return Center(
            child: Image.asset('assets/MG-I-T.png', width: 30, height: 30),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: manager.isPlayingNotifier,
          builder: (context, isPlaying, _) {
            // Lógica del Latido (Solo Ado + Reproduciendo)
            final isAdo = song.artist.toLowerCase().contains('ado');
            if (isAdo && isPlaying) {
              if (!_pulseController.isAnimating) {
                _pulseController.repeat(reverse: true);
              }
            } else {
              _pulseController.stop();
              _pulseController.reset();
            }

            // Lógica de Animación Principal (Visualizador y Rotación)
            if (isPlaying) {
              if (!_controller.isAnimating) _controller.repeat();
            } else {
              if (_controller.isAnimating) _controller.stop();
            }

            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return GestureDetector(
                  onTap:
                      widget.onTap ??
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MobileFullPlayer(),
                        ),
                      ),
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      manager.previous();
                    } else if (details.primaryVelocity! < 0) {
                      manager.next();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.blue.shade900,
                        width: 1.5,
                      ),
                      boxShadow: isAdo
                          ? [
                              BoxShadow(
                                color: Colors.blue.shade900.withOpacity(
                                  0.6 * _pulseController.value,
                                ),
                                blurRadius: 10 * _pulseController.value,
                                spreadRadius: 2 * _pulseController.value,
                              ),
                            ]
                          : [],
                    ),
                    child: child,
                  ),
                );
              },
              child: widget.showVisualizer
                  ? _buildVisualizer()
                  : Row(
                      children: [
                        // Carátula Giratoria
                        RotationTransition(
                          turns: _controller,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.shade900,
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: song.artwork != null
                                  ? Image.memory(
                                      song.artwork!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/MG-I-T.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Información (Título y Tiempo)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              ValueListenableBuilder<Duration>(
                                valueListenable: manager.positionNotifier,
                                builder: (context, position, _) {
                                  final m = position.inMinutes;
                                  final s = (position.inSeconds % 60)
                                      .toString()
                                      .padLeft(2, '0');
                                  return Text(
                                    "$m:$s",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Botones
                        IconButton(
                          icon: Icon(
                            isPlaying ? Ionicons.pause : Ionicons.play,
                          ),
                          iconSize: 20,
                          color: Colors.white,
                          onPressed: manager.togglePlayPause,
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Ionicons.play_skip_forward),
                          iconSize: 20,
                          color: Colors.white,
                          onPressed: manager.next,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisualizer() {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              // Simulación de espectro de audio "Real"
              // Usamos múltiples ondas sinusoidales a diferentes frecuencias para simular caos/ruido
              final noise =
                  math.sin(t * 40 + index) * math.cos(t * 25 + index * 2) +
                  math.sin(t * 15 + index * 0.5);
              final normalized = noise.abs();
              final height = 8.0 + 20.0 * normalized;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

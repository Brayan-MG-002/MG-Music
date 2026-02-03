// Copyright © 2026 Brayan Medrano - MG Music
// Reproductor a pantalla completa Mobile

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_model.dart';

class MobileFullPlayer extends StatelessWidget {
  const MobileFullPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AudioPlayerManager();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "MG Music",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<LocalSong?>(
        valueListenable: manager.currentSongNotifier,
        builder: (context, song, _) {
          if (song == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Carátula
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50.0), // Más pequeña
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade900.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: song.artwork != null
                                ? Image.memory(song.artwork!, fit: BoxFit.cover)
                                : Image.asset(
                                    'assets/MG-I-T.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Espacio reducido
                // Título y Artista
                Column(
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.artist,
                      style: const TextStyle(color: Colors.grey, fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Espacio reducido
                // --- Botones de Acción (Aleatorio, Favoritos, Playlist, Repetir) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Aleatorio
                    ValueListenableBuilder<bool>(
                      valueListenable: manager.isShuffleModeNotifier,
                      builder: (context, isShuffle, _) {
                        return IconButton(
                          icon: Icon(
                            Ionicons.shuffle,
                            color: isShuffle ? Colors.blue : Colors.grey,
                            size: 26,
                          ),
                          onPressed: manager.toggleShuffleMode,
                        );
                      },
                    ),
                    // Favoritos
                    ValueListenableBuilder<List<String>>(
                      valueListenable: FavoritesManager().favoritePathsNotifier,
                      builder: (context, favoritePaths, _) {
                        final isFavorite = favoritePaths.contains(song.path);
                        final isAdo = song.artist.toLowerCase().contains('ado');
                        return _MobileHeartIcon(
                          isFavorite: isFavorite,
                          isAdo: isAdo,
                          onTap: () => FavoritesManager().toggleFavorite(song),
                        );
                      },
                    ),
                    // Agregar a Playlist
                    IconButton(
                      icon: const Icon(
                        Ionicons.add_circle_outline,
                        color: Colors.grey,
                        size: 26,
                      ),
                      onPressed: () => _showAddToPlaylistDialog(context, song),
                    ),
                    // Repetir
                    ValueListenableBuilder<LoopMode>(
                      valueListenable: manager.loopModeNotifier,
                      builder: (context, loopMode, _) {
                        Color color = Colors.grey;
                        if (loopMode == LoopMode.one ||
                            loopMode == LoopMode.all) {
                          color = Colors.blue;
                        }
                        return IconButton(
                          icon: Icon(
                            loopMode == LoopMode.one
                                ? Ionicons.repeat
                                : Ionicons.repeat,
                            color: color,
                            size: 26,
                          ),
                          onPressed: manager.toggleLoopMode,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Barra de Progreso
                ValueListenableBuilder<Duration>(
                  valueListenable: manager.positionNotifier,
                  builder: (context, position, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: manager.durationNotifier,
                      builder: (context, duration, _) {
                        return Column(
                          children: [
                            Slider(
                              activeColor: Colors.blue.shade900,
                              inactiveColor: Colors.grey.shade800,
                              value: position.inMilliseconds.toDouble().clamp(
                                0.0,
                                duration.inMilliseconds.toDouble(),
                              ),
                              min: 0.0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                manager.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.grey,
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
                ),
                const SizedBox(height: 10),

                // --- Controles Principales de Reproducción ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Anterior
                    IconButton(
                      icon: const Icon(
                        Ionicons.play_skip_back,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: manager.previous,
                    ),
                    // Play/Pause (Grande)
                    ValueListenableBuilder<bool>(
                      valueListenable: manager.isPlayingNotifier,
                      builder: (context, isPlaying, _) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade900.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 50,
                            icon: Icon(
                              isPlaying ? Ionicons.pause : Ionicons.play,
                              color: Colors.white,
                            ),
                            onPressed: manager.togglePlayPause,
                          ),
                        );
                      },
                    ),
                    // Siguiente
                    IconButton(
                      icon: const Icon(
                        Ionicons.play_skip_forward,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: manager.next,
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  void _showAddToPlaylistDialog(BuildContext context, LocalSong song) {
    final playlistManager = PlaylistManager();
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Añadir a Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: playlistManager.playlistsNotifier,
            builder: (context, playlists, _) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Ionicons.add, color: Colors.white),
                      title: const Text(
                        'Crear Nueva Playlist',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showCreatePlaylistDialog(parentContext, song);
                      },
                    );
                  }
                  final playlistName = playlists[index - 1];
                  return ListTile(
                    leading: const Icon(Ionicons.list, color: Colors.white),
                    title: Text(
                      playlistName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      final messenger = ScaffoldMessenger.of(parentContext);
                      playlistManager.addSongToPlaylist(playlistName, song);
                      Navigator.pop(dialogContext);
                      messenger.showSnackBar(
                        SnackBar(content: Text('Añadida a $playlistName')),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, LocalSong song) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) =>
          _AnimatedCreatePlaylistDialog(song: song, parentContext: context),
    );
  }
}

class _MobileHeartIcon extends StatefulWidget {
  final bool isFavorite;
  final bool isAdo;
  final VoidCallback onTap;

  const _MobileHeartIcon({
    required this.isFavorite,
    required this.isAdo,
    required this.onTap,
  });

  @override
  State<_MobileHeartIcon> createState() => _MobileHeartIconState();
}

class _MobileHeartIconState extends State<_MobileHeartIcon>
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
  void didUpdateWidget(_MobileHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateState(oldWidget.isFavorite);
  }

  void _updateState(bool wasFavorite) {
    // 1. Latido (Solo Ado)
    if (widget.isAdo) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    // 2. Neón (Ado + Favorito)
    if (widget.isAdo && widget.isFavorite) {
      _neonController.forward();
    } else {
      _neonController.reverse();
    }

    // 3. Efecto al Añadir (Transición a Favorito en Ado)
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
    return AnimatedBuilder(
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
        Color color = widget.isFavorite
            ? (widget.isAdo ? Colors.blue.shade900 : Colors.red)
            : Colors.grey;

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: Transform.scale(
            scale: scale,
            child: IconButton(
              icon: Icon(
                icon,
                color: color,
                size: 26,
                shadows: _neonController.value > 0
                    ? [
                        Shadow(
                          color: Colors.blue.shade900.withOpacity(
                            0.8 * _neonController.value,
                          ),
                          blurRadius: 15.0,
                        ),
                        Shadow(
                          color: Colors.blue.withOpacity(
                            0.5 * _neonController.value,
                          ),
                          blurRadius: 25.0,
                        ),
                      ]
                    : [],
              ),
              onPressed: widget.onTap,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedCreatePlaylistDialog extends StatefulWidget {
  final LocalSong song;
  final BuildContext parentContext;

  const _AnimatedCreatePlaylistDialog({
    required this.song,
    required this.parentContext,
  });

  @override
  State<_AnimatedCreatePlaylistDialog> createState() =>
      _AnimatedCreatePlaylistDialogState();
}

class _AnimatedCreatePlaylistDialogState
    extends State<_AnimatedCreatePlaylistDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final TextEditingController _textController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.song.artist.toLowerCase().contains('ado')) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final isAdo = widget.song.artist.toLowerCase().contains('ado');
        final glowValue = _glowController.value;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade900, width: 2),
                boxShadow: isAdo
                    ? [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(
                            0.6 * glowValue,
                          ),
                          blurRadius: 20 * glowValue,
                          spreadRadius: 5 * glowValue,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nueva Playlist',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.blue.shade900,
                    onChanged: (value) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Nombre de la playlist',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      errorText: _errorText,
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue.shade900),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final name = _textController.text.trim();
                          if (name.isNotEmpty) {
                            if (PlaylistManager().playlistsNotifier.value
                                .contains(name)) {
                              setState(() {
                                _errorText = 'Esta playlist ya existe';
                              });
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(
                              widget.parentContext,
                            );
                            PlaylistManager().createPlaylist(name);
                            PlaylistManager().addSongToPlaylist(
                              name,
                              widget.song,
                            );
                            Navigator.pop(context);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Playlist $name creada'),
                                backgroundColor: Colors.blue.shade900,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Crear',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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

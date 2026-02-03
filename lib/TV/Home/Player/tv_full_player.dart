// Copyright © 2026 Brayan Medrano - MG Music
// Reproductor a pantalla completa TV

import 'dart:math' as math;
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Logic/tv_full_player_logic.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

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

        // Usamos un builder anidado para escuchar cambios en la lista (shuffle, addNext)
        // y sincronizar el scroll cuando cambie la canción O la lista.
        return ValueListenableBuilder<List<LocalSong>>(
          valueListenable: playerManager.activePlaylistNotifier,
          builder: (context, activePlaylist, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Corrección: Scroll manual para centrar la canción actual
              if (_logic.scrollController.hasClients) {
                // Usamos indexWhere para encontrar la posición real en la lista visual
                final index = activePlaylist.indexWhere(
                  (s) => s.id == currentSong.id,
                );
                if (index >= 0) {
                  final itemHeight = _logic.itemHeight;
                  const containerHeight = 400.0; // Altura fija del contenedor
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

            return Stack(
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
                        artwork: currentSong.artwork,
                        songId: currentSong.id,
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
                            // SECCIÓN 1: Barra de Tiempo Vertical (Izquierda)
                            _TimeBarSection(
                              playerManager: playerManager,
                              logic: _logic,
                            ),

                            // SECCIÓN 2: Info + Botones Extra (Centro-Izquierda)
                            _SongInfoSection(
                              currentSong: currentSong,
                              playerManager: playerManager,
                            ),

                            // SECCIÓN 3: Controles de Reproducción (Centro-Derecha)
                            _PlaybackControlsSection(
                              playerManager: playerManager,
                            ),

                            // SECCIÓN 4: Lista de Reproducción (Derecha)
                            _PlaylistSection(
                              playerManager: playerManager,
                              logic: _logic,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 60,
                      ), // Espacio reservado para mantener el layout
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- Secciones de la UI como Widgets separados ---

class _TimeBarSection extends StatelessWidget {
  final AudioPlayerManager playerManager;
  final TvFullPlayerLogic logic;

  const _TimeBarSection({required this.playerManager, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tiempo Total (Arriba)
            ValueListenableBuilder<Duration>(
              valueListenable: playerManager.durationNotifier,
              builder: (context, duration, _) {
                return Text(
                  logic.formatDuration(duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                );
              },
            ),
            const SizedBox(height: 10),
            // Slider Vertical
            Expanded(
              child: ValueListenableBuilder<Duration>(
                valueListenable: playerManager.positionNotifier,
                builder: (context, position, _) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: playerManager.durationNotifier,
                    builder: (context, duration, _) {
                      return TvFocusableItem(
                        focusNode: logic.sliderFocusNode,
                        onKeyEvent: (node, event) =>
                            logic.handleSliderKeyEvent(context, node, event),
                        onTap: () {},
                        child: RotatedBox(
                          quarterTurns: 3, // Vertical: Abajo -> Arriba
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.blue.shade900,
                              inactiveTrackColor: Colors.grey.shade800,
                              thumbColor: Colors.blue.shade900,
                              overlayColor: Colors.blue.shade900.withOpacity(
                                0.2,
                              ),
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble().clamp(
                                0.0,
                                duration.inMilliseconds.toDouble(),
                              ),
                              min: 0.0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                playerManager.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Tiempo Actual (Abajo)
            ValueListenableBuilder<Duration>(
              valueListenable: playerManager.positionNotifier,
              builder: (context, position, _) {
                return Text(
                  logic.formatDuration(position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SongInfoSection extends StatelessWidget {
  final LocalSong currentSong;
  final AudioPlayerManager playerManager;

  const _SongInfoSection({
    required this.currentSong,
    required this.playerManager,
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
              onTap: () {}, // Foco dummy para mejorar navegación
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 750),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: ClipRRect(
                  // ¡Clave única para que AnimatedSwitcher detecte el cambio!
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
            // Título
            Text(
              currentSong.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Artista
            Text(
              currentSong.artist,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            // Botones Extra (Horizontal)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Aleatorio
                ValueListenableBuilder<bool>(
                  valueListenable: playerManager.isShuffleModeNotifier,
                  builder: (context, isShuffle, _) {
                    return _buildIconButton(
                      Ionicons.shuffle,
                      isShuffle ? Colors.blue : Colors.white,
                      playerManager.toggleShuffleMode,
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Favoritos
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
                // Playlist
                _buildIconButton(
                  Ionicons.add_circle_outline,
                  Colors.white,
                  () => _showAddToPlaylistDialog(context, currentSong),
                ),
                const SizedBox(width: 10),
                // Repetir
                ValueListenableBuilder<LoopMode>(
                  valueListenable: playerManager.loopModeNotifier,
                  builder: (context, loopMode, _) {
                    final isRepeatOne = loopMode == LoopMode.one;
                    return _buildIconButton(
                      Ionicons.repeat,
                      isRepeatOne ? Colors.blue.shade900 : Colors.white,
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

  void _showAddToPlaylistDialog(BuildContext context, LocalSong song) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(song: song),
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
            // Escala base del latido
            double scale = 1.0;
            if (widget.isAdo) {
              scale = 1.0 + (_pulseController.value * 0.2);
            }

            // Efecto de expansión y sacudida al añadir
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
              color = widget.isAdo ? Colors.blue.shade900 : Colors.red;
            }

            List<Shadow> shadows = [];
            if (_neonController.value > 0) {
              final opacity = _neonController.value;
              shadows = [
                Shadow(
                  color: Colors.blue.shade900.withOpacity(0.8 * opacity),
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

class _AddToPlaylistDialog extends StatelessWidget {
  final LocalSong song;
  const _AddToPlaylistDialog({required this.song});

  @override
  Widget build(BuildContext context) {
    final playlistManager = PlaylistManager();
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.shade900, width: 2),
      ),
      title: const Text(
        'Añadir a Playlist',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 300,
        height: 300,
        child: ValueListenableBuilder<List<String>>(
          valueListenable: playlistManager.playlistsNotifier,
          builder: (context, playlists, _) {
            return ListView.builder(
              itemCount: playlists.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildDialogOption(
                    Ionicons.add,
                    'Crear Nueva Playlist',
                    onTap: () => _showCreatePlaylistDialog(context),
                  );
                }
                final playlistName = playlists[index - 1];
                return _buildDialogOption(
                  Ionicons.list,
                  playlistName,
                  onTap: () {
                    playlistName;
                    playlistManager.addSongToPlaylist(playlistName, song);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Añadida a $playlistName'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Nombre de la Playlist',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true, // Importante para TV
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.blue.shade900,
          decoration: InputDecoration(
            hintText: 'Escribe el nombre...',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade900),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                PlaylistManager().createPlaylist(controller.text);
                PlaylistManager().addSongToPlaylist(controller.text, song);
                Navigator.pop(context); // Cierra dialogo crear
                Navigator.pop(context); // Cierra dialogo lista
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Creada y añadida a "${controller.text}"'),
                  ),
                );
              }
            },
            child: Text(
              'Crear y Añadir',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackControlsSection extends StatelessWidget {
  final AudioPlayerManager playerManager;

  const _PlaybackControlsSection({required this.playerManager});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Anterior (Arriba)
          _buildPlayerButton(
            Ionicons.chevron_up,
            () => playerManager.previous(),
            size: 30,
          ),
          const SizedBox(height: 20),
          // Play/Pause (Centro)
          ValueListenableBuilder<bool>(
            valueListenable: playerManager.isPlayingNotifier,
            builder: (context, isPlaying, _) {
              return TvFocusableItem(
                borderRadius: 50,
                onTap: playerManager.togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
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
          // Siguiente (Abajo)
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
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _PlaylistSection extends StatelessWidget {
  final AudioPlayerManager playerManager;
  final TvFullPlayerLogic logic;

  const _PlaylistSection({required this.playerManager, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Center(
        child: Container(
          height: 400,
          margin: const EdgeInsets.only(right: 30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.blue.shade900.withOpacity(0.6)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isCurrent
                        ? Border.all(color: Colors.cyanAccent.withOpacity(0.3))
                        : null,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (isCurrent)
                        const Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: Icon(
                            Ionicons.musical_note,
                            color: Colors.cyanAccent,
                            size: 18,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white60,
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
  final Uint8List? artwork;
  final int songId;

  const _MusicVisualizer({
    required this.isPlayingNotifier,
    this.artwork,
    required this.songId,
  });

  @override
  State<_MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<_MusicVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _heightsController;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  List<double> _barHeights = [];

  // Generador de números aleatorios para un comportamiento de visualizador simple.
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

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _colorAnimation = ColorTween(
      begin: Colors.cyanAccent,
      end: Colors.cyanAccent,
    ).animate(_colorController);

    _updateColor();
  }

  @override
  void didUpdateWidget(_MusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.artwork != oldWidget.artwork) {
      _updateColor();
    }
    // Si la canción cambia, resetea las alturas de las barras para evitar el efecto "fantasma".
    if (widget.songId != oldWidget.songId) {
      // Resetea las alturas de las barras al estado inicial para evitar "fantasmas" de la canción anterior.
      // setState fuerza una reconstrucción inmediata con las barras en su estado base.
      setState(() {
        _barHeights = List.filled(48, 5.0);
      });
    }
  }

  Future<void> _updateColor() async {
    if (widget.artwork == null) {
      _animateToColor(Colors.cyanAccent);
      return;
    }
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        // OPTIMIZACIÓN: Redimensionar la imagen antes de procesar los colores.
        // Esto evita que la UI se trabe al cambiar de canción con imágenes grandes.
        ResizeImage(MemoryImage(widget.artwork!), width: 100, height: 100),
        maximumColorCount: 10,
      );
      final newColor =
          generator.dominantColor?.color ??
          generator.vibrantColor?.color ??
          Colors.cyanAccent;
      _animateToColor(newColor);
    } catch (_) {
      _animateToColor(Colors.cyanAccent);
    }
  }

  void _animateToColor(Color newColor) {
    if (!mounted) return;
    final beginColor = _colorAnimation.value ?? Colors.cyanAccent;
    setState(() {
      _colorAnimation = ColorTween(begin: beginColor, end: newColor).animate(
        CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
      );
    });
    _colorController.forward(from: 0.0);
  }

  void _updateHeights() {
    // Si la música está sonando, se aplica la lógica completa de impulsos y gravedad.
    if (widget.isPlayingNotifier.value) {
      // Simula un "kick" de batería con una probabilidad baja para sincronizar los bajos.
      final bool kick = _random.nextDouble() < 0.08;

      for (int i = 0; i < _barHeights.length; i++) {
        // 1. Aplicar Gravedad: Las barras caen constantemente.
        // Las barras de bajos (izquierda) caen más lento para dar sensación de "peso".
        final double gravity = (i < 12) ? 2.0 : 4.0;
        _barHeights[i] = math.max(5.0, _barHeights[i] - gravity);

        // 2. Calcular Probabilidad y Potencia de Impulso por zona.
        double impulseProbability = 0.0;
        double maxImpulseHeight = 0.0;

        if (i < 12) {
          // Zona de Bajos
          impulseProbability = kick ? 0.95 : 0.05;
          maxImpulseHeight = 100.0;
        } else if (i < 32) {
          // Zona de Medios
          impulseProbability = 0.04;
          maxImpulseHeight = 60.0;
        } else {
          // Zona de Agudos
          impulseProbability = 0.07;
          maxImpulseHeight = 45.0;
        }

        // 3. Aplicar Impulso
        if (_random.nextDouble() < impulseProbability) {
          final double newHeight =
              10.0 + _random.nextDouble() * (maxImpulseHeight - 10.0);
          if (newHeight > _barHeights[i]) {
            _barHeights[i] = newHeight;
          }
        }
      }
    } else {
      // Si la música está en pausa, solo se aplica la gravedad hasta que todas las barras lleguen al mínimo.
      bool allBarsAtMinimum = true;
      for (int i = 0; i < _barHeights.length; i++) {
        // Se aplica una gravedad constante para una caída suave.
        _barHeights[i] = math.max(5.0, _barHeights[i] - 3.0);
        if (_barHeights[i] > 5.0) {
          allBarsAtMinimum = false;
        }
      }

      // Si todas las barras han caído, detenemos el controlador para ahorrar recursos.
      if (allBarsAtMinimum && _heightsController.isAnimating) {
        _heightsController.stop();
      }
    }
  }

  @override
  void dispose() {
    _heightsController.removeListener(_updateHeights);
    _heightsController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        // Cuando la música empieza a sonar, nos aseguramos de que el controlador esté activo.
        // El controlador ya no se detiene aquí al pausar, la lógica de `_updateHeights` se encarga de eso.
        if (isPlaying && !_heightsController.isAnimating) {
          _heightsController.repeat();
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_heightsController, _colorController]),
          builder: (context, child) {
            return CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _VisualizerPainter(
                heights: _barHeights,
                color: _colorAnimation.value ?? Colors.cyanAccent,
              ),
            );
          },
        );
      },
    );
  }
}

/// Painter optimizado para el visualizador de música.
/// Dibuja todas las barras en un solo canvas
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

      // El shader se crea por barra para que el gradiente se ajuste a la altura
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
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    // El repintado es controlado por el AnimatedBuilder que lo contiene,
    // por lo que siempre devolvemos true para redibujar con los nuevos datos.
    return true;
  }
}

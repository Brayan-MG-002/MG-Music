// Copyright © 2026 Brayan Medrano - MG Music
// Página de inicio Mobile

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileHomePage extends StatefulWidget {
  final VoidCallback? onOpenPlayer;
  const MobileHomePage({super.key, this.onOpenPlayer});

  @override
  State<MobileHomePage> createState() => MobileHomePageState();
}

class MobileHomePageState extends State<MobileHomePage>
    with AutomaticKeepAliveClientMixin {
  final SongFetcher _songFetcher = SongFetcher();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  List<LocalSong> _allSongs = [];
  List<LocalSong> _displayedSongs = [];
  bool _isLoading = true;
  bool _isGridView = true;
  int _currentSortMode = 0; // 0: Patrona, 1: A-Z, 2: Z-A
  final ScrollController _scrollController = ScrollController();

  // Getter para que el MainScreen pueda obtener la lista de artistas
  List<LocalSong> get allSongs => _allSongs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerManager.init();
    _loadPreferencesAndSongs();
  }

  Future<void> _loadPreferencesAndSongs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool('home_view_mode') ?? true;
        _currentSortMode = prefs.getInt('home_sort_mode') ?? 0;
      });
    }
    await _loadSongs();
  }

  Future<void> _loadSongs() async {
    // 1. Usar caché si existe (Lógica reutilizada del TV)
    if (_playerManager.cachedSongs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allSongs = _playerManager.cachedSongs;
          _displayedSongs = List.from(_allSongs);
          _applySort();
          _isLoading = false;
        });
      }
      await _playerManager.executeStartupBehavior(_allSongs);
      if (mounted) _scrollToCurrentSong();
    } else {
      _playerManager.isRestoringNotifier.value = true;
    }

    // 2. Escaneo en segundo plano mediante Stream para carga progresiva
    _songFetcher
        .getSongsStream(chunkSize: 15)
        .listen(
          (chunk) {
            if (!mounted) return;

            setState(() {
              final existingIds = _allSongs.map((s) => s.id).toSet();
              for (var song in chunk) {
                if (!existingIds.contains(song.id)) {
                  _allSongs.add(song);
                }
              }
              _displayedSongs = List.from(_allSongs);
              _applySort();

              // Si es el primer chunk, quitamos la pantalla de carga inmediatamente
              if (_isLoading) {
                _isLoading = false;
              }
            });
          },
          onDone: () async {
            // Cuando termina la carga de todas las canciones
            await _playerManager.executeStartupBehavior(_allSongs);
            if (mounted) _scrollToCurrentSong();
          },
        );
  }

  // Aplica el ordenamiento actual basado en _currentSortMode
  void _applySort() {
    setState(() {
      if (_currentSortMode == 0) {
        // La Patrona (Ado primero)
        _displayedSongs.sort((a, b) {
          final aIsAdo = a.artist.toLowerCase().contains('ado');
          final bIsAdo = b.artist.toLowerCase().contains('ado');
          if (aIsAdo && !bIsAdo) return -1;
          if (!aIsAdo && bIsAdo) return 1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      } else {
        // Alfabético (1: A-Z, 2: Z-A)
        final ascending = _currentSortMode == 1;
        _displayedSongs.sort(
          (a, b) => ascending
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
      }
      _playerManager.updatePlaylist(_displayedSongs);
    });
  }

  // Lógica de ordenamiento "La Patrona" (Ado primero)
  void sortLaPatrona() {
    _currentSortMode = 0;
    _saveSortMode(0);
    _applySort();
  }

  // Ordenamiento Alfabético (A-Z y Z-A)
  void sortAlphabetical(bool ascending) {
    _currentSortMode = ascending ? 1 : 2;
    _saveSortMode(_currentSortMode);
    _applySort();
  }

  // Filtrado por Artista (Maneja múltiples artistas separados por coma)
  void filterByArtist(String? artist) {
    setState(() {
      if (artist == null) {
        _displayedSongs = List.from(_allSongs);
      } else {
        _displayedSongs = _allSongs.where((s) {
          final artists = s.artist.split(',').map((a) => a.trim()).toList();
          return artists.contains(artist);
        }).toList();
      }
      _playerManager.updatePlaylist(_displayedSongs);
    });
  }

  // Búsqueda por título o artista
  void searchSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedSongs = List.from(_allSongs);
        _applySort(); // Vuelve al orden guardado
      } else {
        final lowerCaseQuery = query.toLowerCase();
        _displayedSongs = _allSongs.where((song) {
          final title = song.title.toLowerCase();
          final artist = song.artist.toLowerCase();
          return title.contains(lowerCaseQuery) ||
              artist.contains(lowerCaseQuery);
        }).toList();
      }
      _playerManager.updatePlaylist(_displayedSongs);
    });
  }

  Future<void> _saveViewMode(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_view_mode', isGrid);
  }

  Future<void> _saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_sort_mode', mode);
  }

  void _scrollToCurrentSong() {
    final currentSong = _playerManager.currentSongNotifier.value;
    if (currentSong == null || _displayedSongs.isEmpty) return;

    final index = _displayedSongs.indexWhere((s) => s.id == currentSong.id);
    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      double offset = 0;
      if (_isGridView) {
        try {
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = 3;
          final crossAxisSpacing = 16.0;
          final paddingHorizontal = 32.0;
          final itemWidth =
              (screenWidth -
                  paddingHorizontal -
                  (crossAxisSpacing * (crossAxisCount - 1))) /
              crossAxisCount;
          final itemHeight = itemWidth / 0.7;
          final mainAxisSpacing = 16.0;
          final row = index ~/ crossAxisCount;
          offset = row * (itemHeight + mainAxisSpacing);
        } catch (_) {}
      } else {
        offset = index * 80.0;
      }

      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Column(
      children: [
        // Cabecera con Título y Botones (Restaurada)
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _isGridView ? Ionicons.list : Ionicons.grid,
                  color: Colors.white,
                ),
                onPressed: () => setState(() {
                  _isGridView = !_isGridView;
                  _saveViewMode(_isGridView);
                }),
                splashRadius: 20,
              ),
              const Text(
                'MG Music',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _playerManager.isShuffleModeNotifier,
                builder: (context, isShuffle, _) {
                  return IconButton(
                    icon: Icon(
                      Ionicons.shuffle,
                      color: isShuffle ? Colors.blue.shade900 : Colors.white,
                    ),
                    onPressed: () {
                      if (isShuffle) {
                        _playerManager.toggleShuffleMode();
                      } else {
                        _playerManager.shufflePlay(_displayedSongs);
                      }
                    },
                    splashRadius: 20,
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSongs,
            color: Colors.blue.shade900,
            backgroundColor: Colors.grey.shade900,
            child: _isGridView
                ? GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _displayedSongs.length,
                    itemBuilder: (context, index) {
                      final song = _displayedSongs[index];
                      final isAdo = song.artist.toLowerCase().contains('ado');
                      return ValueListenableBuilder<LocalSong?>(
                        valueListenable: _playerManager.currentSongNotifier,
                        builder: (context, currentSong, _) {
                          final isPlaying = currentSong?.id == song.id;
                          return _MobileSongItem(
                            song: song,
                            isAdo: isAdo,
                            isGrid: true,
                            isPlaying: isPlaying,
                            onTap: () {
                              if (isPlaying) {
                                widget.onOpenPlayer?.call();
                              } else {
                                _playerManager.playSong(song, _displayedSongs);
                              }
                            },
                          );
                        },
                      );
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemExtent: 80,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 20,
                    ),
                    itemCount: _displayedSongs.length,
                    itemBuilder: (context, index) {
                      final song = _displayedSongs[index];
                      final isAdo = song.artist.toLowerCase().contains('ado');
                      return ValueListenableBuilder<LocalSong?>(
                        valueListenable: _playerManager.currentSongNotifier,
                        builder: (context, currentSong, _) {
                          final isPlaying = currentSong?.id == song.id;
                          return _MobileSongItem(
                            song: song,
                            isAdo: isAdo,
                            isGrid: false,
                            isPlaying: isPlaying,
                            onTap: () {
                              if (isPlaying) {
                                widget.onOpenPlayer?.call();
                              } else {
                                _playerManager.playSong(song, _displayedSongs);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _MobileSongItem extends StatefulWidget {
  final LocalSong song;
  final bool isAdo;
  final VoidCallback onTap;
  final bool isGrid;
  final bool isPlaying;

  const _MobileSongItem({
    required this.song,
    required this.isAdo,
    required this.onTap,
    required this.isGrid,
    this.isPlaying = false,
  });

  @override
  State<_MobileSongItem> createState() => _MobileSongItemState();
}

class _MobileSongItemState extends State<_MobileSongItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeInController;
  late AnimationController _shakeController; // Para sacudida al agregar

  @override
  void initState() {
    super.initState();
    // Controlador para el efecto Glow de Ado
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Controlador para sacudida
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Controlador para la aparición suave (Fade In)
    _fadeInController = AnimationController(
      duration: const Duration(
        milliseconds: 250,
      ), // Más rápido para evitar lag visual
      vsync: this,
    )..forward();

    // Optimización: Solo iniciar animación si es Ado Y es Grid para evitar lag
    if (widget.isAdo && widget.isGrid) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_MobileSongItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdo != oldWidget.isAdo || widget.isGrid != oldWidget.isGrid) {
      if (widget.isAdo && widget.isGrid) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  void dispose() {
    _controller.dispose();
    _fadeInController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _showOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.blue.shade900, width: 2),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.song.artwork != null
                      ? Image.memory(
                          widget.song.artwork!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Image.asset('assets/MG-I-T.png', width: 50),
                ),
                title: Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.song.artist,
                  style: TextStyle(color: Colors.blue.shade400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.grey),
              _buildModalOption(
                Ionicons.play_skip_forward_outline,
                "Reproducir Siguiente",
                action: () {
                  AudioPlayerManager().addNext(widget.song);
                },
              ),
              // Opción Favoritos dinámica
              ValueListenableBuilder<List<String>>(
                valueListenable: FavoritesManager().favoritePathsNotifier,
                builder: (context, favs, _) {
                  final isFav = favs.contains(widget.song.path);
                  return _buildModalOption(
                    isFav ? Ionicons.heart_dislike : Ionicons.heart,
                    isFav ? "Quitar de Favoritos" : "Agregar a Favoritos",
                    action: () => _toggleFavorite(),
                  );
                },
              ),
              _buildModalOption(
                Ionicons.add_circle_outline,
                "Agregar a Playlist",
                action: () => _showAddToPlaylistDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleFavorite() {
    FavoritesManager().toggleFavorite(widget.song);
    final isFav = FavoritesManager().isFavorite(widget.song);

    if (isFav && widget.isAdo) {
      _shakeController.forward(from: 0).then((_) => _shakeController.reset());
    }
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    final playlistManager = PlaylistManager();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              return ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Ionicons.add, color: Colors.blue),
                    title: const Text(
                      'Crear Nueva Playlist',
                      style: TextStyle(color: Colors.blue),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(context);
                    },
                  ),
                  ...playlists.map(
                    (name) => ListTile(
                      leading: const Icon(Ionicons.list, color: Colors.white),
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        playlistManager.addSongToPlaylist(name, widget.song);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Añadida a $name')),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
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
        title: const Text(
          'Nueva Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                PlaylistManager().createPlaylist(controller.text);
                PlaylistManager().addSongToPlaylist(
                  controller.text,
                  widget.song,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Crear', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildModalOption(IconData icon, String text, {VoidCallback? action}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () {
        action?.call();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => _showOptionsModal(context),
      child: FadeTransition(
        opacity: _fadeInController,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _shakeController]),
          builder: (context, child) {
            // Efecto de brillo sutil para Ado
            final glowColor = (widget.isAdo && widget.isGrid)
                ? Colors.blue.shade900.withOpacity(
                    0.3 + (_controller.value * 0.3),
                  )
                : Colors.transparent;

            // Efecto de sacudida
            double offsetX = 0;
            if (_shakeController.isAnimating) {
              offsetX =
                  5.0 *
                  (0.5 - (0.5 - _shakeController.value).abs()) *
                  4 *
                  (1 - _shakeController.value);
              if (_shakeController.value > 0.5) offsetX = -offsetX;
            }

            Color? borderColor;
            if (widget.isPlaying) {
              borderColor = Colors.blueAccent;
            } else if (widget.isAdo) {
              borderColor = Colors.blue.shade900;
            }

            return Transform.translate(
              offset: Offset(offsetX, 0),
              child: Container(
                margin: widget.isGrid
                    ? null
                    : const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: borderColor != null
                      ? Border.all(
                          color: borderColor,
                          width: widget.isPlaying ? 2.0 : 1.5,
                        )
                      : null,
                  boxShadow: (widget.isAdo && widget.isGrid)
                      ? [
                          BoxShadow(
                            color: glowColor,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: widget.isGrid
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: widget.song.artwork != null
                                  ? Image.memory(
                                      widget.song.artwork!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey.shade800,
                                      child: Center(
                                        child: Image.asset(
                                          'assets/MG-I-T.png',
                                          width: 50,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: widget.isPlaying
                                        ? Colors.blueAccent
                                        : (widget.isAdo
                                              ? Colors.blue.shade200
                                              : Colors.white),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: widget.song.artwork != null
                                  ? Image.memory(
                                      widget.song.artwork!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade800,
                                      child: Image.asset('assets/MG-I-T.png'),
                                    ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: widget.isPlaying
                                        ? Colors.blueAccent
                                        : (widget.isAdo
                                              ? Colors.blue.shade200
                                              : Colors.white),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Ionicons.ellipsis_vertical,
                              color: Colors.white,
                            ),
                            onPressed: () => _showOptionsModal(context),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

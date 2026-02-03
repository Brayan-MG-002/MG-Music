// Copyright © 2026 Brayan Medrano - MG Music
// Página de inicio TV con grid de canciones

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/TV/Home/Player/tv_player_widget.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

/// Página de inicio TV con grid de canciones y opciones de filtrado
class TvHomePage extends StatefulWidget {
  final VoidCallback onOpenPlayer;
  const TvHomePage({super.key, required this.onOpenPlayer});

  @override
  State<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends State<TvHomePage>
    with AutomaticKeepAliveClientMixin {
  final SongFetcher _songFetcher = SongFetcher();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  List<LocalSong> _allSongs = [];
  List<LocalSong> _displayedSongs = [];
  bool _isLoading = true;
  bool _isAscending = true;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerManager.init();
    _loadSongs();

    // Escuchar cambios en la canción actual para hacer scroll automático
    _playerManager.currentSongNotifier.addListener(_scrollToCurrentSong);
  }

  @override
  void dispose() {
    _playerManager.currentSongNotifier.removeListener(_scrollToCurrentSong);
    _scrollController.dispose();
    super.dispose();
  }

  /// Hace scroll automático a la canción que está sonando
  void _scrollToCurrentSong() {
    final currentSong = _playerManager.currentSongNotifier.value;
    if (currentSong == null || _displayedSongs.isEmpty) return;

    final index = _displayedSongs.indexWhere((s) => s.id == currentSong.id);
    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      try {
        // Calcular la posición del elemento en la grilla
        // 5 columnas (crossAxisCount: 5)
        const crossAxisCount = 5;
        const itemHeight = 200.0;
        const mainAxisSpacing = 20.0;

        final row = index ~/ crossAxisCount;
        final offset = row * (itemHeight + mainAxisSpacing);

        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
        // Si hay error en el cálculo, simplemente ignorar
      }
    });
  }

  /// Carga canciones desde caché o del dispositivo
  Future<void> _loadSongs() async {
    if (_playerManager.cachedSongs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allSongs = _playerManager.cachedSongs;
          _displayedSongs = List.from(_allSongs);
          _sortLaPatrona();
          _isLoading = false;
        });
      }
      _playerManager.executeStartupBehavior(_allSongs);
    } else {
      _playerManager.isRestoringNotifier.value = true;
    }

    final freshSongs = await _songFetcher.getSongs();

    if (mounted) {
      setState(() {
        _allSongs = freshSongs;
        _displayedSongs = List.from(freshSongs);
        _sortLaPatrona();
        _isLoading = false;
      });
    }

    await _playerManager.executeStartupBehavior(freshSongs);
  }

  /// Ordena canciones alfabéticamente
  void _sortSongs(bool ascending) {
    setState(() {
      _isAscending = ascending;
      _displayedSongs.sort(
        (a, b) => ascending
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
      _playerManager.updatePlaylist(_displayedSongs);
    });
  }

  /// Ordena con Ado primero, luego alfabético
  void _sortLaPatrona() {
    setState(() {
      _displayedSongs.sort((a, b) {
        final aIsAdo = a.artist.toLowerCase().contains('ado');
        final bIsAdo = b.artist.toLowerCase().contains('ado');
        if (aIsAdo && !bIsAdo) return -1;
        if (!aIsAdo && bIsAdo) return 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      _playerManager.updatePlaylist(_displayedSongs);
    });
  }

  /// Filtra canciones por artista
  void _filterByArtist(String? artist) {
    setState(() {
      if (artist == null) {
        _displayedSongs = List.from(_allSongs);
      } else {
        _displayedSongs = _allSongs.where((s) {
          final songArtists = s.artist.split(',').map((a) => a.trim());
          return songArtists.contains(artist);
        }).toList();
      }
      _sortSongs(_isAscending);
      _playerManager.updatePlaylist(_displayedSongs);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para el KeepAlive
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    if (_displayedSongs.isEmpty && _allSongs.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron canciones en la carpeta Music.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila de botones de acción (Filtros y Reproducción)
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            color:
                Colors.black, // Fondo sólido para evitar superposición visual
            // Borde inferior azul oscuro
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade900, width: 3),
            ),
            // Esquinas inferiores redondeadas
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              // Aleatorio a la izquierda
              _buildActionButton(Ionicons.shuffle, 'Aleatorio', () {
                _playerManager.shufflePlay(_displayedSongs);
              }),
              // Reproductor Central
              Expanded(
                child: TvPlayerWidget(
                  onTap: () {
                    widget.onOpenPlayer();
                  },
                ),
              ),
              // Ordenar
              _buildActionButton(Ionicons.swap_vertical, 'Orden', () {
                _showSortMenu(context);
              }),
              const SizedBox(width: 15), // Separación entre botones
              // Artistas
              _buildActionButton(Ionicons.people_outline, 'Artistas', () {
                _showArtistMenu(context);
              }),
            ],
          ),
        ),
        // Contenido Principal: Cuadrícula o Reproductor Completo
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.05, 0.95, 1.0], // Desvanecimiento en bordes
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: GridView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              cacheExtent:
                  500, // Optimización: Reducido para ahorrar memoria con imágenes
              padding: const EdgeInsets.all(24.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.85,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: _displayedSongs.length,
              itemBuilder: (context, index) {
                final song = _displayedSongs[index];
                final isAdo = song.artist.toLowerCase().contains('ado');

                return _SongGridItem(
                  song: song,
                  isAdo: isAdo,
                  onLongPress: () => _showSongOptions(context, song),
                  onTap: () {
                    if (_playerManager.currentSongNotifier.value?.id ==
                        song.id) {
                      widget.onOpenPlayer();
                    } else {
                      _playerManager.playSong(song, _displayedSongs);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  /// Muestra menú para ordenar canciones
  void _showSortMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Ordenar por',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuOption(Ionicons.star, 'La Patrona (Ado primero)', () {
              _sortLaPatrona();
              Navigator.pop(context);
            }),
            _buildMenuOption(Ionicons.text, 'Alfabético (A-Z)', () {
              _sortSongs(true);
              Navigator.pop(context);
            }),
            _buildMenuOption(Ionicons.swap_vertical, 'Inverso (Z-A)', () {
              _sortSongs(false);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  /// Muestra menú para filtrar por artista
  void _showArtistMenu(BuildContext context) {
    // Obtener lista única de artistas
    final artists = _allSongs
        .expand((s) => s.artist.split(',').map((a) => a.trim()))
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList();
    artists.sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Seleccionar Artista',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildMenuOption(Ionicons.people, 'Todos los artistas', () {
                _filterByArtist(null); // Mostrar todos
                Navigator.pop(context);
              }),
              ...artists.map(
                (artist) => _buildMenuOption(Ionicons.person, artist, () {
                  _filterByArtist(artist);
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menú contextual para opciones de canción
  void _showSongOptions(BuildContext context, LocalSong song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
          title: Text(
            song.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuOption(
                Ionicons.play_forward,
                'Reproducir siguiente',
                () async {
                  _playerManager.addNext(song);

                  // Mostrar snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Siguiente: ${song.title}')),
                  );
                  Navigator.pop(context);
                },
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: FavoritesManager().favoritePathsNotifier,
                builder: (context, favoritePaths, _) {
                  final isFavorite = favoritePaths.contains(song.path);
                  final isAdo = song.artist.toLowerCase().contains('ado');

                  final icon = isFavorite
                      ? Ionicons.heart
                      : Ionicons.heart_outline;
                  final color = isFavorite
                      ? (isAdo ? Colors.blue.shade900 : Colors.red)
                      : Colors.white70;

                  return _buildMenuOption(
                    icon,
                    isFavorite ? 'Quitar de Favoritos' : 'Agregar a Favoritos',
                    () {
                      FavoritesManager().toggleFavorite(song);
                      Navigator.pop(context);
                    },
                    iconColor: color,
                  );
                },
              ),
              _buildMenuOption(Ionicons.list, 'Añadir a Playlist', () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, song);
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, LocalSong song) {
    showDialog(
      context: context,
      builder: (context) => _AddToPlaylistDialog(song: song),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String text,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 20),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de elemento de canción en grid con animación
class _SongGridItem extends StatelessWidget {
  final LocalSong song;
  final bool isAdo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SongGridItem({
    super.key,
    required this.song,
    required this.isAdo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final playerManager = AudioPlayerManager();

    // Animación de entrada (Fade In) al aparecer
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child!);
      },
      child: ValueListenableBuilder<LocalSong?>(
        valueListenable: playerManager.currentSongNotifier,
        builder: (context, currentSong, _) {
          final isPlaying = currentSong?.id == song.id;

          return TvFocusableItem(
            onLongPress: onLongPress,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: isPlaying
                          ? Border.all(color: Colors.blueAccent, width: 3)
                          : isAdo
                          ? Border.all(color: Colors.blue.shade900, width: 2)
                          : null,
                      boxShadow: [
                        if (isPlaying)
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                      ],
                      image: song.artwork != null
                          ? DecorationImage(
                              image: ResizeImage(
                                MemoryImage(song.artwork!),
                                width:
                                    250, // Optimización: Carga imagen reducida
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey.shade800,
                    ),
                    child: song.artwork == null
                        ? Center(
                            child: Image.asset('assets/MG-I-T.png', width: 60),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying
                          ? Colors.blueAccent
                          : (isAdo ? Colors.blue.shade900 : Colors.white),
                      fontWeight: isPlaying || isAdo
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: isPlaying ? 13 : 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
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
          autofocus: true,
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

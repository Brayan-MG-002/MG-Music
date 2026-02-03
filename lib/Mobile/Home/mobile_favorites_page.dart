// Copyright © 2026 Brayan Medrano - MG Music
// Página de favoritos Mobile

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileFavoritesPage extends StatefulWidget {
  final ValueChanged<bool> onSelectionModeChanged;
  final VoidCallback? onOpenPlayer;

  const MobileFavoritesPage({
    super.key,
    required this.onSelectionModeChanged,
    this.onOpenPlayer,
  });

  @override
  State<MobileFavoritesPage> createState() => MobileFavoritesPageState();
}

class MobileFavoritesPageState extends State<MobileFavoritesPage>
    with AutomaticKeepAliveClientMixin {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  final SongFetcher _songFetcher = SongFetcher();

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  List<LocalSong> _favoriteSongs = [];
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteSongs();
    _favoritesManager.favoritePathsNotifier.addListener(_loadFavoriteSongs);
  }

  @override
  void dispose() {
    _favoritesManager.favoritePathsNotifier.removeListener(_loadFavoriteSongs);
    super.dispose();
  }

  Future<void> refreshViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isGrid = prefs.getBool('home_view_mode') ?? true;
    if (mounted && _isGridView != isGrid) {
      setState(() => _isGridView = isGrid);
    }
  }

  Future<void> _loadFavoriteSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final isGrid = prefs.getBool('home_view_mode') ?? true;

    final allSongs = await _songFetcher.getSongs();
    final favoritePaths = _favoritesManager.getFavoritePaths();

    final favorites = allSongs
        .where((song) => favoritePaths.contains(song.path))
        .toList();

    // Ordenar con "Ado" primero (Lógica TV)
    favorites.sort((a, b) {
      final aIsAdo = a.artist.toLowerCase().contains('ado');
      final bIsAdo = b.artist.toLowerCase().contains('ado');
      if (aIsAdo && !bIsAdo) return -1;
      if (!aIsAdo && bIsAdo) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _favoriteSongs = favorites;
        _isGridView = isGrid;
        _isLoading = false;
      });
    }
  }

  // Método llamado desde el MainScreen
  void playFavorites() {
    if (_favoriteSongs.isNotEmpty) {
      _playerManager.playSong(_favoriteSongs.first, _favoriteSongs);
    }
  }

  // Método llamado desde el MainScreen
  void handleDeleteAction() {
    if (!_isSelectionMode) {
      // Entrar en modo selección
      setState(() {
        _isSelectionMode = true;
        _selectedIds.clear();
      });
      widget.onSelectionModeChanged(true);
    } else {
      // Eliminar seleccionados
      if (_selectedIds.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.blue.shade900, width: 2),
            ),
            title: const Text(
              '¿Eliminar de Favoritos?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Se eliminarán ${_selectedIds.length} canciones de tu lista de favoritos.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSelectedSongs();
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      } else {
        _exitSelectionMode();
      }
    }
  }

  void _deleteSelectedSongs() {
    final songsToDelete = _favoriteSongs
        .where((s) => _selectedIds.contains(s.id.toString()))
        .toList();

    for (var song in songsToDelete) {
      _favoritesManager.removeFavorite(song);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${songsToDelete.length} canciones eliminadas de favoritos',
        ),
        backgroundColor: Colors.blue.shade900,
        duration: const Duration(seconds: 2),
      ),
    );
    _exitSelectionMode();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    widget.onSelectionModeChanged(false);
  }

  void _toggleSelection(String songId) {
    setState(() {
      if (_selectedIds.contains(songId)) {
        _selectedIds.remove(songId);
      } else {
        _selectedIds.add(songId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_favoriteSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.heart_dislike_outline, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'No tienes favoritos aún',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _favoriteSongs.length,
        itemBuilder: (context, index) {
          return _FavoriteSongItem(
            song: _favoriteSongs[index],
            isGrid: true,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedIds.contains(
              _favoriteSongs[index].id.toString(),
            ),
            onTap: () => _handleItemTap(_favoriteSongs[index]),
            onLongPress: () => _handleItemLongPress(_favoriteSongs[index]),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _favoriteSongs.length,
        itemBuilder: (context, index) {
          return _FavoriteSongItem(
            song: _favoriteSongs[index],
            isGrid: false,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedIds.contains(
              _favoriteSongs[index].id.toString(),
            ),
            onTap: () => _handleItemTap(_favoriteSongs[index]),
            onLongPress: () => _handleItemLongPress(_favoriteSongs[index]),
            onOptionTap: () =>
                _showOptionsModal(context, _favoriteSongs[index]),
          );
        },
      );
    }
  }

  void _handleItemTap(LocalSong song) {
    if (_isSelectionMode) {
      _toggleSelection(song.id.toString());
    } else {
      if (_playerManager.currentSongNotifier.value?.id == song.id) {
        widget.onOpenPlayer?.call();
      } else {
        _playerManager.playSong(song, _favoriteSongs);
      }
    }
  }

  void _handleItemLongPress(LocalSong song) {
    if (!_isSelectionMode) {
      _showOptionsModal(context, song);
    } else {
      _toggleSelection(song.id.toString());
    }
  }

  void _showOptionsModal(BuildContext context, LocalSong song) {
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
                leading: const Icon(
                  Ionicons.play_skip_forward_outline,
                  color: Colors.white,
                ),
                title: const Text(
                  "Reproducir Siguiente",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  AudioPlayerManager().addNext(song);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Ionicons.heart_dislike, color: Colors.red),
                title: const Text(
                  "Quitar de Favoritos",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  _favoritesManager.removeFavorite(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Canción eliminada de favoritos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Ionicons.add_circle_outline,
                  color: Colors.white,
                ),
                title: const Text(
                  "Agregar a Playlist",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, LocalSong song) {
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
                      _showCreatePlaylistDialog(context, song);
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
                        playlistManager.addSongToPlaylist(name, song);
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

  void _showCreatePlaylistDialog(BuildContext context, LocalSong song) {
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
                PlaylistManager().addSongToPlaylist(controller.text, song);
                Navigator.pop(context);
              }
            },
            child: const Text('Crear', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}

class _FavoriteSongItem extends StatefulWidget {
  final LocalSong song;
  final bool isGrid;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onOptionTap;

  const _FavoriteSongItem({
    required this.song,
    required this.isGrid,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.onOptionTap,
  });

  @override
  State<_FavoriteSongItem> createState() => _FavoriteSongItemState();
}

class _FavoriteSongItemState extends State<_FavoriteSongItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeInController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..forward();

    final isAdo = widget.song.artist.toLowerCase().contains('ado');
    if (isAdo && widget.isGrid) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdo = widget.song.artist.toLowerCase().contains('ado');

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: FadeTransition(
        opacity: _fadeInController,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glowColor = (isAdo && widget.isGrid)
                ? Colors.blue.shade900.withOpacity(
                    0.3 + (_controller.value * 0.3),
                  )
                : Colors.transparent;

            return Container(
              margin: widget.isGrid ? null : const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: widget.isSelectionMode && widget.isSelected
                    ? Colors.blue.shade900.withOpacity(0.3)
                    : Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelectionMode && widget.isSelected
                    ? Border.all(color: Colors.blue.shade900, width: 2)
                    : (isAdo && widget.isGrid
                          ? Border.all(color: Colors.blue.shade900, width: 1.5)
                          : null),
                boxShadow: (isAdo && widget.isGrid)
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
                  ? _buildGridContent(isAdo)
                  : _buildListContent(isAdo),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridContent(bool isAdo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: widget.song.artwork != null
                    ? Image.memory(
                        widget.song.artwork!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: Center(
                          child: Image.asset('assets/MG-I-T.png', width: 50),
                        ),
                      ),
              ),
              if (widget.isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    widget.isSelected
                        ? Ionicons.checkbox
                        : Ionicons.square_outline,
                    color: widget.isSelected ? Colors.blue : Colors.white,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
            ],
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
                  color: isAdo ? Colors.blue.shade200 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                widget.song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(bool isAdo) {
    return Row(
      children: [
        if (widget.isSelectionMode)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              widget.isSelected ? Ionicons.checkbox : Ionicons.square_outline,
              color: widget.isSelected ? Colors.blue : Colors.grey,
            ),
          ),
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
            children: [
              Text(
                widget.song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isAdo ? Colors.blue.shade200 : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
        if (!widget.isSelectionMode && widget.onOptionTap != null)
          IconButton(
            icon: const Icon(Ionicons.ellipsis_vertical, color: Colors.white),
            onPressed: widget.onOptionTap,
          ),
      ],
    );
  }
}

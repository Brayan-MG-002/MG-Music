// Copyright © 2026 Brayan Medrano - MG Music
// Página de playlists Mobile

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobilePlaylistsPage extends StatefulWidget {
  final VoidCallback
  onStateChanged; // Para notificar al MainScreen cambios de estado (dentro/fuera de playlist)
  final VoidCallback? onOpenPlayer;

  const MobilePlaylistsPage({
    super.key,
    required this.onStateChanged,
    this.onOpenPlayer,
  });

  @override
  State<MobilePlaylistsPage> createState() => MobilePlaylistsPageState();
}

class MobilePlaylistsPageState extends State<MobilePlaylistsPage>
    with AutomaticKeepAliveClientMixin {
  final PlaylistManager _playlistManager = PlaylistManager();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  final SongFetcher _songFetcher = SongFetcher();
  List<LocalSong> _allSongs = [];

  // Estado
  String?
  _currentPlaylistName; // Si es null, mostramos la lista de playlists. Si tiene valor, mostramos el detalle.
  List<LocalSong> _currentPlaylistSongs = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isGridView = true; // Se carga de preferencias globales

  bool get isInsidePlaylist => _currentPlaylistName != null;
  bool get isSelectionMode => _isSelectionMode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadAllSongs();
  }

  Future<void> _loadAllSongs() async {
    final songs = await _songFetcher.getSongs();
    if (mounted) setState(() => _allSongs = songs);
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool('home_view_mode') ?? true;
      });
    }
  }

  // Método público para refrescar el modo de vista (llamado desde MainScreen)
  Future<void> refreshViewMode() async {
    await _loadViewMode();
  }

  // Navegación
  void goBack() {
    if (_currentPlaylistName != null) {
      setState(() {
        _currentPlaylistName = null;
        _currentPlaylistSongs = [];
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      widget.onStateChanged();
    }
  }

  // Acciones desde el App Bar del MainScreen
  void playCurrentPlaylist() {
    if (_currentPlaylistSongs.isNotEmpty) {
      _playerManager.playSong(
        _currentPlaylistSongs.first,
        _currentPlaylistSongs,
      );
    }
  }

  void handleDeleteAction() {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.clear();
      });
      widget.onStateChanged(); // Para actualizar el icono del App Bar
    } else {
      // Eliminar canciones seleccionadas de la playlist
      if (_selectedIds.isNotEmpty && _currentPlaylistName != null) {
        final songsToDelete = _currentPlaylistSongs
            .where((s) => _selectedIds.contains(s.id.toString()))
            .toList();

        for (var song in songsToDelete) {
          _playlistManager.removeSongFromPlaylist(
            _currentPlaylistName!,
            song.path,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${songsToDelete.length} canciones eliminadas de '),
            backgroundColor: Colors.blue.shade900,
          ),
        );
      }
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      widget.onStateChanged();
    }
  }

  void _openPlaylist(String name) {
    final paths = _playlistManager.getSongsNotifier(name).value;
    final songMap = {for (var s in _allSongs) s.path: s};
    final songs = paths.map((p) => songMap[p]).whereType<LocalSong>().toList();
    setState(() {
      _currentPlaylistName = name;
      _currentPlaylistSongs = songs;
    });
    widget.onStateChanged();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // --- UI Principal ---

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_currentPlaylistName != null) {
      return _buildPlaylistDetail();
    }
    return _buildPlaylistsGrid();
  }

  Widget _buildPlaylistsGrid() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _playlistManager.playlistsNotifier,
      builder: (context, playlists, _) {
        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Ionicons.albums, size: 80, color: Colors.grey.shade800),
                const SizedBox(height: 15),
                const Text(
                  'No hay playlists creadas',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final name = playlists[index];
            final paths = _playlistManager.getSongsNotifier(name).value;
            LocalSong? firstSong;
            if (paths.isNotEmpty) {
              try {
                firstSong = _allSongs.firstWhere((s) => s.path == paths.first);
              } catch (_) {}
            }

            return GestureDetector(
              onTap: () => _openPlaylist(name),
              onLongPress: () => _showPlaylistOptions(name),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: firstSong?.artwork != null
                            ? Image.memory(
                                firstSong!.artwork!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Ionicons.musical_notes,
                                  size: 50,
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${paths.length} canciones',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
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

  Widget _buildPlaylistDetail() {
    if (_currentPlaylistName == null) return const SizedBox.shrink();

    return ValueListenableBuilder<List<String>>(
      valueListenable: _playlistManager.getSongsNotifier(_currentPlaylistName!),
      builder: (context, paths, _) {
        final songMap = {for (var s in _allSongs) s.path: s};
        final songs = paths
            .map((p) => songMap[p])
            .whereType<LocalSong>()
            .toList();
        _currentPlaylistSongs = songs;

        final header = Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _currentPlaylistName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${songs.length} canciones',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        );

        if (songs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Expanded(
                child: Center(
                  child: Text(
                    'Playlist vacía',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              child: _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: songs.length,
                      itemBuilder: (context, index) =>
                          _buildSongItem(songs[index], true),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: songs.length,
                      itemBuilder: (context, index) =>
                          _buildSongItem(songs[index], false),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongItem(LocalSong song, bool isGrid) {
    final isSelected = _selectedIds.contains(song.id.toString());
    final isAdo = song.artist.toLowerCase().contains('ado');

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(song.id.toString());
        } else {
          if (_playerManager.currentSongNotifier.value?.id == song.id) {
            widget.onOpenPlayer?.call();
          } else {
            _playerManager.playSong(song, _currentPlaylistSongs);
          }
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _showSongOptionsInPlaylist(song);
        }
      },
      child: Container(
        margin: isGrid ? null : const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _isSelectionMode && isSelected
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: _isSelectionMode && isSelected
              ? Border.all(color: Colors.blue.shade900, width: 2)
              : (isAdo && isGrid
                    ? Border.all(color: Colors.blue.shade900, width: 1.5)
                    : null),
        ),
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: song.artwork != null
                              ? Image.memory(
                                  song.artwork!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade800,
                                  child: Image.asset('assets/MG-I-T.png'),
                                ),
                        ),
                        if (_isSelectionMode)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Icon(
                              isSelected
                                  ? Ionicons.checkbox
                                  : Ionicons.square_outline,
                              color: isSelected ? Colors.blue : Colors.white,
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
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isAdo ? Colors.blue.shade200 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
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
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(
                        isSelected
                            ? Ionicons.checkbox
                            : Ionicons.square_outline,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.artwork != null
                          ? Image.memory(
                              song.artwork!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/MG-I-T.png',
                              width: 50,
                              height: 50,
                            ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isAdo ? Colors.blue.shade200 : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isSelectionMode)
                    IconButton(
                      icon: const Icon(
                        Ionicons.ellipsis_vertical,
                        color: Colors.white,
                      ),
                      onPressed: () => _showSongOptionsInPlaylist(song),
                    ),
                ],
              ),
      ),
    );
  }

  // --- Modales y Diálogos ---

  void _showPlaylistOptions(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Ionicons.text, color: Colors.white),
            title: const Text(
              'Cambiar nombre',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              _showRenameDialog(name);
            },
          ),
          ListTile(
            leading: const Icon(Ionicons.trash, color: Colors.red),
            title: const Text(
              'Eliminar Playlist',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.shade900, width: 2),
                  ),
                  title: const Text(
                    '¿Eliminar playlist?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: Text(
                    '¿Estás seguro de que quieres eliminar "$name"?',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        _playlistManager.deletePlaylist(name);
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Playlist "$name" eliminada'),
                            backgroundColor: Colors.blue.shade900,
                          ),
                        );
                      },
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Renombrar Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
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
                _playlistManager.renamePlaylist(oldName, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showSongOptionsInPlaylist(LocalSong song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Ionicons.image, color: Colors.white),
            title: const Text(
              'Usar como portada',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              // Hack: Mover la canción al principio para que sea la portada
              _playlistManager.removeSongFromPlaylist(
                _currentPlaylistName!,
                song.path,
              );
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Portada actualizada (requiere recarga)'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Ionicons.trash, color: Colors.red),
            title: const Text(
              'Eliminar de Playlist',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              _playlistManager.removeSongFromPlaylist(
                _currentPlaylistName!,
                song.path,
              );
              Navigator.pop(sheetContext);
            },
          ),
        ],
      ),
    );
  }
}

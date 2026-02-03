// Copyright © 2026 Brayan Medrano - MG Music
// Página de playlists TV

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

class TvPlaylistsPage extends StatefulWidget {
  final VoidCallback onOpenPlayer;
  const TvPlaylistsPage({super.key, required this.onOpenPlayer});

  @override
  State<TvPlaylistsPage> createState() => _TvPlaylistsPageState();
}

class _TvPlaylistsPageState extends State<TvPlaylistsPage> {
  final PlaylistManager _playlistManager = PlaylistManager();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  final SongFetcher _songFetcher = SongFetcher();

  String? _selectedPlaylist;
  List<LocalSong> _playlistSongs = [];
  bool _isLoadingSongs = false;
  bool _isRemoveMode = false;
  Set<String> _songsToRemove = {};

  @override
  Widget build(BuildContext context) {
    if (_selectedPlaylist != null) {
      return _buildPlaylistDetail();
    }
    return _buildPlaylistsGrid();
  }

  Widget _buildPlaylistsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade900, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Tus Playlists',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildActionButton(
                Ionicons.add,
                'Crear Playlist',
                () => _showNameDialog(context, isCreate: true),
                color: Colors.grey,
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: _playlistManager.playlistsNotifier,
            builder: (context, playlists, _) {
              if (playlists.isEmpty) {
                return const Center(
                  child: Text(
                    'No tienes playlists creadas.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlistName = playlists[index];
                  return _buildPlaylistItem(playlistName);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistItem(String name) {
    return TvFocusableItem(
      onTap: () => _openPlaylist(name),
      onLongPress: () => _showDeletePlaylistDialog(name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: _playlistManager.getCoverNotifier(name),
              builder: (context, coverPath, _) {
                return FutureBuilder<LocalSong?>(
                  future: _getSongByPath(coverPath),
                  builder: (context, snapshot) {
                    final artwork = snapshot.data?.artwork;
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade800,
                        image: artwork != null
                            ? DecorationImage(
                                image: MemoryImage(artwork),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: artwork == null
                          ? const Center(
                              child: Icon(
                                Ionicons.musical_notes,
                                color: Colors.white54,
                                size: 40,
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistDetail() {
    if (_isLoadingSongs) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade900, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              _buildIconButton(Ionicons.arrow_back, () {
                setState(() {
                  _selectedPlaylist = null;
                  _isRemoveMode = false;
                });
              }),
              const SizedBox(width: 20),
              Text(
                _selectedPlaylist!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildIconButton(
                Ionicons.pencil,
                () => _showNameDialog(context, isCreate: false),
              ),
              const Spacer(),
              if (_playlistSongs.isNotEmpty) ...[
                _buildActionButton(Ionicons.shuffle, 'Aleatorio', () {
                  _playerManager.shufflePlay(_playlistSongs);
                  widget.onOpenPlayer();
                }, color: Colors.grey),
                const SizedBox(width: 15),
                _buildActionButton(Ionicons.play, 'Reproducir', () {
                  _playerManager.playSong(_playlistSongs.first, _playlistSongs);
                  widget.onOpenPlayer();
                }, color: Colors.grey),
                const SizedBox(width: 15),
                _buildActionButton(
                  _isRemoveMode
                      ? Ionicons.checkmark_circle
                      : Ionicons.trash_outline,
                  _isRemoveMode ? 'Listo' : 'Eliminar',
                  () {
                    if (_isRemoveMode) {
                      _removeSelectedSongs();
                    }
                    setState(() {
                      _isRemoveMode = !_isRemoveMode;
                      _songsToRemove.clear();
                    });
                  },
                  color: _isRemoveMode ? Colors.green : Colors.redAccent,
                ),
              ],
            ],
          ),
        ),
        if (_isRemoveMode)
          Container(
            width: double.infinity,
            color: Colors.red.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: const Text(
              'MODO ELIMINAR: Selecciona canciones y pulsa "Listo" para borrarlas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: _playlistSongs.isEmpty
              ? const Center(
                  child: Text(
                    'Esta playlist está vacía.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _playlistSongs.length,
                  itemBuilder: (context, index) {
                    final song = _playlistSongs[index];
                    return TvFocusableItem(
                      onTap: () {
                        if (_isRemoveMode) {
                          setState(() {
                            if (_songsToRemove.contains(song.path)) {
                              _songsToRemove.remove(song.path);
                            } else {
                              _songsToRemove.add(song.path);
                            }
                          });
                        } else {
                          if (_playerManager.currentSongNotifier.value?.id ==
                              song.id) {
                            widget.onOpenPlayer();
                          } else {
                            _playerManager.playSong(song, _playlistSongs);
                          }
                        }
                      },
                      onLongPress: () {
                        if (!_isRemoveMode) _showSongOptions(song);
                      },
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: song.artwork != null
                                        ? DecorationImage(
                                            image: MemoryImage(song.artwork!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: Colors.grey.shade800,
                                  ),
                                  child: song.artwork == null
                                      ? Center(
                                          child: Image.asset(
                                            'assets/MG-I-T.png',
                                            width: 60,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          if (_isRemoveMode)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _songsToRemove.contains(song.path)
                                      ? Colors.red
                                      : Colors.grey.shade800,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Icon(
                                  _songsToRemove.contains(song.path)
                                      ? Ionicons.trash
                                      : Ionicons.radio_button_off,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _removeSelectedSongs() {
    for (final path in _songsToRemove) {
      _playlistManager.removeSongFromPlaylist(_selectedPlaylist!, path);
      _playlistSongs.removeWhere((s) => s.path == path);
    }
    setState(() {});
  }

  Future<void> _openPlaylist(String name) async {
    setState(() {
      _selectedPlaylist = name;
      _isLoadingSongs = true;
    });
    final allSongs = await _songFetcher.getSongs();
    final songPaths = _playlistManager.getSongsNotifier(name).value;
    final songs = <LocalSong>[];
    for (var path in songPaths) {
      try {
        songs.add(allSongs.firstWhere((s) => s.path == path));
      } catch (_) {}
    }
    if (mounted) setState(() => _playlistSongs = songs..toList());
    setState(() => _isLoadingSongs = false);
  }

  Future<LocalSong?> _getSongByPath(String? path) async {
    if (path == null) return null;
    final allSongs = await _songFetcher.getSongs();
    try {
      return allSongs.firstWhere((s) => s.path == path);
    } catch (_) {
      return null;
    }
  }

  void _showNameDialog(BuildContext context, {required bool isCreate}) {
    final controller = TextEditingController(
      text: isCreate ? '' : _selectedPlaylist,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: Text(
          isCreate ? 'Nueva Playlist' : 'Renombrar Playlist',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.blue.shade900,
          decoration: InputDecoration(
            hintText: 'Nombre',
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
                if (isCreate) {
                  _playlistManager.createPlaylist(controller.text);
                } else {
                  _playlistManager.renamePlaylist(
                    _selectedPlaylist!,
                    controller.text,
                  );
                  setState(() => _selectedPlaylist = controller.text);
                }
                Navigator.pop(context);
              }
            },
            child: Text(
              'Guardar',
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

  void _showSongOptions(LocalSong song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: Text(
          song.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(Ionicons.image, 'Usar como portada', () {
              _playlistManager.setPlaylistCover(_selectedPlaylist!, song.path);
              Navigator.pop(context);
            }),
            _buildDialogOption(Ionicons.trash, 'Eliminar de playlist', () {
              _playlistManager.removeSongFromPlaylist(
                _selectedPlaylist!,
                song.path,
              );
              setState(() => _playlistSongs.remove(song));
              Navigator.pop(context);
            }, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  void _showDeletePlaylistDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: Text(
          'Eliminar "$name"?',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _playlistManager.deletePlaylist(name);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required ColorSwatch<int> color,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildDialogOption(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 20),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(color: color ?? Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

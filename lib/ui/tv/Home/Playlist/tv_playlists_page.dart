// Copyright © 2026 Brayan Medrano - MG Music
// Página de playlists TV

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/ui/tv/Home/Playlist/tv_playlists_top_bar.dart';
import 'package:mg_music/ui/tv/Home/Playlist/tv_playlist_card.dart';
import 'package:mg_music/ui/tv/Home/Playlist/tv_playlist_detail_header.dart';
import 'package:mg_music/ui/tv/Home/Playlist/tv_playlist_song_tile.dart';
import 'package:mg_music/ui/tv/Home/Home/tv_home_song_item.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/playlist_action_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';

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
  List<LocalSong> _allSongsCache = [];
  bool _isLoadingSongs = false;
  bool _isRemoveMode = false;
  Set<String> _songsToRemove = {};

  @override
  /// Construye la vista principal de playlists (lista o detalle)
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    Widget content;

    if (_selectedPlaylist != null) {
      content = _buildPlaylistDetail(mode);
    } else {
      content = _buildPlaylistsGrid(mode);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: content,
    );
  }

  /// Construye la grilla de playlists del usuario
  Widget _buildPlaylistsGrid(AppThemeMode mode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvPlaylistsTopBar(
          onCreate: () {},
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
                  return TvPlaylistCard(
                    name: playlistName,
                    onTap: () => _openPlaylist(playlistName),
                    onLongPress: () => _showDeletePlaylistDialog(playlistName),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistItem(String name) {
    return const SizedBox.shrink();
  }

  /// Construye el detalle de una playlist seleccionada
  Widget _buildPlaylistDetail(AppThemeMode mode) {
    final selected = _selectedPlaylist!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvPlaylistDetailHeader(
          title: selected,
          onBack: () {
            setState(() {
              _selectedPlaylist = null;
              _isRemoveMode = false;
            });
          },
          onRename: () async {
            final newName = await PlaylistActionService.showRenamePlaylistDialog(
              context,
              oldName: selected,
            );
            if (mounted && newName != null && newName.isNotEmpty) {
              setState(() => _selectedPlaylist = newName);
            }
          },
          onShuffle: () {
            final current = _mapPathsToSongs(
              _playlistManager.getSongsNotifier(selected).value,
            );
            if (current.isNotEmpty) {
              _playerManager.shufflePlay(current);
              widget.onOpenPlayer();
            }
          },
          onPlay: () {
            final current = _mapPathsToSongs(
              _playlistManager.getSongsNotifier(selected).value,
            );
            if (current.isNotEmpty) {
              _playerManager.playSong(current.first, current);
              widget.onOpenPlayer();
            }
          },
          canActions:
              _playlistManager.getSongsNotifier(selected).value.isNotEmpty,
          removeMode: _isRemoveMode,
          onToggleRemoveMode: () {
            if (_isRemoveMode) _removeSelectedSongs();
            setState(() {
              _isRemoveMode = !_isRemoveMode;
              _songsToRemove.clear();
            });
          },
        ),
        if (_isRemoveMode)
          Container(
            width: double.infinity,
            color: Colors.red.withOpacity(0.18),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              'MODO ELIMINAR: Selecciona canciones y pulsa "Listo" para borrarlas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: _playlistManager.getSongsNotifier(selected),
            builder: (context, paths, _) {
              if (_isLoadingSongs || _allSongsCache.isEmpty) {
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, __) => const TvHomeSongShimmerItem(),
                );
              }
              final songs = _mapPathsToSongs(paths);
              if (songs.isEmpty) {
                return Center(
                  child: Text(
                    'Esta playlist está vacía.',
                    style: TextStyle(color: AppColors.textSecondary(mode)),
                  ),
                );
              }
              return Stack(
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final selectedFlag = _songsToRemove.contains(song.path);
                      return TvPlaylistSongTile(
                        song: song,
                        removeMode: _isRemoveMode,
                        selectedForRemove: selectedFlag,
                        onTap: () {
                          if (_isRemoveMode) {
                            setState(() {
                              if (selectedFlag) {
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
                              _playerManager.playSong(song, songs);
                            }
                          }
                        },
                        onLongPress: () {
                          if (!_isRemoveMode) _showSongOptions(song);
                        },
                      );
                    },
                  ),
                  if (_isLoadingSongs)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppColors.primaryBlueMid.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlueMid,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Cargando canciones...',
                                style: TextStyle(
                                  color: AppColors.textSecondary(mode),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Elimina canciones seleccionadas del modo eliminar
  void _removeSelectedSongs() {
    for (final path in _songsToRemove) {
      _playlistManager.removeSongFromPlaylist(_selectedPlaylist!, path);
    }
    setState(() {});
  }

  /// Abre una playlist y carga su caché de canciones
  Future<void> _openPlaylist(String name) async {
    setState(() {
      _selectedPlaylist = name;
      _isLoadingSongs = true;
    });
    final all = await _songFetcher.getSongs();
    if (!mounted) return;
    setState(() {
      _allSongsCache = all;
      _isLoadingSongs = false;
    });
  }

  /// Mapea rutas a modelos de canción usando caché local
  List<LocalSong> _mapPathsToSongs(List<String> paths) {
    final byPath = {for (var s in _allSongsCache) s.path: s};
    final songs = <LocalSong>[];
    for (final p in paths) {
      final s = byPath[p];
      if (s != null) songs.add(s);
    }
    return songs;
  }

  /// Muestra opciones para una canción dentro de la playlist
  void _showSongOptions(LocalSong song) {
    GlobalModalService.show(
      title: song.title,
      icon: Ionicons.list,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogOption(
            Ionicons.image,
            'Usar como portada',
            () async {
              await _playlistManager.setPlaylistCover(
                _selectedPlaylist!,
                song.path,
              );
              Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
              CustomToastService.show(
                GlobalModalService.navigatorKey.currentContext!,
                message: 'Portada actualizada',
                type: ToastType.success,
              );
            },
          ),
          _buildDialogOption(
            Ionicons.trash,
            'Eliminar de playlist',
            () async {
              await _playlistManager.removeSongFromPlaylist(
                _selectedPlaylist!,
                song.path,
              );
              Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
              CustomToastService.show(
                GlobalModalService.navigatorKey.currentContext!,
                message: 'Eliminada de la playlist',
                type: ToastType.warning,
              );
            },
            color: Colors.redAccent,
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () =>
              Navigator.pop(GlobalModalService.navigatorKey.currentContext!),
          color: Colors.grey,
        ),
      ],
    );
  }

  /// Confirma la eliminación de una playlist
  void _showDeletePlaylistDialog(String name) {
    GlobalModalService.showConfirmation(
      title: 'Eliminar "$name"?',
      message: 'Esta acción no se puede deshacer.',
      icon: Ionicons.trash_outline,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.redAccent,
    ).then((confirmed) async {
      if (confirmed) {
        await _playlistManager.deletePlaylist(name);
        CustomToastService.show(
          GlobalModalService.navigatorKey.currentContext!,
          message: 'Playlist eliminada',
          type: ToastType.warning,
        );
      }
    });
  }

  /// Construye un botón de acción estilizado
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

  /// Construye un botón redondo simple con icono
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

  /// Construye una opción para diálogos
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

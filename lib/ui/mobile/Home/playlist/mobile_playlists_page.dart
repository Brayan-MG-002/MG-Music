// Copyright © 2026 Brayan Medrano - MG Music
// Página de playlists Mobile

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/mobile/Home/Home/components/mobile_song_item.dart';
import 'package:mg_music/ui/mobile/Home/playlist/components/edit_playlist_dialog.dart';
import 'package:mg_music/ui/mobile/Home/playlist/components/playlist_card.dart';
import 'package:mg_music/ui/mobile/Home/playlist/components/playlist_detail_header.dart';
import 'package:mg_music/ui/mobile/Home/Shared/shared_cover_header.dart';
import 'package:mg_music/ui/mobile/Home/playlist/components/mobile_playlist_shimmer.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class MobilePlaylistsPage extends StatefulWidget {
  final VoidCallback onStateChanged;
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

  String? _currentPlaylistName;
  List<LocalSong> _currentPlaylistSongs = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isLoadingPlaylist = false;
  bool _isGridView = true; // Se carga de preferencias globales
  final Map<String, Uint8List?> _playlistCoverCache = {};
  final Map<String, Future<Uint8List?>> _pendingCoverFutures = {};

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
    final songs = await _songFetcher.getSongs(
      onProgress: (earlySongs) {
        if (mounted && _allSongs.isEmpty) {
          setState(() => _allSongs = earlySongs);
        }
      },
    );
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


  Future<void> refreshViewMode() async {
    await _loadViewMode();
  }


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
      if (_selectedIds.isNotEmpty && _currentPlaylistName != null) {
        final songsToDelete = _currentPlaylistSongs
            .where((s) => _selectedIds.contains(s.id.toString()))
            .toList();

        GlobalModalService.showConfirmation(
          title: '¿Eliminar canciones?',
          message:
              'Se eliminarán ${songsToDelete.length} canciones de la playlist "$_currentPlaylistName".',
          icon: Ionicons.trash,
          confirmText: 'Eliminar',
          cancelText: 'Cancelar',
          confirmButtonColor: Colors.red.shade900,
        ).then((confirmed) {
          if (!confirmed) return;

          for (var song in songsToDelete) {
            _playlistManager.removeSongFromPlaylist(
              _currentPlaylistName!,
              song.path,
            );
          }

          if (mounted) {
            CustomToastService.show(
              context,
              message: '${songsToDelete.length} canciones eliminadas',
              type: ToastType.error,
            );
          }

          setState(() {
            _isSelectionMode = false;
            _selectedIds.clear();
          });
          widget.onStateChanged();
        });
      } else {
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        widget.onStateChanged();
      }
    }
  }


  void _openPlaylist(String name) {
    setState(() {
      _currentPlaylistName = name;
      _isLoadingPlaylist = true;
      _currentPlaylistSongs = [];
    });
    widget.onStateChanged();

    // Asegurar que la carátula esté cargada antes de entrar
    _getPlaylistArtworkCached(name, []);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final paths = _playlistManager.getSongsNotifier(name).value;
      final songMap = {for (var s in _allSongs) s.path: s};
      final songs = paths
          .map((p) => songMap[p])
          .whereType<LocalSong>()
          .toList();
      if (mounted) {
        setState(() {
          _currentPlaylistSongs = songs;
          _isLoadingPlaylist = false;
        });
      }
    });
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


  void _handleItemTap(LocalSong song) {
    if (_isSelectionMode) {
      _toggleSelection(song.id.toString());
    } else {
      if (_playerManager.currentSongNotifier.value?.id == song.id) {
        widget.onOpenPlayer?.call();
      } else {
        _playerManager.playSong(song, _currentPlaylistSongs);
      }
    }
  }


  void _handleItemLongPress(LocalSong song) {
    if (!_isSelectionMode) {
      setState(() => _isSelectionMode = true);
      _toggleSelection(song.id.toString());
      widget.onStateChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mode = context.select<ThemeService, AppThemeMode>((ts) => ts.mode);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: RepaintBoundary(
        child: _currentPlaylistName != null
            ? _buildPlaylistDetail(mode)
            : _buildPlaylistsGrid(mode),
      ),
    );
  }


  Widget _buildPlaylistsGrid(AppThemeMode mode) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _playlistManager.playlistsNotifier,
      builder: (context, playlists, _) {
        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.albums,
                  size: 80,
                  color: AppColors.textSecondary(mode).withOpacity(0.5),
                ),
                SizedBox(height: 15.h),
                Text(
                  'No hay playlists creadas',
                  style: TextStyle(
                    color: AppColors.textSecondary(mode),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final songMap = {for (var s in _allSongs) s.path: s};

        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final name = playlists[index];

            return ValueListenableBuilder<List<String>>(
              valueListenable: _playlistManager.getSongsNotifier(name),
              builder: (context, paths, _) {
                final songsFound = paths
                    .map((p) => songMap[p])
                    .whereType<LocalSong>()
                    .toList();

                final artwork = _playlistCoverCache[name];
                if (artwork == null && !_pendingCoverFutures.containsKey(name)) {
                  _getPlaylistArtworkCached(name, songsFound);
                }

                return PlaylistCard(
                  name: name,
                  songCount: paths.length,
                  artwork: artwork,
                  firstSong: songsFound.isNotEmpty
                      ? songsFound.first
                      : null,
                  onTap: () => _openPlaylist(name),
                  onLongPress: () => _showPlaylistOptions(name),
                );
              },
            );
          },
        );
      },
    );
  }


  void _showEditDialog(String playlistName) {
    GlobalModalService.show<String>(
      title: 'Editar Playlist',
      icon: Ionicons.settings,
      content: EditPlaylistDialog(
        playlistName: playlistName,
        songs: _currentPlaylistSongs,
        playlistManager: _playlistManager,
      ),
      actions:
          [], // Pasamos lista vacía porque los botones están dentro del EditPlaylistDialog
    ).then((newName) {
      if (newName != null && mounted) {
        setState(() {
          _playlistCoverCache.remove(playlistName);
          _playlistCoverCache.remove(newName);
          _currentPlaylistName = newName;
        });
      }
    });
  }


  Widget _buildPlaylistDetail(AppThemeMode mode) {
    final playlistName = _currentPlaylistName;
    if (playlistName == null) return const SizedBox.shrink();

    return ValueListenableBuilder<List<String>>(
      valueListenable: _playlistManager.getSongsNotifier(playlistName),
      builder: (context, paths, _) {
        final songMap = {for (var s in _allSongs) s.path: s};
        final songs = paths
            .map((p) => songMap[p])
            .whereType<LocalSong>()
            .toList();
        _currentPlaylistSongs = songs;

        final artwork = _playlistCoverCache[playlistName];
        if (artwork == null && !_pendingCoverFutures.containsKey(playlistName)) {
          _getPlaylistArtworkCached(playlistName, songs);
        }

        LocalSong? firstSong;
        if (songs.isNotEmpty) {
          firstSong = songs.first;
        }

        final totalDuration = songs.fold<Duration>(Duration.zero, (prev, song) {
          final int? songDuration = song.duration;
          return prev + Duration(milliseconds: songDuration ?? 0);
        });

        return ValueListenableBuilder<bool>(
          valueListenable: _playerManager.isPlayingNotifier,
          builder: (context, isPlayingGlobal, _) {
            return ValueListenableBuilder<LocalSong?>(
              valueListenable: _playerManager.currentSongNotifier,
              builder: (context, currentSong, _) {
                final bool isSongInPlaylist = currentSong != null && songs.any((s) => s.id == currentSong.id);
                final bool showPause = isPlayingGlobal && isSongInPlaylist;

                final header = PlaylistDetailHeader(
                  playlistName: playlistName,
                  songs: songs,
                  totalDuration: totalDuration,
                  isPlaying: showPause,
                  onPlay: () {
                    if (songs.isNotEmpty) {
                      if (isSongInPlaylist) {
                        _playerManager.togglePlayPause();
                      } else {
                        _playerManager.playSong(songs.first, songs);
                      }
                    }
                  },
                  onShufflePlay: () {
                    if (songs.isNotEmpty) {
                      _playerManager.shufflePlay(songs);
                    }
                  },
                  onEdit: () => _showEditDialog(playlistName),
                );

                Widget songsBody;
                if (_isLoadingPlaylist) {
                  songsBody = SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: MobilePlaylistShimmer(isGridView: _isGridView),
                    ),
                  );
                } else if (songs.isEmpty) {
                  songsBody = SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Playlist vacía',
                        style: TextStyle(
                          color: AppColors.textSecondary(mode),
                        ),
                      ),
                    ),
                  );
                } else if (_isGridView) {
                  songsBody = SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          columnCount: 3,
                          duration: const Duration(milliseconds: 375),
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: RepaintBoundary(
                                child: _buildSongItem(songs[index], true, mode),
                              ),
                            ),
                          ),
                        );
                      }, childCount: songs.length),
                    ),
                  );
                } else {
                  songsBody = SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                              child: SizedBox(
                                height: 75.h,
                                child: RepaintBoundary(
                                  child: _buildSongItem(songs[index], false, mode),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: songs.length),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SharedCoverHeader(
                      mode: mode,
                      artwork: artwork ?? firstSong?.artwork,
                      bottom: header,
                      expandedHeight: 300.0.h,
                    ),
                    songsBody,
                    SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildSongItem(LocalSong song, bool isGrid, AppThemeMode mode) {
    final isSelected = _selectedIds.contains(song.id.toString());
    final isAdo = AdoHandler.isAdo(song);

    return ValueListenableBuilder<LocalSong?>(
      valueListenable: _playerManager.currentSongNotifier,
      builder: (context, currentSong, _) {
        final isPlaying = currentSong?.id == song.id;
        return Stack(
          children: [
            MobileSongItem(
              song: song,
              isAdo: isAdo,
              isGrid: isGrid,
              isPlaying: isPlaying,
              onTap: () => _handleItemTap(song),
              onLongPress: () => _handleItemLongPress(song),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: _isSelectionMode
                    ? GestureDetector(
                        key: ValueKey('selection_widget_${song.id}'),
                        onTap: () => _toggleSelection(song.id.toString()),
                        child: Container(
                          decoration: BoxDecoration(
                            color: mode == AppThemeMode.dark
                                ? Colors.black54
                                : Colors.white70,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              key: ValueKey(isSelected),
                              isSelected
                                  ? Ionicons.checkmark_circle
                                  : Ionicons.ellipse_outline,
                              color: isSelected
                                  ? AppColors.primaryBlueMid
                                  : AppColors.textPrimary(mode),
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_selection')),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showPlaylistOptions(String name) async {
    final action = await GlobalModalService.showList<String>(
      title: name,
      icon: Ionicons.options,
      items: ['Editar Playlist', 'Eliminar Playlist'],
      labelBuilder: (item) => item,
    );

    if (action == null) return;

    if (action == 'Editar Playlist') {
      final paths = _playlistManager.getSongsNotifier(name).value;
      final songMap = {for (var s in _allSongs) s.path: s};
      final songs = paths
          .map((p) => songMap[p])
          .whereType<LocalSong>()
          .toList();

      await GlobalModalService.show<String>(
        title: 'Editar Playlist',
        icon: Ionicons.settings,
        content: EditPlaylistDialog(
          playlistName: name,
          songs: songs,
          playlistManager: _playlistManager,
        ),
        actions: [],
      );
      if (mounted) {
        setState(() => _playlistCoverCache.remove(name));
      }
    } else if (action == 'Eliminar Playlist') {
      final confirmed = await GlobalModalService.showConfirmation(
        title: '¿Eliminar playlist?',
        message: '¿Estás seguro de que quieres eliminar "$name"?',
        confirmText: 'Eliminar',
        cancelText: 'Cancelar',
        confirmButtonColor: Colors.red.shade900,
        icon: Ionicons.trash,
      );

      if (confirmed) {
        _playlistManager.deletePlaylist(name);
        _removePlaylistCover(name);
        if (mounted) {
          CustomToastService.show(
            context,
            message: 'Playlist "$name" eliminada',
            type: ToastType.error,
          );
        }
      }
    }
  }


  Future<Uint8List?> _getPlaylistArtwork(
    String playlistName,
    List<LocalSong> songs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final coverId = prefs.getString('playlist_cover_$playlistName');

    if (coverId == null || coverId == 'DEFAULT') {
      return null;
    }

    if (coverId == 'APP_LOGO') {
      final byteData = await DefaultAssetBundle.of(
        context,
      ).load('assets/MG-I-T.png');
      return byteData.buffer.asUint8List();
    }

    if (coverId.startsWith('SONG_ID:')) {
      final songId = int.tryParse(coverId.split(':')[1]);
      if (songId != null) {
        final matches = songs.where((s) => s.id == songId);
        if (matches.isNotEmpty) {
          return matches.first.artwork;
        }
      }
    }

    if (coverId.startsWith('FILE:')) {
      final filePath = coverId.substring(5);
      final file = File(filePath);
      if (file.existsSync()) {
        try {
          return await file.readAsBytes();
        } catch (_) {}
      }
    }

    return null;
  }


  Future<Uint8List?> _getPlaylistArtworkCached(String playlistName, List<LocalSong> songs) {
    if (_playlistCoverCache.containsKey(playlistName)) {
      return Future.value(_playlistCoverCache[playlistName]);
    }
    
    // Si ya hay una petición en curso para esta playlist, retornamos la misma
    if (_pendingCoverFutures.containsKey(playlistName)) {
      return _pendingCoverFutures[playlistName]!;
    }

    final future = _getPlaylistArtwork(playlistName, songs).then((data) {
      if (mounted) {
        setState(() {
          _playlistCoverCache[playlistName] = data;
        });
      }
      _pendingCoverFutures.remove(playlistName);
      return data;
    });

    _pendingCoverFutures[playlistName] = future;
    return future;
  }


  Future<void> _removePlaylistCover(String playlistName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('playlist_cover_$playlistName');
  }
}

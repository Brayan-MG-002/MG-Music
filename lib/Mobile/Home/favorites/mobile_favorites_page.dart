// Copyright © 2026 Brayan Medrano - MG Music
// Página de favoritos Mobile

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Mobile/Home/favorites/components/mobile_favorites_shimmer.dart';
import 'package:mg_music/Mobile/Home/playlist/components/playlist_detail_header.dart';
import 'package:mg_music/Mobile/Home/Shared/shared_cover_header.dart';
import 'package:mg_music/services/bottom_modal_service.dart';
import 'package:mg_music/services/custom_toast_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/services/global_modal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/Mobile/Home/Home/components/mobile_song_item.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';

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
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final FavoritesManager _favoritesManager = FavoritesManager();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  final SongFetcher _songFetcher = SongFetcher();

  late AnimationController _glowController;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  List<LocalSong> _favoriteSongs = [];
  String? _mainFavoriteSongId;
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  /// Mantiene el estado al cambiar de pestañas
  bool get wantKeepAlive => true;

  @override
  /// Inicializa animaciones y carga de favoritos
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _loadFavoriteSongs();
    _favoritesManager.favoritePathsNotifier.addListener(_loadFavoriteSongs);
  }

  @override
  /// Libera controladores y listeners
  void dispose() {
    _glowController.dispose();
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
    final mainId = prefs.getString('main_favorite_song_id');

    final allSongs = await _songFetcher.getSongs(
      onProgress: (earlySongs) {
        if (mounted && _isLoading) {
          _processAndSetFavorites(earlySongs, mainId, isGrid);
        }
      },
    );

    _processAndSetFavorites(allSongs, mainId, isGrid);
  }

  /// Procesa canciones, filtra favoritas y actualiza estado
  void _processAndSetFavorites(
    List<LocalSong> songs,
    String? mainId,
    bool isGrid,
  ) {
    if (!mounted) return;

    final favoritePaths = _favoritesManager.getFavoritePaths();
    final favorites = songs
        .where((song) => favoritePaths.contains(song.path))
        .toList();

    // Ordenar con "Ado" primero
    favorites.sort((a, b) {
      final aIsAdo = AdoHandler.isAdo(a);
      final bIsAdo = AdoHandler.isAdo(b);
      if (aIsAdo && !bIsAdo) return -1;
      if (!aIsAdo && bIsAdo) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    setState(() {
      _favoriteSongs = favorites;
      _mainFavoriteSongId = mainId;
      _isGridView = isGrid;
      _isLoading = false;
    });
    _updateGlowState();
  }

  Future<void> _setMainFavorite(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('main_favorite_song_id', songId);
    if (!mounted) return;

    setState(() {
      _mainFavoriteSongId = songId;
    });
    _updateGlowState();

    CustomToastService.show(
      context,
      message: 'Establecido como principal',
      type: ToastType.success,
    );
  }

  /// Actualiza el brillo del header según si la principal es Ado
  void _updateGlowState() {
    if (_favoriteSongs.isEmpty) {
      if (_glowController.isAnimating) {
        _glowController.stop();
        _glowController.reset();
      }
      return;
    }

    LocalSong? mainSong;
    if (_mainFavoriteSongId != null) {
      try {
        mainSong = _favoriteSongs.firstWhere(
          (s) => s.id.toString() == _mainFavoriteSongId,
        );
      } catch (_) {}
    }
    mainSong ??= _favoriteSongs.first;

    final bool isMainSongAdo = AdoHandler.isAdo(mainSong);

    if (isMainSongAdo && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!isMainSongAdo && _glowController.isAnimating) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  /// Reproduce favoritos (llamado desde el MainScreen)
  void playFavorites() {
    if (_favoriteSongs.isNotEmpty) {
      _playerManager.playSong(_favoriteSongs.first, _favoriteSongs);
    }
  }

  /// Entra o confirma eliminación en modo selección (MainScreen)
  void handleDeleteAction() {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.clear();
      });
      widget.onSelectionModeChanged(true);
    } else {
      if (_selectedIds.isNotEmpty) {
        GlobalModalService.showConfirmation(
          title: '¿Eliminar de Favoritos?',
          message:
              'Se eliminarán ${_selectedIds.length} canciones de tu lista de favoritos.',
          icon: Ionicons.heart_dislike,
          confirmText: 'Eliminar',
          cancelText: 'Cancelar',
          confirmButtonColor: Colors.red.shade900,
        ).then((confirmed) {
          if (confirmed) _deleteSelectedSongs();
        });
      } else {
        _exitSelectionMode();
      }
    }
  }

  /// Elimina las canciones seleccionadas de favoritos
  void _deleteSelectedSongs() async {
    final songsToDelete = _favoriteSongs
        .where((s) => _selectedIds.contains(s.id.toString()))
        .toList();

    int deletedCount = 0;
    bool skipMain = false;

    for (var song in songsToDelete) {
      if (song.id.toString() == _mainFavoriteSongId) {
        skipMain = true;
        continue;
      }
      final success = await _favoritesManager.removeFavorite(song);
      if (success) deletedCount++;
    }

    if (skipMain) {
      CustomToastService.show(
        context,
        message: 'No puedes eliminar la canción principal',
        type: ToastType.error,
      );
    }

    if (deletedCount > 0) {
      CustomToastService.show(
        context,
        message: '$deletedCount canciones eliminadas de favoritos',
        type: ToastType.success,
      );
    }

    _exitSelectionMode();
  }

  /// Sale del modo selección
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    widget.onSelectionModeChanged(false);
  }

  /// Alterna la selección de una canción
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
  /// Construye la vista de favoritos (grid o lista) con header y acciones
  Widget build(BuildContext context) {
    super.build(context);
    final mode = context.watch<ThemeService>().mode;

    if (_isLoading) {
      return MobileFavoritesShimmer(isGridView: _isGridView);
    }

    if (_favoriteSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.heart_dislike_outline,
              size: 60,
              color: AppColors.textSecondary(mode),
            ),
            const SizedBox(height: 10),
            Text(
              'No tienes favoritos aún',
              style: TextStyle(color: AppColors.textSecondary(mode)),
            ),
          ],
        ),
      );
    }

    LocalSong? mainSong;
    if (_mainFavoriteSongId != null) {
      try {
        mainSong = _favoriteSongs.firstWhere(
          (s) => s.id.toString() == _mainFavoriteSongId,
        );
      } catch (_) {}
    }
    mainSong ??= _favoriteSongs.first;

    final bool isMainSongAdo = AdoHandler.isAdo(mainSong);

    final totalDuration = _favoriteSongs.fold<Duration>(Duration.zero, (
      prev,
      song,
    ) {
      return prev + Duration(milliseconds: song.duration ?? 0);
    });

    return ValueListenableBuilder<bool>(
      valueListenable: _playerManager.isPlayingNotifier,
      builder: (context, isPlayingGlobal, _) {
        return ValueListenableBuilder<LocalSong?>(
          valueListenable: _playerManager.currentSongNotifier,
          builder: (context, currentSong, _) {
            final bool isSongInFavorites =
                currentSong != null &&
                _favoriteSongs.any((s) => s.id == currentSong.id);
            final bool showPause = isPlayingGlobal && isSongInFavorites;

            final header = PlaylistDetailHeader(
              playlistName: 'Tus Favoritos',
              songs: _favoriteSongs,
              totalDuration: totalDuration,
              isPlaying: showPause,
              onPlay: () {
                if (_favoriteSongs.isNotEmpty) {
                  if (isSongInFavorites) {
                    _playerManager.togglePlayPause();
                  } else {
                    _playerManager.playSong(
                      _favoriteSongs.first,
                      _favoriteSongs,
                    );
                  }
                }
              },
              onShufflePlay: () {
                if (_favoriteSongs.isNotEmpty) {
                  _playerManager.shufflePlay(_favoriteSongs);
                }
              },
            );

            Widget songsBody;
            if (_isGridView) {
              songsBody = SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      columnCount: 3,
                      duration: const Duration(milliseconds: 375),
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _buildSongItem(
                            _favoriteSongs[index],
                            true,
                            mode,
                          ),
                        ),
                      ),
                    );
                  }, childCount: _favoriteSongs.length),
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
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildSongItem(
                              _favoriteSongs[index],
                              false,
                              mode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: _favoriteSongs.length),
              );
            }

            final content = CustomScrollView(
              slivers: [
                SharedCoverHeader(
                  mode: mode,
                  artwork: mainSong?.artwork,
                  isGlowActive: isMainSongAdo,
                  glowAnimation: _glowController,
                  bottom: header,
                  expandedHeight: 300.0,
                ),
                songsBody,
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );

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
    if (_isSelectionMode) return;

    BottomModalService.show(
      context,
      title: song.title,
      subtitle: song.artist,
      artwork: song.artwork,
      options: [
        BottomModalOption(
          icon: Ionicons.image_outline,
          label: "Establecer como principal",
          onTap: () {
            Navigator.pop(context);
            _setMainFavorite(song.id.toString());
          },
        ),
        BottomModalOption(
          icon: Ionicons.heart_dislike,
          label: "Eliminar de favoritos",
          onTap: () {
            Navigator.pop(context);
            if (song.id.toString() == _mainFavoriteSongId) {
              CustomToastService.show(
                context,
                message: 'No puedes eliminar tu canción principal',
                type: ToastType.error,
              );
              return;
            }

            GlobalModalService.showConfirmation(
              title: '¿Eliminar de Favoritos?',
              message:
                  '¿Estás seguro de que deseas eliminar "${song.title}" de tus favoritos?',
              icon: Ionicons.heart_dislike,
              confirmText: 'Eliminar',
              cancelText: 'Cancelar',
              confirmButtonColor: Colors.red.shade900,
            ).then((confirmed) {
              if (confirmed) {
                _favoritesManager.removeFavorite(song).then((success) {
                  if (mounted && success) {
                    CustomToastService.show(
                      context,
                      message: 'Canción eliminada de favoritos',
                      type: ToastType.error,
                    );
                  }
                });
              }
            });
          },
        ),
      ],
    );
  }
}

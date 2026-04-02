// Copyright © 2026 Brayan Medrano - MG Music
// Página de gestión de canciones favoritas para la interfaz de TV, con soporte para modo de eliminación múltiple y opciones personalizadas.

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/ui/tv/Home/Favorites/tv_favorites_top_bar.dart';
import 'package:mg_music/ui/tv/Home/Home/tv_home_song_item.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/playlist_action_service.dart';

class TvFavoritesPage extends StatefulWidget {
  final VoidCallback onOpenPlayer;
  const TvFavoritesPage({super.key, required this.onOpenPlayer});

  @override
  State<TvFavoritesPage> createState() => _TvFavoritesPageState();
}

class _TvFavoritesPageState extends State<TvFavoritesPage> {
  final SongFetcher _songFetcher = SongFetcher();
  final FavoritesManager _favoritesManager = FavoritesManager();
  final AudioPlayerManager _playerManager = AudioPlayerManager();

  List<LocalSong> _favoriteSongs = [];
  bool _isLoading = true;
  bool _isRemoveMode = false;
  Set<String> _songsToRemove = <String>{};

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

  Future<void> _loadFavoriteSongs() async {
    setState(() => _isLoading = true);
    final allSongs = await _songFetcher.getSongs();
    final favoritePaths = _favoritesManager.getFavoritePaths();

    final favorites = allSongs
        .where((song) => favoritePaths.contains(song.path))
        .toList();

    favorites.sort((a, b) {
      final aIsAdo = AdoHandler.isAdo(a);
      final bIsAdo = AdoHandler.isAdo(b);
      if (aIsAdo && !bIsAdo) return -1;
      if (!aIsAdo && bIsAdo) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _favoriteSongs = favorites;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    Widget content;

    if (_isLoading) {
      content = GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.82,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemCount: 15,
        itemBuilder: (_, __) => const TvHomeSongShimmerItem(),
      );
    } else if (_favoriteSongs.isEmpty) {
      content = Center(
        child: Text(
          'Aún no has agregado canciones a favoritos.',
          style: TextStyle(color: AppColors.textSecondary(mode), fontSize: 18),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvFavoritesTopBar(
            onShuffle: () {
              if (_favoriteSongs.isNotEmpty) {
                _playerManager.shufflePlay(_favoriteSongs);
                widget.onOpenPlayer();
              }
            },
            removeMode: _isRemoveMode,
            onToggleRemoveMode: () {
              if (_isRemoveMode) {
                _removeSelectedFavorites();
              } else {
                setState(() {
                  _isRemoveMode = true;
                });
              }
            },
          ),
          if (_isRemoveMode)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.2),
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
            child: GridView.builder(
              padding: const EdgeInsets.all(24.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.85,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: _favoriteSongs.length,
              itemBuilder: (context, index) {
                final song = _favoriteSongs[index];
                final isAdo = AdoHandler.isAdo(song);
                return Stack(
                  children: [
                    TvHomeSongItem(
                      song: song,
                      isAdo: isAdo,
                      onTap: () {
                        if (_isRemoveMode) {
                          setState(() {
                            final key = song.id.toString();
                            if (_songsToRemove.contains(key)) {
                              _songsToRemove.remove(key);
                            } else {
                              _songsToRemove.add(key);
                            }
                          });
                        } else {
                          if (_playerManager.currentSongNotifier.value?.id ==
                              song.id) {
                            widget.onOpenPlayer();
                          } else {
                            _playerManager.playSong(song, _favoriteSongs);
                          }
                        }
                      },
                      onLongPress: () {
                        if (!_isRemoveMode) {
                          _showFavoriteSongOptions(song, mode);
                        }
                      },
                    ),
                    if (_isRemoveMode)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _songsToRemove.contains(song.id.toString())
                                ? Colors.redAccent
                                : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white),
                          ),
                          child: Icon(
                            _songsToRemove.contains(song.id.toString())
                                ? Ionicons.trash
                                : Ionicons.radio_button_off,
                            color: Colors.white,
                            size: 16,
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

  void _removeSelectedFavorites() {
    if (_songsToRemove.isEmpty) {
      CustomToastService.show(
        GlobalModalService.navigatorKey.currentContext!,
        message: 'No has seleccionado canciones',
        type: ToastType.info,
      );
      return;
    }
    GlobalModalService.showConfirmation(
      title: 'Eliminar de Favoritos',
      message:
          'Se eliminarán ${_songsToRemove.length} canciones de favoritos. ¿Deseas continuar?',
      icon: Ionicons.trash_outline,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.redAccent,
    ).then((confirmed) async {
      if (!confirmed) return;
      final mainId = await _favoritesManager.getMainFavoriteId();
      final snapshot = _favoriteSongs
          .where((s) => _songsToRemove.contains(s.id.toString()))
          .toList();
      int removed = 0;
      int protegidas = 0;
      int fallidas = 0;
      for (final song in snapshot) {
        if (mainId != null && song.id.toString() == mainId) {
          protegidas++;
          continue;
        }
        final wasFav = _favoritesManager.getFavoritePaths().contains(song.path);
        if (!wasFav) {
          continue;
        }
        final ok = await _favoritesManager.removeFavorite(song);
        final stillFav = _favoritesManager.getFavoritePaths().contains(
          song.path,
        );
        if (ok && !stillFav) {
          removed++;
        } else if (!ok) {
          protegidas++;
        } else {
          fallidas++;
        }
      }
      _songsToRemove.clear();
      if (mounted) setState(() => _isRemoveMode = false);
      final ctx = GlobalModalService.navigatorKey.currentContext!;
      if (removed > 0 && protegidas == 0 && fallidas == 0) {
        CustomToastService.show(
          ctx,
          message: 'Eliminadas $removed de favoritos',
          type: ToastType.warning,
        );
      } else if (removed == 0 && protegidas > 0 && fallidas == 0) {
        CustomToastService.show(
          ctx,
          message: 'No se quitó $protegidas por ser la principal',
          type: ToastType.error,
        );
      } else {
        final parts = <String>[];
        parts.add('Eliminadas $removed');
        if (protegidas > 0) parts.add('$protegidas por ser la principal');
        if (fallidas > 0) parts.add('$fallidas no se pudieron quitar');
        final msg = parts.join('. ') + '.';
        CustomToastService.show(
          ctx,
          message: msg,
          type: removed > 0 ? ToastType.warning : ToastType.error,
        );
      }
    });
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

  void _showFavoriteSongOptions(LocalSong song, AppThemeMode mode) {
    final isAdo = AdoHandler.isAdo(song);
    GlobalModalService.show(
      title: song.title,
      icon: isAdo ? Ionicons.star : Ionicons.musical_note,
      primaryColor: isAdo ? Colors.blue.shade900 : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reproducir siguiente
          _buildDialogOption(Ionicons.play_forward, 'Reproducir siguiente', () {
            AudioPlayerManager().addNext(song);
            final ctx = GlobalModalService.navigatorKey.currentContext!;
            Navigator.pop(ctx);
            CustomToastService.show(
              ctx,
              message: 'Siguiente: ${song.title}',
              type: ToastType.info,
              icon: Ionicons.play_forward,
            );
          }),
          const SizedBox(height: 4),
          // Añadir a Playlist (servicio central)
          _buildDialogOption(Ionicons.list, 'Añadir a Playlist', () {
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
            PlaylistActionService.showAddToPlaylistDialog(
              GlobalModalService.navigatorKey.currentContext!,
              song,
            );
          }),
          const SizedBox(height: 4),
          // Establecer como principal
          _buildDialogOption(
            Ionicons.ribbon,
            'Establecer como principal',
            () async {
              await _favoritesManager.setMainFavorite(song);
              final ctx = GlobalModalService.navigatorKey.currentContext!;
              Navigator.pop(ctx);
              CustomToastService.show(
                ctx,
                message: 'Establecida como favorita principal',
                type: ToastType.success,
              );
            },
          ),
          const SizedBox(height: 4),
          // Quitar de Favoritos
          _buildDialogOption(
            Ionicons.heart_dislike,
            'Quitar de Favoritos',
            () async {
              final ctx = GlobalModalService.navigatorKey.currentContext!;
              final ok = await _favoritesManager.removeFavorite(song);
              Navigator.pop(ctx);
              CustomToastService.show(
                ctx,
                message: ok
                    ? 'Quitada de Favoritos'
                    : 'No se puede quitar: es la principal',
                type: ok ? ToastType.warning : ToastType.error,
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
}

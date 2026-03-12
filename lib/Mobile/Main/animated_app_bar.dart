import 'dart:ui';
import 'package:animations_plus/animations_plus.dart' hide ScaleAnimation;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Mobile/Home/favorites/mobile_favorites_page.dart';
import 'package:mg_music/Mobile/Home/playlist/mobile_playlists_page.dart';
import 'package:mg_music/Mobile/Home/Player/mobile_mini_player.dart';
import 'package:mg_music/Mobile/Main/painters.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/Mobile/Main/search_rotating_artwork.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';

class AnimatedAppBar extends StatelessWidget {
  final int selectedIndex;
  final bool isSearching;
  final bool showFullPlayer;
  final bool isFavoritesSelectionMode;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final GlobalKey<MobileFavoritesPageState> favoritesKey;
  final GlobalKey<MobilePlaylistsPageState> playlistsKey;
  final VoidCallback onSearchTap;
  final VoidCallback onSortTap;
  final VoidCallback onArtistFilterTap;
  final VoidCallback onToggleFullPlayer;

  const AnimatedAppBar({
    super.key,
    required this.selectedIndex,
    required this.isSearching,
    required this.showFullPlayer,
    required this.isFavoritesSelectionMode,
    required this.searchController,
    required this.searchFocusNode,
    required this.favoritesKey,
    required this.playlistsKey,
    required this.onSearchTap,
    required this.onSortTap,
    required this.onArtistFilterTap,
    required this.onToggleFullPlayer,
  });

  @override
  /// Construye el app bar animado con contenido según estado
  Widget build(BuildContext context) {
    return SimpleFadeAnimation(
      duration: const Duration(milliseconds: 400),
      child: SimpleSlideAnimation(
        duration: const Duration(milliseconds: 400),
        direction: SlideDirection.up,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Consumer<ThemeService>(
              builder: (context, themeService, _) {
                final mode = themeService.mode;
                return CustomPaint(
                  painter: AppBarPainter(
                    borderColor: mode == AppThemeMode.dark
                        ? Colors.blue.shade900
                        : Colors.blue.shade500,
                    mode: mode,
                  ),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      bottom: 5,
                      left: 10,
                      right: 10,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: isSearching
                          ? Container(
                              key: const ValueKey('search'),
                              child: _buildSearchBar(),
                            )
                          : Container(
                              key: const ValueKey('default'),
                              child: _buildDefaultAppBarContent(),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el contenido por defecto del app bar
  Widget _buildDefaultAppBarContent() {
    const contentDelay = Duration(milliseconds: 400);

    Widget iconTransition(Widget child, Animation<double> animation) {
      return FadeTransition(opacity: animation, child: child);
    }

    return SimpleFadeAnimation(
      delay: contentDelay,
      duration: const Duration(milliseconds: 300),
      child: Builder(
        builder: (context) {
          return Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: iconTransition,
                child: _buildLeftAppBarIcon(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: MobileMiniPlayer(
                    showVisualizer: showFullPlayer,
                    onTap: onToggleFullPlayer,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: iconTransition,
                child: _buildRightAppBarIcon(context),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Icono izquierdo según sección/estado
  Widget _buildLeftAppBarIcon(BuildContext context) {
    if (selectedIndex == 1 &&
        (playlistsKey.currentState?.isInsidePlaylist ?? false)) {
      return _buildPopAnimation(
        const ValueKey('back'),
        _buildTopBarIcon(
          Ionicons.arrow_back,
          () => playlistsKey.currentState?.goBack(),
          context: context,
        ),
      );
    }
    if (selectedIndex == 0 && !showFullPlayer) {
      return _buildPopAnimation(
        const ValueKey('sort'),
        _buildTopBarIcon(Ionicons.swap_vertical, onSortTap, context: context),
      );
    }
    if (selectedIndex == 2 && !showFullPlayer && !isFavoritesSelectionMode) {
      return _buildPopAnimation(
        const ValueKey('play_favs'),
        _buildTopBarIcon(
          Ionicons.play_circle,
          () => favoritesKey.currentState?.playFavorites(),
          context: context,
        ),
      );
    }
    return _buildPopAnimation(
      const ValueKey('empty_left'),
      const SizedBox(width: 48),
    );
  }

  /// Icono derecho según sección/estado
  Widget _buildRightAppBarIcon(BuildContext context) {
    if (selectedIndex == 0 && !showFullPlayer) {
      return _buildPopAnimation(
        const ValueKey('artists'),
        _buildTopBarIcon(Ionicons.people, onArtistFilterTap, context: context),
      );
    }
    if (selectedIndex == 2 && !showFullPlayer) {
      return _buildPopAnimation(
        ValueKey('trash_fav_$isFavoritesSelectionMode'),
        _buildTopBarIcon(
          isFavoritesSelectionMode ? Ionicons.trash : Ionicons.trash_outline,
          () => favoritesKey.currentState?.handleDeleteAction(),
          color: isFavoritesSelectionMode ? Colors.red : null,
          context: context,
        ),
      );
    }
    if (selectedIndex == 1 &&
        !showFullPlayer &&
        (playlistsKey.currentState?.isInsidePlaylist ?? false)) {
      bool isSelectionMode =
          playlistsKey.currentState?.isSelectionMode ?? false;
      return _buildPopAnimation(
        ValueKey('trash_playlist_$isSelectionMode'),
        _buildTopBarIcon(
          isSelectionMode ? Ionicons.trash : Ionicons.trash_outline,
          () => playlistsKey.currentState?.handleDeleteAction(),
          color: isSelectionMode ? Colors.red : null,
          context: context,
        ),
      );
    }
    return _buildPopAnimation(
      const ValueKey('empty_right'),
      const SizedBox(width: 48),
    );
  }

  /// Barra de búsqueda con carátula rotatoria
  Widget _buildSearchBar() {
    final playerManager = AudioPlayerManager();
    return Builder(
      builder: (context) {
        final mode = context.watch<ThemeService>().mode;
        return Row(
          children: [
            ValueListenableBuilder<LocalSong?>(
              valueListenable: playerManager.currentSongNotifier,
              builder: (context, song, _) {
                if (song == null) return const SizedBox(width: 40);
                return ValueListenableBuilder<bool>(
                  valueListenable: playerManager.isPlayingNotifier,
                  builder: (context, isPlaying, _) => SearchRotatingArtwork(
                    artwork: song.artwork,
                    isPlaying: isPlaying,
                    isAdo: AdoHandler.isAdo(song),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary(mode)),
                cursorColor: AppColors.primaryBlueLight,
                decoration: InputDecoration(
                  hintText: 'Buscar canciones, artistas...',
                  hintStyle: TextStyle(color: AppColors.textSecondary(mode)),
                  border: InputBorder.none,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Ionicons.close_circle,
                            color: AppColors.textSecondary(mode),
                          ),
                          onPressed: () => searchController.clear(),
                          splashRadius: 20,
                        )
                      : null,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Ionicons.close, color: AppColors.icon(mode)),
              onPressed: onSearchTap,
              splashRadius: 20,
            ),
          ],
        );
      },
    );
  }

  /// Construye un icono del app bar con estilo actual
  Widget _buildTopBarIcon(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    required BuildContext context,
  }) {
    final mode = context.watch<ThemeService>().mode;
    return IconButton(
      icon: Icon(icon, color: color ?? AppColors.icon(mode)),
      onPressed: onTap,
      splashRadius: 20,
    );
  }

  /// Envuelve un widget con animación de escala al aparecer
  Widget _buildPopAnimation(Key key, Widget child) {
    return AnimationConfiguration.synchronized(
      key: key,
      duration: const Duration(milliseconds: 500),
      child: ScaleAnimation(scale: 0.5, curve: Curves.elasticOut, child: child),
    );
  }
}

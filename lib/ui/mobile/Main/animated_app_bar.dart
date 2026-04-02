import 'dart:ui';
import 'package:animations_plus/animations_plus.dart' hide ScaleAnimation;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/mobile/Home/favorites/mobile_favorites_page.dart';
import 'package:mg_music/ui/mobile/Home/playlist/mobile_playlists_page.dart';
import 'package:mg_music/ui/mobile/Home/Player/mobile_mini_player.dart';
import 'package:mg_music/ui/mobile/Main/painters.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/ui/mobile/Main/search_rotating_artwork.dart';
import 'package:mg_music/services/ui/ado_experience_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

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

  final String? subPageTitle;
  final VoidCallback? onBack;

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
    this.subPageTitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleFadeAnimation(
      duration: const Duration(milliseconds: 400),
      child: SimpleSlideAnimation(
        duration: const Duration(milliseconds: 400),
        direction: SlideDirection.up,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16.r),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Consumer<ThemeService>(
              builder: (context, themeService, _) {
                final mode = themeService.mode;
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: AppBarPainter(
                      borderColor: AppColors.themeBorder(mode),
                      mode: mode,
                    ),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        bottom: 5.h,
                        left: 10.w,
                        right: 10.w,
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
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAppBarContent() {
    final playerManager = AudioPlayerManager();
    return ValueListenableBuilder<LocalSong?>(
      valueListenable: playerManager.currentSongNotifier,
      builder: (context, song, _) {
        final isAdo = song != null && AdoHandler.isAdo(song);
        final specialEnabled = AdoExperienceService().dedicatedPlayerEnabled;
        final isSpecialExpanded = showFullPlayer && isAdo && specialEnabled;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSpecialExpanded 
              ? _buildSpecialAppBarContent(context, song)
              : _buildStandardAppBarContent(context),
        );
      }
    );
  }

  Widget _buildSpecialAppBarContent(BuildContext context, LocalSong song) {
    final playerManager = AudioPlayerManager();
    final mode = context.watch<ThemeService>().mode;
    
    return SimpleFadeAnimation(
      key: const ValueKey('special_app_bar'),
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: playerManager.isShuffleModeNotifier,
            builder: (context, isShuffle, _) {
              return IconButton(
                icon: Icon(
                  Ionicons.shuffle,
                  color: isShuffle ? AppColors.primaryBlueFixed : AppColors.textSecondary(mode),
                ),
                onPressed: playerManager.toggleShuffleMode,
              );
            }
          ),
          Expanded(
            child: MobileMiniPlayer(
              showVisualizer: false,
              isSpecialExpanded: true,
              onTap: onToggleFullPlayer,
            ),
          ),
          ValueListenableBuilder<LoopMode>(
            valueListenable: playerManager.loopModeNotifier,
            builder: (context, loopMode, _) {
              Color color = AppColors.textSecondary(mode);
              if (loopMode == LoopMode.one || loopMode == LoopMode.all) {
                 color = AppColors.primaryBlueFixed;
              }
              IconData icon = Ionicons.repeat;
              if (loopMode == LoopMode.one) {
                 icon = Ionicons.repeat; 
              }
              return IconButton(
                icon: Icon(icon, color: color),
                onPressed: playerManager.toggleLoopMode,
              );
            }
          ),
        ]
      ),
    );
  }

  Widget _buildStandardAppBarContent(BuildContext context) {
    const contentDelay = Duration(milliseconds: 400);

    Widget iconTransition(Widget child, Animation<double> animation) {
      return FadeTransition(opacity: animation, child: child);
    }

    Widget contentTransition(Widget child, Animation<double> animation) {
      final offsetAnimation = CurveTween(curve: Curves.easeOutCubic)
          .animate(animation)
          .drive(Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ));

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    }

    return SimpleFadeAnimation(
      delay: contentDelay,
      duration: const Duration(milliseconds: 300),
      child: Builder(
        builder: (context) {
          return Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: iconTransition,
                child: _buildLeftAppBarIcon(context),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0.w),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: contentTransition,
                    child: subPageTitle != null
                        ? Center(
                            child: Text(
                              subPageTitle!,
                              style: TextStyle(
                                color: AppColors.textPrimary(
                                  context.read<ThemeService>().mode,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : MobileMiniPlayer(
                            showVisualizer: showFullPlayer,
                            onTap: onToggleFullPlayer,
                          ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: iconTransition,
                child: _buildRightAppBarIcon(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftAppBarIcon(BuildContext context) {
    if (subPageTitle != null) {
      return _buildPopAnimation(
        const ValueKey('back_sub'),
        _buildTopBarIcon(
          Ionicons.arrow_back,
          () => onBack?.call(),
          context: context,
        ),
      );
    }
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
    if (selectedIndex == 3 && !showFullPlayer && !isFavoritesSelectionMode) {
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
      SizedBox(width: 44.w),
    );
  }

  Widget _buildRightAppBarIcon(BuildContext context) {
    if (subPageTitle != null) {
      final playerManager = AudioPlayerManager();
      return ValueListenableBuilder<LocalSong?>(
        valueListenable: playerManager.currentSongNotifier,
        builder: (context, song, _) {
          if (song == null) return SizedBox(width: 44.w);
          return ValueListenableBuilder<bool>(
            valueListenable: playerManager.isPlayingNotifier,
            builder:
                (context, isPlaying, _) => SearchRotatingArtwork(
                  artwork: song.artwork,
                  isPlaying: isPlaying,
                  isAdo: AdoHandler.isAdo(song),
                  onTap: () => playerManager.togglePlayPause(),
                ),
          );
        },
      );
    }
    if (selectedIndex == 0 && !showFullPlayer) {
      return _buildPopAnimation(
        const ValueKey('artists'),
        _buildTopBarIcon(Ionicons.people, onArtistFilterTap, context: context),
      );
    }
    if (selectedIndex == 3 && !showFullPlayer) {
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
      SizedBox(width: 44.w),
    );
  }

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
                if (song == null) return SizedBox(width: 40.w);
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
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                autofocus: true,
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 14.sp,
                ),
                cursorColor: AppColors.primaryBlueLight,
                decoration: InputDecoration(
                  hintText: 'Buscar canciones, artistas...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary(mode),
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Ionicons.close_circle,
                            color: AppColors.textSecondary(mode),
                          ),
                          onPressed: () => searchController.clear(),
                          splashRadius: 20.r,
                        )
                      : null,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Ionicons.close, color: AppColors.icon(mode)),
              onPressed: onSearchTap,
              splashRadius: 20.r,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBarIcon(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    required BuildContext context,
  }) {
    final mode = context.watch<ThemeService>().mode;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 650;
    
    return IconButton(
      icon: Icon(icon, color: color ?? AppColors.icon(mode)),
      onPressed: onTap,
      splashRadius: 20.r,
      iconSize: (isShort ? 22 : 24).r, 
    );
  }

  Widget _buildPopAnimation(Key key, Widget child) {
    return AnimationConfiguration.synchronized(
      key: key,
      duration: const Duration(milliseconds: 500),
      child: ScaleAnimation(scale: 0.5, curve: Curves.elasticOut, child: child),
    );
  }
}

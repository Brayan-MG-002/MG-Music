// Copyright © 2026 Brayan Medrano - MG Music
// Página de inicio Mobile

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

// Importación de componentes divididos
import 'components/mobile_song_item.dart';
import 'components/mobile_home_header.dart';
import 'components/mobile_home_shimmer.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';

class MobileHomePage extends StatefulWidget {
  final List<LocalSong> songs;
  final Function(List<LocalSong>) onSongsLoaded;
  final VoidCallback? onOpenPlayer;

  const MobileHomePage({
    super.key,
    required this.songs,
    required this.onSongsLoaded,
    this.onOpenPlayer,
  });

  @override
  State<MobileHomePage> createState() => MobileHomePageState();
}

class MobileHomePageState extends State<MobileHomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final SongFetcher _songFetcher = SongFetcher();
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  bool _isLoading = true;
  bool _isReanimating = false; // Shimmer breve al volver a Home
  bool _isGridView = true;

  late AnimationController _headerAnimationController;

  final ScrollController _scrollController = ScrollController();

  // Llave para forzar la reconstrucción de la lista y disparar animaciones al reordenar
  Key _listKey = UniqueKey();

  @override
  /// Mantiene el estado al cambiar de pestañas
  bool get wantKeepAlive => true;

  @override
  /// Inicializa animaciones, reproductor y carga preferencias/canciones
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _playerManager.init();
    _loadPreferencesAndSongs();
  }

  @override
  /// Dispara animación del header cuando hay dependencias listas
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_headerAnimationController.status != AnimationStatus.completed) {
      _headerAnimationController.forward();
    }
  }

  @override
  /// Reanima lista al cambiar el conjunto de canciones
  void didUpdateWidget(MobileHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.songs != oldWidget.songs) {
      setState(() {
        _listKey = UniqueKey();
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  /// Libera controladores
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> triggerExitAnimation() async {
    await _headerAnimationController.reverse();
  }

  /// Relanza las animaciones de entrada de las canciones.
  /// Llamado por MobileMainScreen cuando el usuario navega de vuelta a Home.
  Future<void> triggerEnterAnimation() async {
    if (!mounted || _isLoading) return;

    setState(() => _isReanimating = true);
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    setState(() {
      _isReanimating = false;
      _listKey = UniqueKey();
    });

    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    _headerAnimationController.reset();
    _headerAnimationController.forward();
  }

  /// Carga modo de vista y canciones
  Future<void> _loadPreferencesAndSongs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool('home_view_mode') ?? true;
      });
    }
    await _loadSongs(isInitialLoad: true);
  }

  /// Carga canciones y notifica al padre progresivamente
  Future<void> _loadSongs({bool isInitialLoad = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final loadedSongs = isInitialLoad && _playerManager.cachedSongs.isNotEmpty
        ? List<LocalSong>.from(_playerManager.cachedSongs)
        : await _songFetcher.getSongs(
            onProgress: (earlySongs) {
              if (mounted && _isLoading) {
                widget.onSongsLoaded(earlySongs);
                setState(() => _isLoading = false);
              }
            },
          );
    if (mounted) {
      widget.onSongsLoaded(loadedSongs);
      setState(() => _isLoading = false);
    }
  }

  /// Persiste el modo de vista
  Future<void> _saveViewMode(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_view_mode', isGrid);
  }

  /// Desplaza la lista hasta la canción actual si existe
  void _scrollToCurrentSong() {
    final currentSong = _playerManager.currentSongNotifier.value;
    if (currentSong == null || widget.songs.isEmpty) return;
    final index = widget.songs.indexWhere((s) => s.id == currentSong.id);
    if (index == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      double offset = 0;
      if (_isGridView) {
        try {
          final screenWidth = MediaQuery.of(context).size.width;
          const crossAxisCount = 3;
          const crossAxisSpacing = 16.0;
          const paddingHorizontal = 32.0;
          final itemWidth =
              (screenWidth -
                  paddingHorizontal -
                  (crossAxisSpacing * (crossAxisCount - 1))) /
              crossAxisCount;
          final itemHeight = itemWidth / 0.7;
          const mainAxisSpacing = 16.0;
          final row = index ~/ crossAxisCount;
          offset = row * (itemHeight + mainAxisSpacing);
        } catch (_) {}
      } else {
        offset = index * 80.0;
      }
      final maxScroll = _scrollController.positions.isNotEmpty
          ? _scrollController.positions.last.maxScrollExtent
          : 0.0;
      _scrollController.animateTo(
        offset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  /// Construye la pantalla de inicio con pull-to-refresh y encabezado
  Widget build(BuildContext context) {
    super.build(context);
    final mode = context.watch<ThemeService>().mode;

    return WillPopScope(
      onWillPop: () async {
        await triggerExitAnimation();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _loadSongs(isInitialLoad: true),
              edgeOffset: 60.0,
              color: AppColors.themeBorder(mode),
              backgroundColor: AppColors.background(mode),
              child: _isLoading && widget.songs.isEmpty || _isReanimating
                  ? MobileHomeShimmer(isGridView: _isGridView)
                  : (_isGridView ? _buildGridView(mode) : _buildListView(mode)),
            ),
            MobileHomeHeader(
              isGridView: _isGridView,
              onViewModeChanged: _toggleViewMode,
            ),
          ],
        ),
        floatingActionButton: _buildCurrentSongFAB(mode),
      ),
    );
  }

  /// Alterna entre grilla y lista conservando posición aproximada
  void _toggleViewMode() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.positions.isNotEmpty
        ? _scrollController.positions.last.pixels
        : 0.0;
    int topVisibleIndex = 0;

    if (_isGridView) {
      final screenWidth = MediaQuery.of(context).size.width;
      const crossAxisCount = 3;
      const crossAxisSpacing = 16.0;
      const paddingHorizontal = 32.0;
      final itemWidth =
          (screenWidth -
              paddingHorizontal -
              (crossAxisSpacing * (crossAxisCount - 1))) /
          crossAxisCount;
      final itemHeight = itemWidth / 0.7; // childAspectRatio
      const mainAxisSpacing = 16.0;

      final adjustedOffset = (currentOffset - 60).clamp(0.0, double.infinity);
      final row = (adjustedOffset / (itemHeight + mainAxisSpacing)).floor();
      topVisibleIndex = row * crossAxisCount;
    } else {
      const itemHeight = 80.0;
      final adjustedOffset = (currentOffset - 60).clamp(0.0, double.infinity);
      topVisibleIndex = (adjustedOffset / itemHeight).floor();
    }

    setState(() {
      _isGridView = !_isGridView;
      _saveViewMode(_isGridView);
      _listKey = UniqueKey();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      double newOffset = 0.0;
      if (_isGridView) {
        final screenWidth = MediaQuery.of(context).size.width;
        const crossAxisCount = 3;
        const crossAxisSpacing = 16.0;
        const paddingHorizontal = 32.0;
        final itemWidth =
            (screenWidth -
                paddingHorizontal -
                (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final itemHeight = itemWidth / 0.7;
        const mainAxisSpacing = 16.0;

        final row = topVisibleIndex ~/ crossAxisCount;
        newOffset = 60 + (row * (itemHeight + mainAxisSpacing));
      } else {
        const itemHeight = 80.0;
        newOffset = 60 + (topVisibleIndex * itemHeight);
      }

      final maxScroll = _scrollController.positions.isNotEmpty
          ? _scrollController.positions.last.maxScrollExtent
          : 0.0;
      _scrollController.jumpTo(newOffset.clamp(0.0, maxScroll));
    });
  }

  /// FAB que salta a la canción actual si no está visible
  Widget _buildCurrentSongFAB(AppThemeMode mode) {
    return ValueListenableBuilder<LocalSong?>(
      valueListenable: _playerManager.currentSongNotifier,
      builder: (context, currentSong, _) {
        if (currentSong == null || widget.songs.isEmpty) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            bool isVisibleOnScreen = false;

            if (_scrollController.hasClients &&
                _scrollController.positions.isNotEmpty) {
              final pos = _scrollController.positions.last;

              // Evitar "Null check operator used on a null value" durante la construcción inicial
              if (pos.hasPixels && pos.hasContentDimensions) {
                final index = widget.songs.indexWhere(
                  (s) => s.id == currentSong.id,
                );

                if (index != -1) {
                  final currentOffset = pos.pixels;
                  final viewportHeight = pos.viewportDimension;

                  double itemTopOffset = 0;
                  double itemBottomOffset = 0;

                  if (_isGridView) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    const crossAxisCount = 3;
                    const crossAxisSpacing = 16.0;
                    const paddingHorizontal = 32.0;
                    final itemWidth =
                        (screenWidth -
                            paddingHorizontal -
                            (crossAxisSpacing * (crossAxisCount - 1))) /
                        crossAxisCount;
                    final itemHeight = itemWidth / 0.7;
                    const mainAxisSpacing = 16.0;

                    final row = index ~/ crossAxisCount;
                    itemTopOffset = 60 + (row * (itemHeight + mainAxisSpacing));
                    itemBottomOffset = itemTopOffset + itemHeight;
                  } else {
                    const itemHeight = 80.0;
                    itemTopOffset = 60 + (index * itemHeight);
                    itemBottomOffset = itemTopOffset + itemHeight;
                  }

                  // Considerar visible si al menos una parte del item está en el viewport
                  isVisibleOnScreen =
                      (itemBottomOffset > currentOffset) &&
                      (itemTopOffset < currentOffset + viewportHeight);
                }
              }
            }

            return AnimatedScale(
              scale: isVisibleOnScreen ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              child: AnimatedOpacity(
                opacity: isVisibleOnScreen ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 80.0,
                  ), // Margen para evitar solapamiento con la Bottom Nav
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: AppColors.fabGradient(mode),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [
                              0.3,
                              1.0,
                            ], // Más espacio visual para el azul
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.fabAccent(mode).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: 'mobile_home_fab',
                          onPressed: _scrollToCurrentSong,
                          backgroundColor:
                              Colors.transparent, // Deja ver el gradiente
                          elevation: 0,
                          highlightElevation:
                              0, // Las sombras las maneja el Container superior
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.fabAccent(mode).withOpacity(0.7),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: AppColors.fabAccent(mode),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construye la grilla de canciones
  Widget _buildGridView(AppThemeMode mode) {
    return AnimationLimiter(
      key: _listKey,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
        controller: _scrollController,
        cacheExtent: 1000,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: widget.songs.length,
        itemBuilder: (context, index) {
          final song = widget.songs[index];
          final isAdo = AdoHandler.isAdo(song);

          final animationDuration = index < 15
              ? const Duration(milliseconds: 375)
              : const Duration(milliseconds: 200);

          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 3,
            duration: animationDuration,
            child: FadeInAnimation(
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: ValueListenableBuilder<LocalSong?>(
                  valueListenable: _playerManager.currentSongNotifier,
                  builder: (context, currentSong, _) {
                    return MobileSongItem(
                      song: song,
                      isAdo: isAdo,
                      isGrid: true,
                      isPlaying: currentSong?.id == song.id,
                      onTap: () {
                        if (currentSong?.id == song.id) {
                          widget.onOpenPlayer?.call();
                        } else {
                          _playerManager.playSong(song, widget.songs);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye la lista de canciones
  Widget _buildListView(AppThemeMode mode) {
    const double itemHeight = 80.0;
    return AnimationLimiter(
      key: _listKey,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 60, bottom: 140),
        controller: _scrollController,
        cacheExtent: 1000,
        itemExtent: itemHeight,
        itemCount: widget.songs.length,
        itemBuilder: (context, index) {
          final song = widget.songs[index];
          final isAdo = AdoHandler.isAdo(song);

          final animationDuration = index < 15
              ? const Duration(milliseconds: 375)
              : const Duration(milliseconds: 200);

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: animationDuration,
            child: FadeInAnimation(
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: ValueListenableBuilder<LocalSong?>(
                  valueListenable: _playerManager.currentSongNotifier,
                  builder: (context, currentSong, _) {
                    return SizedBox(
                      height: itemHeight,
                      child: MobileSongItem(
                        song: song,
                        isAdo: isAdo,
                        isGrid: false,
                        isPlaying: currentSong?.id == song.id,
                        onTap: () {
                          if (currentSong?.id == song.id) {
                            widget.onOpenPlayer?.call();
                          } else {
                            _playerManager.playSong(song, widget.songs);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Página de inicio Mobile

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

import 'components/mobile_song_item.dart';
import 'components/mobile_home_header.dart';
import 'components/mobile_home_shimmer.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/folder_settings_modal.dart';
import 'dart:io';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/playlist_action_service.dart';

class MobileHomePage extends StatefulWidget {
  final List<LocalSong> songs;
  final bool isScanning;
  final Function(List<LocalSong>) onSongsLoaded;
  final Function(List<LocalSong>) onScanComplete;
  final VoidCallback? onForceRefresh;
  final VoidCallback? onOpenPlayer;
  final VoidCallback? onSearchTriggered;
  final void Function(LocalSong)? onEditSong;
  final void Function(LocalSong)? onSongDeleted;

  const MobileHomePage({
    super.key,
    required this.songs,
    required this.isScanning,
    required this.onSongsLoaded,
    required this.onScanComplete,
    this.onForceRefresh,
    this.onOpenPlayer,
    this.onSearchTriggered,
    this.onEditSong,
    this.onSongDeleted,
  });

  @override
  State<MobileHomePage> createState() => MobileHomePageState();
}

class MobileHomePageState extends State<MobileHomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  bool _isLoading = true;
  bool _isReanimating = false;
  bool _isGridView = true;

  final Set<LocalSong> _selectedSongs = {};

  late AnimationController _headerAnimationController;

  final ScrollController _scrollController = ScrollController();

  // Llave para forzar la reconstrucción de la lista y disparar animaciones al reordenar
  Key _listKey = UniqueKey();

  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _playerManager.init();
    SongFetcher.onLibraryChanged.addListener(_onLibraryChanged);
    _loadPreferencesAndSongs();
  }

  void _onLibraryChanged() {
    // El escaneo real está en MobileMainScreen; aquí solo forzamos un re-sort/re-render
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_headerAnimationController.status != AnimationStatus.completed) {
      _headerAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(MobileHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ya no forzamos un UniqueKey nuevo ni saltamos al inicio si la lista cambia.
    // Esto permite que las canciones nuevas se agreguen abajo sin interrumpir
    // la navegación del usuario durante el escaneo.
  }

  @override
  void dispose() {
    SongFetcher.onLibraryChanged.removeListener(_onLibraryChanged);
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> triggerExitAnimation() async {
    await _headerAnimationController.reverse();
  }

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

  Future<void> _loadPreferencesAndSongs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool('home_view_mode') ?? true;
        if (widget.songs.isNotEmpty) {
          _isLoading = false;
        }
      });
    }

    if (widget.songs.isNotEmpty || !SongFetcher.isScanning) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveViewMode(bool isGrid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_view_mode', isGrid);
  }

  void _toggleSelection(LocalSong song) {
    setState(() {
      if (_selectedSongs.any((s) => s.id == song.id)) {
        _selectedSongs.removeWhere((s) => s.id == song.id);
      } else {
        _selectedSongs.add(song);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSongs.clear();
    });
  }

  Future<void> _bulkFavorite() async {
    final songs = _selectedSongs.toList();
    for (var song in songs) {
      await FavoritesManager().addFavorite(song);
    }
    _clearSelection();
    if (mounted) {
      CustomToastService.show(
        context,
        message: '${songs.length} pistas añadidas a Favoritos',
        type: ToastType.success,
        icon: Ionicons.heart,
      );
    }
  }

  Future<void> _bulkPlaylist() async {
    final songs = _selectedSongs.toList();
    await PlaylistActionService.showAddMultipleToPlaylistDialog(context, songs);
    _clearSelection();
  }

  Future<void> _bulkDelete() async {
    final songs = _selectedSongs.toList();
    final confirmed = await GlobalModalService.showConfirmation(
      title: 'Eliminar múltiples pistas',
      message:
          '¿Eliminar ${songs.length} pistas seleccionadas del almacenamiento?\n\nEsta acción es permanente.',
      icon: Ionicons.warning_outline,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.redAccent,
    );

    if (!confirmed) return;

    int deletedCount = 0;
    for (var song in songs) {
      try {
        final file = File(song.path);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
        }
      } catch (_) {}
    }

    _clearSelection();
    if (deletedCount > 0) {
      _onLibraryChanged(); // Recargar lista
      if (mounted) {
        CustomToastService.show(
          context,
          message: '$deletedCount pistas eliminadas',
          type: ToastType.success,
          icon: Ionicons.checkmark_circle,
        );
      }
    }
  }

  void _showBulkActionsMenu(BuildContext context, AppThemeMode mode) {
    BottomModalService.show(
      context,
      title: 'Acciones en lote',
      subtitle: '${_selectedSongs.length} pistas seleccionadas',
      options: [
        BottomModalOption(
          icon: Ionicons.heart_outline,
          label: "Agregar a Favoritos",
          onTap: () {
            Navigator.pop(context);
            _bulkFavorite();
          },
        ),
        BottomModalOption(
          icon: Ionicons.add_circle_outline,
          label: "Agregar a Playlist",
          onTap: () {
            Navigator.pop(context);
            _bulkPlaylist();
          },
        ),
        BottomModalOption(
          icon: Ionicons.trash_outline,
          label: "Eliminar seleccionadas",
          color: Colors.redAccent,
          textColor: Colors.redAccent,
          onTap: () {
            Navigator.pop(context);
            _bulkDelete();
          },
        ),
        BottomModalOption(
          icon: Ionicons.close_circle_outline,
          label: "Cancelar selección",
          onTap: () {
            Navigator.pop(context);
            _clearSelection();
          },
        ),
      ],
    );
  }

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
          final crossAxisSpacing = 16.0.w;
          final paddingHorizontal = 32.0.w;
          final itemWidth =
              (screenWidth -
                  paddingHorizontal -
                  (crossAxisSpacing * (crossAxisCount - 1))) /
              crossAxisCount;
          final itemHeight = itemWidth / 0.7;
          final mainAxisSpacing = 16.0.h;
          final row = index ~/ crossAxisCount;
          offset = row * (itemHeight + mainAxisSpacing);
        } catch (_) {}
      } else {
        final itemHeight = 80.0.h;
        offset = index * itemHeight;
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
              onRefresh: () async => widget.onForceRefresh?.call(),
              edgeOffset: 65.h,
              color: AppColors.themeBorder(mode),
              backgroundColor: AppColors.background(mode),
              child: _isLoading && widget.songs.isEmpty || _isReanimating
                  ? MobileHomeShimmer(isGridView: _isGridView)
                  : (widget.songs.isEmpty
                        ? _buildEmptyState(mode)
                        : (_isGridView
                              ? _buildGridView(mode)
                              : _buildListView(mode))),
            ),
            MobileHomeHeader(
              isGridView: _isGridView,
              isScanning: widget.isScanning,
              selectedCount: _selectedSongs.length,
              onViewModeChanged: _toggleViewMode,
            ),
          ],
        ),
        floatingActionButton: _selectedSongs.isNotEmpty
            ? _buildBulkActionsFAB(mode)
            : _buildCurrentSongFAB(mode),
      ),
    );
  }

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

      final adjustedOffset = (currentOffset - 65.h).clamp(0.0, double.infinity);
      final row = (adjustedOffset / (itemHeight + mainAxisSpacing)).floor();
      topVisibleIndex = row * crossAxisCount;
    } else {
      const itemHeight = 80.0;
      final adjustedOffset = (currentOffset - 65.h).clamp(0.0, double.infinity);
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

  Widget _buildEmptyState(AppThemeMode mode) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final prefs = snapshot.data!;
        final scanAll = prefs.getBool('scan_all_device') ?? true;
        final folders = prefs.getStringList('music_scan_folders') ?? [];

        String message = 'No se encontraron canciones en el dispositivo.';
        String subMessage =
            'Intenta actualizar tirando de la lista o verifica tus carpetas.';

        if (!scanAll && folders.isEmpty) {
          message = 'No has seleccionado carpetas.';
          subMessage =
              'Configura las carpetas donde guardas tu música para empezar a escuchar.';
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: AnimationConfiguration.synchronized(
                duration: const Duration(milliseconds: 600),
                child: FadeInAnimation(
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: Container(
                      height: constraints.maxHeight,
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.musical_notes_outline,
                            size: 80.r,
                            color: AppColors.textSecondary(
                              mode,
                            ).withOpacity(0.5),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary(mode),
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            subMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(mode),
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 32.h),
                          GestureDetector(
                            onTap: () =>
                                FolderSettingsContent.showModal(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.fabGradient(mode),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppColors.fabAccent(
                                    mode,
                                  ).withOpacity(0.6),
                                  width: 1.5.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.fabAccent(
                                      mode,
                                    ).withOpacity(0.3),
                                    blurRadius: 12.r,
                                    spreadRadius: 2.r,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Ionicons.folder_open_outline,
                                    color: AppColors.textPrimary(mode),
                                    size: 22.r,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Configurar Ubicación',
                                    style: TextStyle(
                                      color: AppColors.textPrimary(mode),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                    itemTopOffset =
                        65.h + (row * (itemHeight + mainAxisSpacing));
                    itemBottomOffset = itemTopOffset + itemHeight;
                  } else {
                    const itemHeight = 80.0;
                    itemTopOffset = 65.h + (index * itemHeight);
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
                  padding: EdgeInsets.only(
                    bottom: 80.0.h,
                  ), // Margen para evitar solapamiento con la Bottom Nav
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 56.r,
                        height: 56.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
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
                              blurRadius: 15.r,
                              spreadRadius: 2.r,
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
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(
                              color: AppColors.fabAccent(mode).withOpacity(0.7),
                              width: 1.5.w,
                            ),
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: widget.onSearchTriggered,
                            child: SizedBox.expand(
                              child: Center(
                                child: Icon(
                                  Ionicons.search,
                                  color: AppColors.fabAccent(mode),
                                  size: 26.r,
                                ),
                              ),
                            ),
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

  Widget _buildBulkActionsFAB(AppThemeMode mode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 80.0.h),
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: AppColors.fabGradient(mode),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.fabAccent(mode).withOpacity(0.4),
              blurRadius: 15.r,
              spreadRadius: 2.r,
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'bulk_actions_fab',
          onPressed: () => _showBulkActionsMenu(context, mode),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(
              color: AppColors.fabAccent(mode).withOpacity(0.7),
              width: 1.5.w,
            ),
          ),
          child: Icon(
            Ionicons.layers_outline,
            color: AppColors.fabAccent(mode),
            size: 26.r,
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(AppThemeMode mode) {
    return GridView.builder(
      key: _listKey,
      padding: EdgeInsets.fromLTRB(16.w, 65.h, 16.w, 100.h),
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

        return ValueListenableBuilder<LocalSong?>(
          valueListenable: _playerManager.currentSongNotifier,
          builder: (context, currentSong, _) {
            return MobileSongItem(
              key: ValueKey(song.id),
              song: song,
              isAdo: isAdo,
              isGrid: true,
              isPlaying: currentSong?.id == song.id,
              isSelected: _selectedSongs.any((s) => s.id == song.id),
              onTap: () {
                if (_selectedSongs.isNotEmpty) {
                  _toggleSelection(song);
                } else if (currentSong?.id == song.id) {
                  widget.onOpenPlayer?.call();
                } else {
                  _playerManager.playSong(song, widget.songs);
                }
              },
              onDoubleTap: () => _toggleSelection(song),
              onEditSong: widget.onEditSong != null
                  ? () => widget.onEditSong!(song)
                  : null,
              onSongDeleted: widget.onSongDeleted != null
                  ? () => widget.onSongDeleted!(song)
                  : null,
              onMultiSelect: () => _toggleSelection(song),
            );
          },
        );
      },
    );
  }

  /// Construye la lista de canciones
  Widget _buildListView(AppThemeMode mode) {
    final double itemHeight = 80.0.h;
    return ListView.builder(
      key: _listKey,
      padding: EdgeInsets.only(top: 65.h, bottom: 140.h),
      controller: _scrollController,
      cacheExtent: 1000,
      itemExtent: itemHeight,
      itemCount: widget.songs.length,
      itemBuilder: (context, index) {
        final song = widget.songs[index];
        final isAdo = AdoHandler.isAdo(song);

        return ValueListenableBuilder<LocalSong?>(
          valueListenable: _playerManager.currentSongNotifier,
          builder: (context, currentSong, _) {
            return SizedBox(
              height: itemHeight,
              child: MobileSongItem(
                key: ValueKey(song.id),
                song: song,
                isAdo: isAdo,
                isGrid: false,
                isPlaying: currentSong?.id == song.id,
                isSelected: _selectedSongs.any((s) => s.id == song.id),
                onTap: () {
                  if (_selectedSongs.isNotEmpty) {
                    _toggleSelection(song);
                  } else if (currentSong?.id == song.id) {
                    widget.onOpenPlayer?.call();
                  } else {
                    _playerManager.playSong(song, widget.songs);
                  }
                },
                onDoubleTap: () => _toggleSelection(song),
                onEditSong: widget.onEditSong != null
                    ? () => widget.onEditSong!(song)
                    : null,
                onSongDeleted: widget.onSongDeleted != null
                    ? () => widget.onSongDeleted!(song)
                    : null,
                onMultiSelect: () => _toggleSelection(song),
              ),
            );
          },
        );
      },
    );
  }
}

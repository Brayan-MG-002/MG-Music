// Copyright © 2026 Brayan Medrano - MG Music
// Página de inicio para la interfaz de TV: carga progresiva de biblioteca, detección de canciones de Ado y navegación por grilla.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:ionicons/ionicons.dart';
import 'tv_home_song_item.dart';
import 'tv_home_top_bar.dart';
import 'tv_home_dialogs.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/folder_settings_modal.dart';
import 'package:mg_music/services/ui/song_context_menu_service.dart';
import 'package:mg_music/ui/mobile/Home/EditSong/edit_song_page.dart';

class TvHomePage extends StatefulWidget {
  final VoidCallback onOpenPlayer;
  const TvHomePage({super.key, required this.onOpenPlayer});

  @override
  State<TvHomePage> createState() => _TvHomePageState();
}

class _TvHomePageState extends State<TvHomePage>
    with AutomaticKeepAliveClientMixin {
  final SongFetcher _songFetcher = SongFetcher();
  final AudioPlayerManager _playerManager = AudioPlayerManager();

  List<LocalSong> _allSongs = [];
  List<LocalSong> _displayedSongs = [];
  bool _isLoading = true;
  bool _hasEarlyLoad = false;

  Key _gridKey = UniqueKey();
  bool _isAscending = true;

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerManager.init();
    SongFetcher.onLibraryChanged.addListener(_onLibraryChanged);
    _loadSongs();
    _playerManager.currentSongNotifier.addListener(_scrollToCurrentSong);
  }

  void _onLibraryChanged() {
    if (mounted) {
      _loadSongs();
    }
  }

  @override
  void dispose() {
    SongFetcher.onLibraryChanged.removeListener(_onLibraryChanged);
    _playerManager.currentSongNotifier.removeListener(_scrollToCurrentSong);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    if (_playerManager.cachedSongs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allSongs = _playerManager.cachedSongs;
          _displayedSongs = List.from(_allSongs);
          _sortAdoPrimero();
          _isLoading = false;
        });
      }
      _playerManager.executeStartupBehavior(_allSongs);
      _songFetcher.getSongs(forceRefresh: false).then((fresh) {
        if (!mounted) return;
        if (fresh.length != _allSongs.length) {
          setState(() {
            _allSongs = fresh;
            _displayedSongs = List.from(fresh);
            _sortAdoPrimero();
          });
          _verifyAdoSongs(fresh);
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasEarlyLoad = false;
    });

    final freshSongs = await _songFetcher.getSongs(
      onProgress: (early) {
        if (mounted && _isLoading && !_hasEarlyLoad) {
          setState(() {
            _allSongs = early;
            _displayedSongs = List.from(early);
            _sortAdoPrimero();
            _isLoading = false;
            _hasEarlyLoad = true;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _allSongs = freshSongs;
        _displayedSongs = List.from(freshSongs);
        _sortAdoPrimero();
        _isLoading = false;
        _gridKey = UniqueKey();
      });
    }

    await _playerManager.executeStartupBehavior(freshSongs);

    _verifyAdoSongs(freshSongs);
  }

  Future<void> _verifyAdoSongs(List<LocalSong> songs) async {
    final adoSongs = songs.where((s) => AdoHandler.isAdo(s)).toList();
    final hasAdo = adoSongs.isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    final lastAdoCount = prefs.getInt('last_ado_count') ?? 0;
    await prefs.setBool('has_ado_songs', hasAdo);
    await prefs.setInt('last_ado_count', adoSongs.length);

    if (!mounted) return;

    if (hasAdo) {
      final pm = PlaylistManager();
      const autoPlaylistName = '⭐ Ado';
      await pm.createOrUpdateAutoPlaylist(autoPlaylistName, adoSongs);

      if (adoSongs.length > lastAdoCount) {
        GlobalModalService.show(
          title: 'Detección de Ado',
          icon: Ionicons.star,
          primaryColor: Colors.blue.shade900,
          content: Text(
            '¡Se han encontrado ${adoSongs.length} canciones de Ado! '
            'La playlist "$autoPlaylistName" ha sido actualizada y está lista para sonar.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ModalActionButton(
              label: 'Entendido',
              color: AppColors.primaryBlueMid,
              onPressed: () => Navigator.pop(
                GlobalModalService.navigatorKey.currentContext!,
              ),
            ),
          ],
        );
      }
    }
  }


  void _sortAdoPrimero() {
    _displayedSongs.sort((a, b) {
      final aAdo = AdoHandler.isAdo(a);
      final bAdo = AdoHandler.isAdo(b);
      if (aAdo && !bAdo) return -1;
      if (!aAdo && bAdo) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    _playerManager.updatePlaylist(_displayedSongs);
  }

  void _sortAlpha(bool ascending) {
    setState(() {
      _isAscending = ascending;
      _displayedSongs.sort(
        (a, b) => ascending
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
      _playerManager.updatePlaylist(_displayedSongs);
      _gridKey = UniqueKey();
    });
  }

  void _filterByArtist(String? artist) {
    setState(() {
      _displayedSongs = artist == null
          ? List.from(_allSongs)
          : _allSongs
                .where(
                  (s) =>
                      s.artist.split(',').map((a) => a.trim()).contains(artist),
                )
                .toList();
      _sortAlpha(_isAscending);
      _gridKey = UniqueKey();
    });
  }

  void _scrollToCurrentSong() {
    final current = _playerManager.currentSongNotifier.value;
    if (current == null || _displayedSongs.isEmpty) return;
    final index = _displayedSongs.indexWhere((s) => s.id == current.id);
    if (index == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      const crossAxisCount = 5;
      const itemHeight = 200.0;
      const spacing = 20.0;
      final row = index ~/ crossAxisCount;
      final offset = row * (itemHeight + spacing);
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mode = context.watch<ThemeService>().mode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TvHomeTopBar(
            mode: mode,
            onOpenPlayer: widget.onOpenPlayer,
            onShuffle: () => _playerManager.shufflePlay(_displayedSongs),
            onSort: () => showTvSortModal(
              mode: mode,
              onAdoPrimero: () => setState(() {
                _sortAdoPrimero();
                _gridKey = UniqueKey();
              }),
              onAZ: () => _sortAlpha(true),
              onZA: () => _sortAlpha(false),
            ),
            onArtists: () {
              final artists =
                  _allSongs
                      .expand((s) => s.artist.split(',').map((a) => a.trim()))
                      .where((a) => a.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
              showTvArtistModal(
                mode: mode,
                artists: artists,
                onArtistSelected: _filterByArtist,
              );
            },
          ),

          Expanded(child: _buildContent(mode)),
        ],
      ),
    );
  }

  Widget _buildContent(AppThemeMode mode) {
    if (_isLoading && _allSongs.isEmpty) {
      return _buildShimmer();
    }

    if (_allSongs.isEmpty) {
      return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          final scanAll = snapshot.data?.getBool('scan_all_device') ?? true;
          final folders = snapshot.data?.getStringList('music_scan_folders') ?? [];
          
          String message = 'No se encontraron canciones en el dispositivo.';
          String subMessage = 'Verifica que tus carpetas contengan archivos de audio compatibles.';
          
          if (!scanAll && folders.isEmpty) {
            message = 'No has seleccionado carpetas para escanear.';
            subMessage = 'Configura las ubicaciones de tu música para empezar a usar la aplicación.';
          }

          return Center(
            child: AnimationConfiguration.synchronized(
              duration: const Duration(milliseconds: 700),
              child: FadeInAnimation(
                child: ScaleAnimation(
                  scale: 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Ionicons.musical_notes_outline,
                        color: AppColors.textSecondary(mode).withOpacity(0.5),
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        message,
                        style: TextStyle(
                          color: AppColors.textPrimary(mode),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subMessage,
                        style: TextStyle(
                          color: AppColors.textSecondary(mode),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Focus(
                        child: Builder(
                          builder: (context) {
                            final hasFocus = Focus.of(context).hasFocus;
                            final textColor = hasFocus ? Colors.white : AppColors.textPrimary(mode);

                            return GestureDetector(
                              onTap: () => FolderSettingsContent.showModal(context),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: AppColors.fabGradient(mode),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: hasFocus ? Colors.white : AppColors.fabAccent(mode).withOpacity(0.6),
                                    width: hasFocus ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.fabAccent(mode).withOpacity(hasFocus ? 0.6 : 0.3),
                                      blurRadius: hasFocus ? 20 : 12,
                                      spreadRadius: hasFocus ? 4 : 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Ionicons.folder_open_outline, 
                                      color: textColor,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Configurar Ubicación',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      );
    }

    return Stack(
      children: [
        ClipRect(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.04, 0.96, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: AnimationLimiter(
              key: _gridKey,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_scrollController.hasClients &&
                      _scrollController.offset < 0) {
                    _scrollController.jumpTo(0);
                    return true;
                  }
                  return false;
                },
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  cacheExtent: 800,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: _displayedSongs.length,
                  itemBuilder: (context, index) {
                    final song = _displayedSongs[index];
                    final isAdo = AdoHandler.isAdo(song);

                    final duration = index < 15
                        ? const Duration(milliseconds: 400)
                        : const Duration(milliseconds: 200);

                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      columnCount: 5,
                      duration: duration,
                      child: FadeInAnimation(
                        child: ScaleAnimation(
                          scale: 0.85,
                          child: TvHomeSongItem(
                            song: song,
                            isAdo: isAdo,
                            onLongPress: () =>
                                SongContextMenuService.showOptions(
                              context,
                              song,
                              isTv: true,
                              onEditSong: () =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditSongPage(song: song),
                                ),
                              ),
                              onSongDeleted: () => _onLibraryChanged(),
                            ),
                            onTap: () {
                              if (_playerManager.currentSongNotifier.value?.id ==
                                  song.id) {
                                widget.onOpenPlayer();
                              } else {
                                _playerManager.playSong(song, _displayedSongs);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        if (_hasEarlyLoad && _isLoading)
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
                    color: AppColors.primaryBlueMid.withOpacity(0.4),
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
                      'Cargando más canciones...',
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
  }

  Widget _buildShimmer() {
    return GridView.builder(
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
  }
}

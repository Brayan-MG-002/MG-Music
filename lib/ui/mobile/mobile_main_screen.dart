// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla principal Mobile

import 'dart:async';
import 'dart:io';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/mobile/Home/favorites/mobile_favorites_page.dart';
import 'package:mg_music/ui/mobile/Home/Home/mobile_home_page.dart';
import 'package:mg_music/ui/mobile/Home/playlist/mobile_playlists_page.dart';
import 'package:mg_music/ui/mobile/Home/Player/mobile_full_player.dart';
import 'package:mg_music/ui/mobile/Home/Settings/mobile_settings_page.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/whats_new_page.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/backup_settings_page.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/ui/mobile/Main/animated_app_bar.dart';
import 'package:mg_music/ui/mobile/Main/animated_bottom_nav_bar.dart';
import 'package:mg_music/ui/mobile/Main/enums.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/ui/mobile/Main/landscape_warning_screen.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/ui/mobile/Home/Notifications/mobile_notifications_page.dart';
import 'package:mg_music/services/logic/notification_service.dart';
import 'package:mg_music/ui/mobile/Home/EditSong/edit_song_page.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showFullPlayer = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isFavoritesSelectionMode = false;
  bool _isScanning = true;
  Widget? _settingsSubPage;
  String? _settingsSubPageTitle;
  Widget? _editSongPage;
  String? _editSongPageTitle;

  List<LocalSong> _allSongs = [];
  List<LocalSong> _songs = [];
  SortType _currentSortType = SortType.patrona;
  String? _selectedArtist;
  List<String>? _cachedArtistList;

  final GlobalKey<MobileHomePageState> _homeKey = GlobalKey();
  final GlobalKey<MobileFavoritesPageState> _favoritesKey = GlobalKey();
  final GlobalKey<MobilePlaylistsPageState> _playlistsKey = GlobalKey();

  final SongFetcher _songFetcher = SongFetcher();

  late final List<Widget> _pages;
  StreamSubscription? _notiSubscription;

  @override
  void initState() {
    super.initState();
    FavoritesManager().init();
    PlaylistManager().init();
    AudioPlayerManager().init();
    _loadSortPreference();
    _searchController.addListener(_applyFiltersAndSort);

    SongFetcher.songsNotifier.addListener(_onGlobalSongsChanged);
    SongFetcher.isScanningNotifier.addListener(_onScanningStateChanged);

    _startAppScan();

    _pages = [
      MobilePlaylistsPage(
        key: _playlistsKey,
        onStateChanged: () => setState(() {}),
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      const MobileNotificationsPage(),
      MobileFavoritesPage(
        key: _favoritesKey,
        onSelectionModeChanged: (isSelectionMode) =>
            setState(() => _isFavoritesSelectionMode = isSelectionMode),
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      MobileSettingsPage(
        onNavigate: (page, title) {
          setState(() {
            _settingsSubPage = page;
            _settingsSubPageTitle = title;
          });
        },
      ),
    ];

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final notiService = context.read<NotificationService>();
        notiService.init().then((_) {
          notiService.checkForUpdates();
        });
        
        _notiSubscription = notiService.onActionTriggered.listen((action) {
          _handleNotificationAction(action);
        });
      }
    });
  }

  void _handleNotificationAction(Map<String, dynamic> action) {
    if (!mounted) return;
    
    final type = action['action_type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'open_favorites':
        _handleNavItemTap(3);
        break;
      case 'open_home':
        _handleNavItemTap(0);
        break;
      case 'open_settings':
        _handleNavItemTap(4);
        break;
      case 'open_playlists':
        _handleNavItemTap(1);
        break;
      case 'open_player':
        setState(() => _showFullPlayer = true);
        break;
      case 'open_updates':
        _selectedIndex = 4;
        _settingsSubPage = const WhatsNewPage();
        _settingsSubPageTitle = 'Novedades';
        setState(() {});
        break;
      case 'open_backup':
        _selectedIndex = 4;
        _settingsSubPage = const BackupSettingsPage();
        _settingsSubPageTitle = 'Gestión de Copias';
        setState(() {});
        break;
      case 'open_notifications':
        _handleNavItemTap(2);
        break;
    }
  }

  static const String _adoPlaylistName = 'Ado ★';
  static const String _prefHasAdoSongs = 'has_ado_songs';

  Future<void> _syncAdoPlaylist(List<LocalSong> allSongs) async {
    final prefs = await SharedPreferences.getInstance();
    final adoSongs = allSongs.where((s) => AdoHandler.isAdo(s)).toList();
    await prefs.setBool(_prefHasAdoSongs, adoSongs.isNotEmpty);

    if (!mounted) return;

    if (adoSongs.isEmpty) {
      final currentSort = prefs.getInt('sort_type') ?? 0;
      final currentStartup = prefs.getString('startup_mode') ?? 'ado';

      if (currentSort == 0) {
        await prefs.setInt('sort_type', 1);
        if (mounted) {
          setState(() {
            _currentSortType = SortType.alphabetical;
            _applyFiltersAndSort();
          });
        }
      }
      if (currentStartup == 'ado') {
        await AudioPlayerManager().setStartupMode(AudioPlayerManager.startupLast);
        if (mounted) setState(() {});
      }
      return;
    }

    final pm = PlaylistManager();
    final playlists = pm.playlistsNotifier.value;
    final isNew = !playlists.contains(_adoPlaylistName);

    if (isNew) {
      pm.createPlaylist(_adoPlaylistName);
      for (final song in adoSongs) {
        pm.addSongToPlaylist(_adoPlaylistName, song);
      }

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      GlobalModalService.show(
        title: '¡Playlist de Ado creada!',
        icon: Ionicons.musical_notes,
        primaryColor: Colors.blue.shade900,
        message: 'Encontramos ${adoSongs.length} canciones de Ado en tu biblioteca.\nCreamos la playlist «$_adoPlaylistName» automáticamente para ti.',
        actions: [
          ModalActionButton(
            label: 'Entendido',
            onPressed: () => Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop(),
            color: Colors.grey.shade800,
          ),
          ModalActionButton(
            label: 'Ver Playlist',
            onPressed: () {
              Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop();
              setState(() => _selectedIndex = 1);
            },
            color: Colors.blue.shade900,
          ),
        ],
      );
    } else {
      List<String> existingPaths = pm.getSongsNotifier(_adoPlaylistName).value.toList();
      int retries = 0;

      while (existingPaths.isEmpty && retries < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        existingPaths = pm.getSongsNotifier(_adoPlaylistName).value.toList();
        retries++;
      }

      final existingPathsSet = existingPaths.toSet();
      final newSongs = adoSongs.where((s) => !existingPathsSet.contains(s.path)).toList();

      if (newSongs.isNotEmpty) {
        for (final song in newSongs) {
          pm.addSongToPlaylist(_adoPlaylistName, song);
        }
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        CustomToastService.show(
          context,
          message: '${newSongs.length} canción${newSongs.length > 1 ? 'es' : ''} nueva${newSongs.length > 1 ? 's' : ''} de Ado agregada${newSongs.length > 1 ? 's' : ''} a «$_adoPlaylistName»',
          type: ToastType.ado,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  void dispose() {
    _notiSubscription?.cancel();
    SongFetcher.songsNotifier.removeListener(_onGlobalSongsChanged);
    SongFetcher.isScanningNotifier.removeListener(_onScanningStateChanged);
    _searchController.removeListener(_applyFiltersAndSort);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _startAppScan({bool forceRefresh = false}) async {
    await _songFetcher.startScan(
      forceRefresh: forceRefresh,
      onSongFound: (song) {},
      onScanComplete: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final allSongs = List<LocalSong>.from(SongFetcher.songsNotifier.value);
          setState(() {
            _isScanning = false;
            _allSongs = allSongs;
            _applyFiltersAndSort();
          });
          AudioPlayerManager().executeStartupBehavior(allSongs);
          _syncAdoPlaylist(allSongs);
        });
      },
    );
  }

  void _onGlobalSongsChanged() {
    if (!mounted) return;
    _cachedArtistList = null;
    final newSongs = List<LocalSong>.from(SongFetcher.songsNotifier.value);
    setState(() {
      _allSongs = newSongs;
      _applyFiltersAndSort();
    });
    AudioPlayerManager().updatePlaylist(_songs);
  }

  void _onScanningStateChanged() {
    if (!mounted) return;
    setState(() {
      _isScanning = SongFetcher.isScanningNotifier.value;
    });
  }

  Future<void> _handleNavItemTap(int index) async {
    if (_selectedIndex == index) return;

    final previousIndex = _selectedIndex;

    if (previousIndex == 0) {
      await _homeKey.currentState?.triggerExitAnimation();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchFocusNode.unfocus();
        _searchController.clear();
      }
      _selectedIndex = index;
      _settingsSubPage = null;
      _settingsSubPageTitle = null;
      _editSongPage = null;
      _editSongPageTitle = null;
      if (_showFullPlayer) _showFullPlayer = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (index == 3 || index == 1) {
      _favoritesKey.currentState?.refreshViewMode();
      _playlistsKey.currentState?.refreshViewMode();
    }

    if (index == 0 && previousIndex != 0) {
      _homeKey.currentState?.triggerEnterAnimation();
    }
  }

  void _handleSearchTap() {
    setState(() {
      if (_selectedIndex != 0) _selectedIndex = 0;
      _isSearching = !_isSearching;
      _showFullPlayer = false;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
      }
    });
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSortIndex = prefs.getInt('sort_type') ?? 0;
    if (mounted) {
      setState(() {
        _currentSortType = SortType.values.length > savedSortIndex
            ? SortType.values[savedSortIndex]
            : SortType.patrona;
        if (_allSongs.isNotEmpty) {
          _applyFiltersAndSort();
        }
      });
    }
  }

  void _handleSortTap() async {
    final selected = await GlobalModalService.showSelectionList<SortType>(
      title: "Ordenar por",
      icon: Ionicons.swap_vertical,
      items: SortType.values
          .where((st) => st != SortType.patrona || _allSongs.any((s) => AdoHandler.isAdo(s)))
          .toList(),
      labelBuilder: (item) {
        switch (item) {
          case SortType.patrona: return 'Experiencia temática';
          case SortType.alphabetical: return 'Alfabético (A-Z)';
          case SortType.inverse: return 'Inverso (Z-A)';
          case SortType.byDate: return 'Por Fecha (Recientes)';
          case SortType.byDateAsc: return 'Por Fecha (Antiguas)';
        }
      },
      selectedItem: _currentSortType,
    );

    if (selected != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sort_type', selected.index);
      setState(() {
        _currentSortType = selected;
        _applyFiltersAndSort();
      });
    }
  }

  void _handleArtistFilterTap() async {
    if (_cachedArtistList == null) {
      GlobalModalService.showLoading(message: "Cargando artistas...");
      await Future.delayed(const Duration(milliseconds: 100)); // allow dialog to show
      final Set<String> uniqueArtists = {};
      for (final s in _allSongs) {
        uniqueArtists.add(s.artist);
      }
      _cachedArtistList = uniqueArtists.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _cachedArtistList!.insert(0, "Todos");
      if (mounted) Navigator.pop(context); // close loading
    }

    final selected = await GlobalModalService.showSelectionList<String>(
      title: "Filtrar por Artista",
      icon: Ionicons.people,
      items: _cachedArtistList!,
      labelBuilder: (item) => item,
      selectedItem: _selectedArtist ?? "Todos",
    );

    if (selected != null) {
      setState(() {
        _selectedArtist = (selected == "Todos") ? null : selected;
        _applyFiltersAndSort();
      });
    }
  }

  void _applyFiltersAndSort() {
    List<LocalSong> tempSongs = List.from(_allSongs);

    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      tempSongs = tempSongs.where((song) {
        return song.title.toLowerCase().contains(searchQuery) ||
            song.artist.toLowerCase().contains(searchQuery);
      }).toList();
    }

    if (_selectedArtist != null) {
      tempSongs = tempSongs.where((s) => s.artist == _selectedArtist).toList();
    }

    switch (_currentSortType) {
      case SortType.alphabetical:
        tempSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortType.inverse:
        tempSongs.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortType.patrona:
        tempSongs.sort((a, b) {
          final aIsAdo = AdoHandler.isAdo(a);
          final bIsAdo = AdoHandler.isAdo(b);
          if (aIsAdo && !bIsAdo) return -1;
          if (!aIsAdo && bIsAdo) return 1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case SortType.byDate:
        tempSongs.sort((a, b) {
          try {
            final aDate = File(a.path).statSync().modified;
            final bDate = File(b.path).statSync().modified;
            return bDate.compareTo(aDate);
          } catch (_) {
            return 0;
          }
        });
        break;
      case SortType.byDateAsc:
        tempSongs.sort((a, b) {
          try {
            final aDate = File(a.path).statSync().modified;
            final bDate = File(b.path).statSync().modified;
            return aDate.compareTo(bDate);
          } catch (_) {
            return 0;
          }
        });
        break;
    }

    setState(() {
      _songs = tempSongs;
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return const LandscapeWarningScreen();
        }
        return WillPopScope(
          onWillPop: () async {
            if (_editSongPage != null) {
              setState(() {
                _editSongPage = null;
                _editSongPageTitle = null;
              });
              return false;
            }
            if (_settingsSubPage != null) {
              setState(() {
                _settingsSubPage = null;
                _settingsSubPageTitle = null;
              });
              return false;
            }
            if (_selectedIndex == 1 && (_playlistsKey.currentState?.isInsidePlaylist ?? false)) {
              _playlistsKey.currentState?.goBack();
              return false;
            }
            if (_showFullPlayer) {
              setState(() => _showFullPlayer = false);
              return false;
            }
            if (_selectedIndex != 0) {
              await _handleNavItemTap(0);
              return false;
            }
            await _homeKey.currentState?.triggerExitAnimation();
            return true;
          },
          child: Selector<ThemeService, AppThemeMode>(
            selector: (context, ts) => ts.mode,
            builder: (context, mode, _) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset: false,
                extendBody: true,
                body: Stack(
                  children: [
                    Column(
                      children: [
                        AnimatedAppBar(
                          selectedIndex: _selectedIndex,
                          isSearching: _isSearching,
                          showFullPlayer: _showFullPlayer,
                          isFavoritesSelectionMode: _isFavoritesSelectionMode,
                          searchController: _searchController,
                          searchFocusNode: _searchFocusNode,
                          favoritesKey: _favoritesKey,
                          playlistsKey: _playlistsKey,
                          onSearchTap: _handleSearchTap,
                          onSortTap: _handleSortTap,
                          onArtistFilterTap: _handleArtistFilterTap,
                          onToggleFullPlayer: () => setState(() => _showFullPlayer = !_showFullPlayer),
                          subPageTitle: _editSongPageTitle ?? _settingsSubPageTitle,
                          onBack: () => setState(() {
                            if (_editSongPage != null) {
                              _editSongPage = null;
                              _editSongPageTitle = null;
                            } else {
                              _settingsSubPage = null;
                              _settingsSubPageTitle = null;
                            }
                          }),
                        ),
                        Expanded(
                          child: PageTransitionSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                              return FadeThroughTransition(
                                animation: primaryAnimation,
                                secondaryAnimation: secondaryAnimation,
                                fillColor: Colors.transparent,
                                child: child,
                              );
                            },
                            child: _buildCurrentPage(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                bottomNavigationBar: AnimatedBottomNavBar(
                  selectedIndex: _selectedIndex,
                  showFullPlayer: _showFullPlayer,
                  onNavItemTap: _handleNavItemTap,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCurrentPage() {
    if (_showFullPlayer) {
      return const MobileFullPlayer(key: ValueKey('full_player'));
    }

    if (_selectedIndex == 0 && _editSongPage != null) {
      return KeyedSubtree(
        key: const ValueKey('edit_song'),
        child: _editSongPage!,
      );
    }

    if (_selectedIndex == 4 && _settingsSubPage != null) {
      return KeyedSubtree(
        key: const ValueKey('settings_sub'),
        child: _settingsSubPage!,
      );
    }

    if (_selectedIndex == 0) {
      return MobileHomePage(
        key: _homeKey,
        songs: _songs,
        isScanning: _isScanning,
        onSongsLoaded: (_) {},
        onScanComplete: (_) {},
        onForceRefresh: () => _startAppScan(forceRefresh: true),
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
        onSearchTriggered: _handleSearchTap,
        onEditSong: (song) {
          setState(() {
            _editSongPage = EditSongPage(song: song);
            _editSongPageTitle = 'Editar: ${song.title}';
          });
        },
        onSongDeleted: (song) {
          setState(() {
            _cachedArtistList = null;
            _allSongs.removeWhere((s) => s.id == song.id);
            _applyFiltersAndSort();
          });
        },
      );
    }

    return KeyedSubtree(
      key: ValueKey('page_$_selectedIndex'),
      child: _pages[_selectedIndex - 1],
    );
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla principal Mobile

import 'dart:async';
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
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/ui/mobile/Main/animated_app_bar.dart';
import 'package:mg_music/ui/mobile/Main/animated_bottom_nav_bar.dart';
import 'package:mg_music/ui/mobile/Main/enums.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/services/models/version_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mg_music/ui/mobile/Main/landscape_warning_screen.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

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
  bool _isScanning = true; // Empieza escaneando

  List<LocalSong> _allSongs = [];
  List<LocalSong> _songs = [];
  SortType _currentSortType = SortType.patrona;
  String? _selectedArtist;

  final GlobalKey<MobileHomePageState> _homeKey = GlobalKey();
  final GlobalKey<MobileFavoritesPageState> _favoritesKey = GlobalKey();
  final GlobalKey<MobilePlaylistsPageState> _playlistsKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  /// Inicializa servicios, listeners y páginas
  void initState() {
    super.initState();
    FavoritesManager().init();
    PlaylistManager().init();
    AudioPlayerManager().init();
    _loadSortPreference();
    _searchController.addListener(_applyFiltersAndSort);

    // MobileHomePage is now built dynamically in _buildCurrentPage to pass the song list.
    // The _pages list now only contains the other main sections.
    _pages = [
      // Index 0 is MobileHomePage
      MobilePlaylistsPage(
        key: _playlistsKey,
        onStateChanged: () => setState(() {}),
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      MobileFavoritesPage(
        key: _favoritesKey,
        onSelectionModeChanged: (isSelectionMode) =>
            setState(() => _isFavoritesSelectionMode = isSelectionMode),
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      const MobileSettingsPage(),
    ];

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkForUpdates();
    });
  }

  /// Claves y preferencias de Ado
  static const String _adoPlaylistName = 'Ado ★';
  static const String _prefHasAdoSongs = 'has_ado_songs';

  /// Sincroniza la playlist de Ado y ajusta sort/startup según disponibilidad
  Future<void> _syncAdoPlaylist(List<LocalSong> allSongs) async {
    final prefs = await SharedPreferences.getInstance();

    final adoSongs = allSongs.where((s) => AdoHandler.isAdo(s)).toList();

    await prefs.setBool(_prefHasAdoSongs, adoSongs.isNotEmpty);

    if (!mounted) return;

    if (adoSongs.isEmpty) {
      final currentSort = prefs.getInt('sort_type') ?? 0;
      final currentStartup = prefs.getString('startup_mode') ?? 'ado';

      if (currentSort == 0 /* patrona */ ) {
        await prefs.setInt('sort_type', 1 /* alphabetical */);
        if (mounted) {
          setState(() {
            _currentSortType = SortType.alphabetical;
            _applyFiltersAndSort();
          });
        }
      }
      if (currentStartup == 'ado') {
        await AudioPlayerManager().setStartupMode(
          AudioPlayerManager.startupLast,
        );
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
        message:
            'Encontramos ${adoSongs.length} canciones de Ado en tu biblioteca.\n'
            'Creamos la playlist «$_adoPlaylistName» automáticamente para ti.',
        actions: [
          ModalActionButton(
            label: 'Entendido',
            onPressed: () => Navigator.of(
              GlobalModalService.navigatorKey.currentContext!,
            ).pop(),
            color: Colors.grey.shade800,
          ),
          ModalActionButton(
            label: 'Ver Playlist',
            onPressed: () {
              Navigator.of(
                GlobalModalService.navigatorKey.currentContext!,
              ).pop();
              setState(() => _selectedIndex = 1);
            },
            color: Colors.blue.shade900,
          ),
        ],
      );
    } else {
      List<String> existingPaths = pm
          .getSongsNotifier(_adoPlaylistName)
          .value
          .toList();
      int retries = 0;

      while (existingPaths.isEmpty && retries < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        existingPaths = pm.getSongsNotifier(_adoPlaylistName).value.toList();
        retries++;
      }

      final existingPathsSet = existingPaths.toSet();
      final newSongs = adoSongs
          .where((s) => !existingPathsSet.contains(s.path))
          .toList();

      if (newSongs.isNotEmpty) {
        for (final song in newSongs) {
          pm.addSongToPlaylist(_adoPlaylistName, song);
        }
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        CustomToastService.show(
          context,
          message:
              '${newSongs.length} canción${newSongs.length > 1 ? 'es' : ''} nueva${newSongs.length > 1 ? 's' : ''} de Ado agregada${newSongs.length > 1 ? 's' : ''} a «$_adoPlaylistName»',
          type: ToastType.ado,
          duration: const Duration(seconds: 5),
        );
      }
      // Si no hay nuevas no se muestra nada
    }
  }

  @override
  /// Libera controladores de búsqueda
  void dispose() {
    _searchController.removeListener(_applyFiltersAndSort);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index) return;

    if (_selectedIndex == 0) {
      await _homeKey.currentState?.triggerExitAnimation();
      await Future.delayed(const Duration(milliseconds: 100)); // Pequeña pausa
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo['hasUpdate'] && mounted) {
      final version = updateInfo['data'] as VersionModel;

      // Determinar colores e iconos según importancia
      Color color;
      IconData icon;
      String importanceLabel;

      switch (version.importance) {
        case 'critical':
          color = Colors.red;
          icon = Ionicons.alert_circle;
          importanceLabel = 'Crítica';
          break;
        case 'high':
          color = Colors.orange;
          icon = Ionicons.warning;
          importanceLabel = 'Alta';
          break;
        case 'medium':
          color = Colors.amber;
          icon = Ionicons.information_circle;
          importanceLabel = 'Media';
          break;
        default:
          color = Colors.blue;
          icon = Ionicons.refresh_circle;
          importanceLabel = 'Normal';
      }

      GlobalModalService.show(
        title: "Nueva Versión Disponible",
        icon: icon,
        primaryColor: color,
        dismissible: !version.forceUpdate,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  "v${version.version} • $importanceLabel",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              version.title,
              style: TextStyle(
                color: AppColors.textPrimary(context.read<ThemeService>().mode),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            if (version.changelog.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  version.changelog,
                  style: TextStyle(
                    color: AppColors.textSecondary(
                      context.read<ThemeService>().mode,
                    ),
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!version.forceUpdate)
            ModalActionButton(
              label: "Ahora no",
              onPressed: () => Navigator.of(
                GlobalModalService.navigatorKey.currentContext!,
              ).pop(),
              color: Colors.grey,
            ),
          ModalActionButton(
            label: "Actualizar",
            onPressed: () {
              Navigator.of(
                GlobalModalService.navigatorKey.currentContext!,
              ).pop();
              launchUrl(
                Uri.parse(version.websiteUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            color: color,
          ),
        ],
      );
    }
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
            if (_selectedIndex == 1 &&
                (_playlistsKey.currentState?.isInsidePlaylist ?? false)) {
              _playlistsKey.currentState?.goBack();
              return false;
            }
            if (_showFullPlayer) {
              setState(() => _showFullPlayer = false);
              return false;
            }
            if (_selectedIndex != 0) {
              await _onItemTapped(0);
              return false;
            }
            await _homeKey.currentState?.triggerExitAnimation();
            return true;
          },
          child: Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return Scaffold(
                backgroundColor: Colors
                    .transparent, // El fondo lo maneja AnimatedThemeSwitcher en root
                resizeToAvoidBottomInset: false,
                extendBody: true,
                body: Stack(
                  children: [
                    Column(
                      children: [
                        // SOLUCIÓN: Se restaura el AppBar aquí
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
                          onToggleFullPlayer: () => setState(
                            () => _showFullPlayer = !_showFullPlayer,
                          ),
                        ),
                        Expanded(
                          child: PageTransitionSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder:
                                (child, primaryAnimation, secondaryAnimation) {
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
                  isSearching: _isSearching,
                  onNavItemTap: _handleNavItemTap,
                  onSearchTap: _handleSearchTap,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _handleNavItemTap(int index) async {
    final previousIndex = _selectedIndex;
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchFocusNode.unfocus();
        _searchController.clear();
      }
      if (_selectedIndex != index) _selectedIndex = index;
      if (_showFullPlayer) _showFullPlayer = false;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (index == 2 || index == 1) {
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

  // --- MODALES GLOBALES Y LÓGICA DE FILTRADO/ORDENAMIENTO ---

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

  /// Abre el selector de ordenamiento
  void _handleSortTap() async {
    final selected = await GlobalModalService.showSelectionList<SortType>(
      title: "Ordenar por",
      icon: Ionicons.swap_vertical,
      items: SortType.values
          .where(
            (st) =>
                st != SortType.patrona ||
                _allSongs.any((s) => AdoHandler.isAdo(s)),
          )
          .toList(),
      labelBuilder: (item) {
        switch (item) {
          case SortType.patrona:
            return 'Ado (Por defecto)';
          case SortType.alphabetical:
            return 'Alfabético (A-Z)';
          case SortType.inverse:
            return 'Inverso (Z-A)';
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

  /// Abre el selector de artistas
  void _handleArtistFilterTap() async {
    final Set<String> uniqueArtists = _allSongs.map((s) => s.artist).toSet();
    final List<String> artistList = uniqueArtists.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    artistList.insert(0, "Todos");

    final selected = await GlobalModalService.showSelectionList<String>(
      title: "Filtrar por Artista",
      icon: Ionicons.people,
      items: artistList,
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

  /// Aplica búsqueda, filtro de artista y ordenamiento sobre la lista maestra
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
        tempSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortType.inverse:
        tempSongs.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
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
    }

    setState(() {
      _songs = tempSongs;
    });

    // No se actualiza la lista interna del reproductor aquí
  }

  /// Construye la página actual o el full player
  Widget _buildCurrentPage() {
    if (_showFullPlayer) {
      return const MobileFullPlayer(key: ValueKey('full_player'));
    }

    if (_selectedIndex == 0) {
      return MobileHomePage(
        key: _homeKey,
        songs: _songs,
        isScanning: _isScanning, // Pasar estado
        onSongsLoaded: (allSongs) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _allSongs = allSongs;
                _applyFiltersAndSort();
              });
              AudioPlayerManager().updatePlaylist(_songs);
            }
          });
        },
        onScanComplete: (allSongs) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isScanning = false;
                _allSongs = allSongs;
                _applyFiltersAndSort();
              });
              AudioPlayerManager().executeStartupBehavior(allSongs);
              _syncAdoPlaylist(allSongs);
            }
          });
        },
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      );
    }

    return KeyedSubtree(
      key: ValueKey('page_$_selectedIndex'),
      child: _pages[_selectedIndex - 1], // Ajusta el índice
    );
  }
}

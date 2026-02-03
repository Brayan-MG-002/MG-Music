// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla principal Mobile

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Mobile/Home/mobile_favorites_page.dart';
import 'package:mg_music/Mobile/Home/mobile_home_page.dart';
import 'package:mg_music/Mobile/Home/mobile_playlists_page.dart';
import 'package:mg_music/Mobile/Home/Player/mobile_full_player.dart';
import 'package:mg_music/Mobile/Home/Player/mobile_mini_player.dart';
import 'package:mg_music/Mobile/Home/mobile_settings_page.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/screens/update_dialog.dart';

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

  // Key para controlar el Home Page desde el Main Screen
  final GlobalKey<MobileHomePageState> _homeKey = GlobalKey();
  // Key para controlar Favoritos
  final GlobalKey<MobileFavoritesPageState> _favoritesKey = GlobalKey();
  // Key para controlar Playlists
  final GlobalKey<MobilePlaylistsPageState> _playlistsKey = GlobalKey();

  // Caché para la lista de artistas para optimizar el rendimiento
  List<String>? _cachedArtistList;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    FavoritesManager().init(); // Inicializar Favoritos
    PlaylistManager().init(); // Inicializar Playlists
    AudioPlayerManager().init(); // Inicializar AudioPlayer
    _searchController.addListener(_onSearchChanged);
    _pages = [
      MobileHomePage(
        key: _homeKey,
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      MobilePlaylistsPage(
        key: _playlistsKey,
        onStateChanged: () {
          setState(() {});
        },
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      MobileFavoritesPage(
        key: _favoritesKey,
        onSelectionModeChanged: (isSelectionMode) {
          setState(() {
            _isFavoritesSelectionMode = isSelectionMode;
          });
        },
        onOpenPlayer: () => setState(() => _showFullPlayer = true),
      ),
      const MobileSettingsPage(),
    ];

    // Verificar actualizaciones después de inicializar
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isSearching) {
      // Llama a la función de búsqueda en MobileHomePage
      _homeKey.currentState?.searchSongs(_searchController.text);
    }
  }

  /// Verifica si hay actualizaciones disponibles
  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    final updateInfo = await UpdateService.checkForUpdate();

    if (updateInfo['hasUpdate'] && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            UpdateDialog(versionData: updateInfo['data'], isTv: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Manejar botón atrás para Playlists
        if (_selectedIndex == 1 &&
            (_playlistsKey.currentState?.isInsidePlaylist ?? false)) {
          _playlistsKey.currentState?.goBack();
          return false;
        }
        if (_showFullPlayer) {
          setState(() => _showFullPlayer = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        extendBody: false, // El contenido respeta el espacio del NavBar
        body: Stack(
          children: [
            Column(
              children: [
                // --- App Bar Personalizada ---
                CustomPaint(
                  painter: _TopBarPainter(
                    color: Colors.grey.shade900,
                    borderColor: Colors.blue.shade900,
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
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                      child: _isSearching
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

                // --- Contenido de la Página ---
                Expanded(
                  child: _showFullPlayer
                      ? const MobileFullPlayer()
                      : _pages[_selectedIndex],
                ),
              ],
            ),
            // --- Indicador de temporizador (superpuesto) ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSleepTimerIndicator(),
            ),
          ],
        ),

        // --- Barra de Navegación con Curva ---
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: CustomPaint(
            painter: _NavBarPainter(
              color: Colors.grey.shade900,
              borderColor: Colors.blue.shade900,
            ),
            child: Container(
              height: 70 + MediaQuery.of(context).padding.bottom,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildNavItem(
                      0,
                      Ionicons.musical_notes_outline,
                      Ionicons.musical_notes,
                      'Pistas',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      1,
                      Ionicons.list_outline,
                      Ionicons.list,
                      'Playlists',
                    ),
                  ),
                  Expanded(child: _buildSearchNavItem()),
                  Expanded(
                    child: _buildNavItem(
                      2,
                      Ionicons.heart_outline,
                      Ionicons.heart,
                      'Favoritos',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      3,
                      Ionicons.settings_outline,
                      Ionicons.settings,
                      'Ajustes',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData iconOff,
    IconData iconOn,
    String label,
  ) {
    // Un item no está seleccionado si estamos en modo búsqueda
    final bool isActuallySelected = _selectedIndex == index && !_isSearching;

    return GestureDetector(
      onTap: () {
        setState(() {
          // Si tocamos un item de la nav bar, salimos del modo búsqueda
          if (_isSearching) {
            _isSearching = false;
            _searchFocusNode.unfocus();
            _searchController
                .clear(); // Esto dispara el listener y resetea la lista
          }

          _selectedIndex = index;

          // Si cambiamos a Favoritos (índice 2), refrescamos el modo de vista
          if (index == 2 || index == 1) {
            _favoritesKey.currentState?.refreshViewMode();
            _playlistsKey.currentState?.refreshViewMode();
          }

          // No mostrar el reproductor completo al cambiar de pestaña
          if (_showFullPlayer) {
            _showFullPlayer = false;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActuallySelected ? iconOn : iconOff,
            color: isActuallySelected ? Colors.blue.shade900 : Colors.grey,
            size: 24,
          ),
          if (isActuallySelected)
            Text(
              label,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchNavItem() {
    // El botón de búsqueda se considera "seleccionado" si el modo búsqueda está activo
    final isSelected = _isSearching;
    return GestureDetector(
      onTap: _handleSearchTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? Ionicons.search : Ionicons.search_outline,
            color: isSelected ? Colors.blue.shade900 : Colors.grey,
            size: 24,
          ),
          if (isSelected)
            Text(
              'Buscar',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  void _handleSearchTap() {
    setState(() {
      // Si no estamos en la pestaña de Pistas, nos movemos a ella
      if (_selectedIndex != 0) {
        _selectedIndex = 0;
      }

      _isSearching = !_isSearching;
      _showFullPlayer = false; // Cerramos el reproductor si estaba abierto

      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear(); // Limpia y resetea la lista
      }
    });
  }

  Widget _buildDefaultAppBarContent() {
    return Row(
      children: [
        // Botón Atrás (Solo si estamos DENTRO de una Playlist)
        if (_selectedIndex == 1 &&
            (_playlistsKey.currentState?.isInsidePlaylist ?? false))
          _buildTopBarIcon(Ionicons.arrow_back, () {
            _playlistsKey.currentState?.goBack();
          }),

        // --- IZQUIERDA ---
        // Pistas (0): Ordenar
        if (_selectedIndex == 0 && !_showFullPlayer)
          _buildTopBarIcon(Ionicons.swap_vertical, () {
            _showSortMenu(context);
          }),

        // Favoritos (2): Reproducir Todo (Solo si no estamos seleccionando)
        if (_selectedIndex == 2 &&
            !_showFullPlayer &&
            !_isFavoritesSelectionMode)
          _buildTopBarIcon(Ionicons.play_circle, () {
            _favoritesKey.currentState?.playFavorites();
          }),

        // Playlists (1): Reproducir Todo (Solo si estamos DENTRO de una playlist)
        if (_selectedIndex == 1 &&
            !_showFullPlayer &&
            (_playlistsKey.currentState?.isInsidePlaylist ?? false))
          _buildTopBarIcon(Ionicons.play_circle, () {
            _playlistsKey.currentState?.playCurrentPlaylist();
          }),

        // --- Mini Reproductor Integrado (Centro) ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: MobileMiniPlayer(
              showVisualizer: _showFullPlayer,
              onTap: () {
                setState(() {
                  _showFullPlayer = !_showFullPlayer;
                });
              },
            ),
          ),
        ),

        // --- DERECHA ---
        // Pistas (0): Artistas
        if (_selectedIndex == 0 && !_showFullPlayer)
          _buildTopBarIcon(Ionicons.people, () {
            _showArtistMenu(context);
          }),

        // Favoritos (2): Eliminar / Confirmar Eliminación
        if (_selectedIndex == 2 && !_showFullPlayer)
          _buildTopBarIcon(
            _isFavoritesSelectionMode ? Ionicons.trash : Ionicons.trash_outline,
            () {
              _favoritesKey.currentState?.handleDeleteAction();
            },
            color: _isFavoritesSelectionMode ? Colors.red : Colors.white,
          ),

        // Playlists (1): Eliminar (Solo si estamos DENTRO de una playlist)
        if (_selectedIndex == 1 &&
            !_showFullPlayer &&
            (_playlistsKey.currentState?.isInsidePlaylist ?? false))
          _buildTopBarIcon(
            (_playlistsKey.currentState?.isSelectionMode ?? false)
                ? Ionicons.trash
                : Ionicons.trash_outline,
            () {
              _playlistsKey.currentState?.handleDeleteAction();
            },
            color: (_playlistsKey.currentState?.isSelectionMode ?? false)
                ? Colors.red
                : Colors.white,
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final playerManager = AudioPlayerManager();

    return Row(
      children: [
        // Carátula giratoria
        ValueListenableBuilder<LocalSong?>(
          valueListenable: playerManager.currentSongNotifier,
          builder: (context, song, _) {
            if (song == null) return const SizedBox(width: 40);
            return ValueListenableBuilder<bool>(
              valueListenable: playerManager.isPlayingNotifier,
              builder: (context, isPlaying, _) {
                return _SearchRotatingArtwork(
                  artwork: song.artwork,
                  isPlaying: isPlaying,
                  isAdo: song.artist.toLowerCase().contains('ado'),
                );
              },
            );
          },
        ),
        const SizedBox(width: 8),
        // Campo de búsqueda
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.blue.shade300,
            decoration: InputDecoration(
              hintText: 'Buscar canciones, artistas...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Ionicons.close_circle,
                        color: Colors.grey,
                      ),
                      onPressed: () => _searchController.clear(),
                      splashRadius: 20,
                    )
                  : null,
            ),
          ),
        ),
        // Botón para cerrar la búsqueda
        IconButton(
          icon: const Icon(Ionicons.close, color: Colors.white),
          onPressed: _handleSearchTap, // Reutilizamos para cerrar
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildTopBarIcon(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onTap,
      splashRadius: 20,
    );
  }

  // --- Menús Personalizados ---

  void _showSortMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Ordenar por',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuOption(Ionicons.star, 'La Patrona (Ado primero)', () {
              _homeKey.currentState?.sortLaPatrona();
              Navigator.pop(context);
            }),
            _buildMenuOption(Ionicons.text, 'Alfabético (A-Z)', () {
              _homeKey.currentState?.sortAlphabetical(true);
              Navigator.pop(context);
            }),
            _buildMenuOption(Ionicons.swap_vertical, 'Inverso (Z-A)', () {
              _homeKey.currentState?.sortAlphabetical(false);
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showArtistMenu(BuildContext context) {
    // Usar la lista de artistas en caché si está disponible para evitar recálculos.
    if (_cachedArtistList == null) {
      // Obtener canciones del estado del Home
      final allSongs = _homeKey.currentState?.allSongs ?? [];

      // Extraer y limpiar artistas (separando por comas)
      final artists = allSongs
          .expand((s) => s.artist.split(',').map((a) => a.trim()))
          .where((a) => a.isNotEmpty)
          .toSet()
          .toList();
      artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _cachedArtistList = artists;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Seleccionar Artista',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildMenuOption(Ionicons.people, 'Todos los artistas', () {
                _homeKey.currentState?.filterByArtist(null);
                Navigator.pop(context);
              }),
              ...(_cachedArtistList ?? []).map(
                (artist) => _buildMenuOption(Ionicons.person, artist, () {
                  _homeKey.currentState?.filterByArtist(artist);
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepTimerIndicator() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: AudioPlayerManager().sleepEndTimeNotifier,
      builder: (context, endTime, _) {
        if (endTime == null) return const SizedBox.shrink();

        return StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final remaining = endTime.difference(DateTime.now());
            if (remaining.isNegative) {
              return const SizedBox.shrink();
            }

            final timeStr =
                '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

            // El Center alinea el indicador horizontalmente. El Positioned en el body
            // lo coloca abajo, y el margin en el Container le da espacio sobre el NavBar.
            return Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.shade900.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Ionicons.moon, size: 14, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Apagado en $timeStr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => AudioPlayerManager().setSleepTimer(0),
                      child: Icon(
                        Ionicons.close_circle,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade900),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.blue.shade900.withOpacity(0.2),
    );
  }
}

/// Widget para la carátula giratoria en la barra de búsqueda
class _SearchRotatingArtwork extends StatefulWidget {
  final Uint8List? artwork;
  final bool isPlaying;
  final bool isAdo;

  const _SearchRotatingArtwork({
    required this.artwork,
    required this.isPlaying,
    required this.isAdo,
  });

  @override
  State<_SearchRotatingArtwork> createState() => _SearchRotatingArtworkState();
}

class _SearchRotatingArtworkState extends State<_SearchRotatingArtwork>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant _SearchRotatingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying ||
        widget.isAdo != oldWidget.isAdo) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
    if (widget.isAdo) {
      _glowController.repeat(reverse: true);
    } else {
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowColor = widget.isAdo
            ? Colors.blue.shade900.withOpacity(
                0.3 + (_glowController.value * 0.4),
              )
            : Colors.transparent;

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: glowColor, blurRadius: 8, spreadRadius: 2),
            ],
          ),
          child: RotationTransition(
            turns: _rotationController,
            child: ClipOval(
              child: widget.artwork != null
                  ? Image.memory(
                      widget.artwork!,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                      cacheHeight: 120,
                    )
                  : Image.asset('assets/MG-I-T.png'),
            ),
          ),
        );
      },
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _NavBarPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double borderRadius = 30.0;

    path.moveTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);

    // Línea recta superior (sin notch)
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);

    // Extender hacia abajo para asegurar que cubra el fondo (safe area)
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Dibujar fondo
    canvas.drawPath(path, paint);

    // Dibujar borde (solo la parte superior)
    final borderPath = Path();
    borderPath.moveTo(0, borderRadius);
    borderPath.quadraticBezierTo(0, 0, borderRadius, 0);
    borderPath.lineTo(size.width - borderRadius, 0);
    borderPath.quadraticBezierTo(size.width, 0, size.width, borderRadius);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopBarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TopBarPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const double radius = 20.0;
    final path = Path();

    // Dibujar forma con esquinas inferiores redondeadas
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();

    canvas.drawPath(path, paint);

    // Dibujar solo el borde inferior curvo
    final borderPath = Path();
    borderPath.moveTo(0, size.height - radius);
    borderPath.quadraticBezierTo(0, size.height, radius, size.height);
    borderPath.lineTo(size.width - radius, size.height);
    borderPath.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - radius,
    );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

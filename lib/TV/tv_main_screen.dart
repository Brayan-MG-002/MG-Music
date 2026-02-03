// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla principal TV con navegación de pestañas

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/TV/Home/Player/tv_player_widget.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/Home/tv_home_page.dart';
import 'package:mg_music/TV/Home/Player/tv_full_player.dart';
import 'package:mg_music/TV/Home/tv_favorites_page.dart';
import 'package:mg_music/TV/Home/tv_playlists_page.dart';
import 'package:mg_music/TV/Home/tv_settings_page.dart';
import 'package:mg_music/Logic/tv_exit_dialog.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/screens/update_dialog.dart';

/// Pantalla principal de TV con navegación lateral
class TvMainScreen extends StatefulWidget {
  const TvMainScreen({super.key});

  @override
  State<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends State<TvMainScreen> {
  int _selectedIndex = 0;
  bool _showFullPlayer = false;

  @override
  void initState() {
    super.initState();
    FavoritesManager().init();
    PlaylistManager().init();

    // Verificar actualizaciones después de inicializar
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showFullPlayer) {
          setState(() => _showFullPlayer = false);
          return false;
        }

        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => const TvExitDialog(),
        );

        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Row(
          children: [
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.5),
                border: Border(
                  right: BorderSide(color: Colors.blue.shade900, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildSidebarHeader(),
                  _buildMenuItem(0, Ionicons.musical_notes_outline, 'Pistas'),
                  const SizedBox(height: 10),
                  _buildMenuItem(1, Ionicons.list_outline, 'Playlists'),
                  const SizedBox(height: 10),
                  _buildMenuItem(2, Ionicons.heart_outline, 'Favoritos'),
                  const SizedBox(height: 10),
                  _buildMenuItem(3, Ionicons.settings_outline, 'Ajustes'),
                  const Spacer(),
                  _buildSleepTimerStatus(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: _showFullPlayer
                  ? const TvFullPlayer()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey<int>(_selectedIndex),
                        child: _buildContentPage(_selectedIndex),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
            UpdateDialog(versionData: updateInfo['data'], isTv: true),
      );
    }
  }

  /// Construye el encabezado de la barra lateral
  Widget _buildSidebarHeader() {
    return _buildLogoOrPlayer();
  }

  /// Muestra logo o mini reproductor según la pestaña
  Widget _buildLogoOrPlayer() {
    if (_selectedIndex == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0),
        child: Image.asset('assets/MG-I-T.png', width: 60),
      );
    }

    final manager = AudioPlayerManager();
    return ValueListenableBuilder<String>(
      valueListenable: manager.startupModeNotifier,
      builder: (context, startupMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: manager.isRestoringNotifier,
          builder: (context, isRestoring, _) {
            if (isRestoring) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                ),
              );
            }
            return ValueListenableBuilder<LocalSong?>(
              valueListenable: manager.currentSongNotifier,
              builder: (context, song, _) {
                if (song == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Image.asset('assets/MG-I-T.png', width: 60),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: TvFocusableItem(
                    onTap: manager.togglePlayPause,
                    onLongPress: manager.next,
                    borderRadius: 50,
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: _ArtworkColorProgressIndicator(
                              artwork: song.artwork,
                              manager: manager,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: RotatingArtwork(
                              artwork: song.artwork,
                              isPlayingNotifier: manager.isPlayingNotifier,
                              size: 60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Construye la página de contenido según el índice
  Widget _buildContentPage(int index) {
    switch (index) {
      case 0:
        return TvHomePage(
          onOpenPlayer: () => setState(() => _showFullPlayer = true),
        );
      case 1:
        return TvPlaylistsPage(
          onOpenPlayer: () => setState(() => _showFullPlayer = true),
        );
      case 2:
        return TvFavoritesPage(
          onOpenPlayer: () => setState(() => _showFullPlayer = true),
        );
      case 3:
        return const TvSettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Construye un elemento de menú con estado de selección
  Widget _buildMenuItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return TvFocusableItem(
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _showFullPlayer = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 30,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  /// Muestra el estado del temporizador de reposo
  Widget _buildSleepTimerStatus() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: AudioPlayerManager().sleepEndTimeNotifier,
      builder: (context, endTime, _) {
        if (endTime == null) return const SizedBox.shrink();

        return StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final now = DateTime.now();
            final remaining = endTime.difference(now);

            if (remaining.isNegative) {
              return const SizedBox.shrink();
            }

            final minutes = remaining.inMinutes;
            final seconds = remaining.inSeconds % 60;
            final timeString =
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

            return Column(
              children: [
                const Icon(
                  Ionicons.timer_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(height: 5),
                Text(
                  timeString,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Indicador de progreso con color dominante de carátula
class _ArtworkColorProgressIndicator extends StatefulWidget {
  final Uint8List? artwork;
  final AudioPlayerManager manager;

  const _ArtworkColorProgressIndicator({
    required this.artwork,
    required this.manager,
  });

  @override
  State<_ArtworkColorProgressIndicator> createState() =>
      _ArtworkColorProgressIndicatorState();
}

class _ArtworkColorProgressIndicatorState
    extends State<_ArtworkColorProgressIndicator> {
  Color _progressColor = Colors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _updateColor();
  }

  @override
  void didUpdateWidget(covariant _ArtworkColorProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.artwork != oldWidget.artwork) {
      _updateColor();
    }
  }

  /// Actualiza el color basado en la carátula
  Future<void> _updateColor() async {
    if (widget.artwork == null) {
      if (mounted) setState(() => _progressColor = Colors.cyanAccent);
      return;
    }
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(MemoryImage(widget.artwork!), width: 50, height: 50),
        maximumColorCount: 10,
      );
      if (mounted) {
        setState(
          () => _progressColor =
              generator.dominantColor?.color ?? Colors.cyanAccent,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _progressColor = Colors.cyanAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.manager.positionNotifier,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.manager.durationNotifier,
          builder: (context, duration, _) {
            double progress = 0.0;
            if (duration.inMilliseconds > 0) {
              progress = position.inMilliseconds / duration.inMilliseconds;
            }
            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 500),
              tween: ColorTween(begin: Colors.cyanAccent, end: _progressColor),
              builder: (context, color, _) {
                return CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? Colors.cyanAccent,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla principal para TV que gestiona la navegación lateral, el reproductor completo y el contenido dinámico.

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/ui/tv/Home/Home/tv_home_page.dart';
import 'package:mg_music/ui/tv/Home/Player/tv_full_player.dart';
import 'package:mg_music/ui/tv/Home/Favorites/tv_favorites_page.dart';
import 'package:mg_music/ui/tv/Home/Playlist/tv_playlists_page.dart';
import 'package:mg_music/ui/tv/Home/Settings/tv_settings_page.dart';
import 'package:mg_music/ui/tv/tv_exit_dialog.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/ui/tv/Main/tv_sidebar.dart';

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
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                TvSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _showFullPlayer = false;
                    });
                  },
                ),
                Expanded(
                  child: _showFullPlayer
                      ? const TvFullPlayer()
                      : PageTransitionSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder:
                              (child, primaryAnimation, secondaryAnimation) {
                                return SharedAxisTransition(
                                  animation: primaryAnimation,
                                  secondaryAnimation: secondaryAnimation,
                                  transitionType:
                                      SharedAxisTransitionType.horizontal,
                                  fillColor: Colors.transparent,
                                  child: child,
                                );
                              },
                          child: Container(
                            key: ValueKey<int>(_selectedIndex),
                            child: _buildContentPage(_selectedIndex),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


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
}

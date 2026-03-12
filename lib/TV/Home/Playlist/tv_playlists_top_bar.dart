// Barra superior de Playlists en TV
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/playlist_action_service.dart';

class TvPlaylistsTopBar extends StatelessWidget {
  final VoidCallback onCreate;
  const TvPlaylistsTopBar({super.key, required this.onCreate});

  @override
  /// Construye la barra con título y acción de crear playlist
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.sidebarGradient(mode),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.themeBorder(mode), width: 2),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlueMid.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Tus Playlists',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TvFocusableItem(
            onTap: () {
              PlaylistActionService.showCreatePlaylistDialog(context);
              onCreate();
            },
            borderRadius: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.themeBorder(mode)),
              ),
              child: Row(
                children: [
                  const Icon(Ionicons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Crear Playlist',
                    style: TextStyle(
                      color: AppColors.textPrimary(mode),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

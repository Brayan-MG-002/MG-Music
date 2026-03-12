// m:\MG Proyect\MG Music\MG Music\lib\Mobile\Home\Player\components\mobile_player_actions.dart

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/services/playlist_action_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/services/custom_toast_service.dart';
import 'mobile_heart_icon.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';

class MobilePlayerActions extends StatelessWidget {
  final AudioPlayerManager manager;
  final LocalSong song;

  const MobilePlayerActions({
    super.key,
    required this.manager,
    required this.song,
  });

  @override
  /// Construye las acciones del reproductor: shuffle, favorito, agregar y repetir
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Aleatorio
        ValueListenableBuilder<bool>(
          valueListenable: manager.isShuffleModeNotifier,
          builder: (context, isShuffle, _) {
            return IconButton(
              icon: Icon(
                Ionicons.shuffle,
                color: isShuffle
                    ? AppColors.primaryBlueMid
                    : AppColors.textSecondary(mode),
                size: 26,
              ),
              onPressed: manager.toggleShuffleMode,
            );
          },
        ),
        // Favoritos (Animado)
        ValueListenableBuilder<List<String>>(
          valueListenable: FavoritesManager().favoritePathsNotifier,
          builder: (context, favoritePaths, _) {
            final isFavorite = favoritePaths.contains(song.path);
            final isAdo = AdoHandler.isAdo(song);
            return MobileHeartIcon(
              isFavorite: isFavorite,
              isAdo: isAdo,
              song: song,
              onTap: () async {
                final success = await FavoritesManager().toggleFavorite(song);
                if (!success && context.mounted) {
                  CustomToastService.show(
                    context,
                    message: 'No puedes desmarcar tu canción principal',
                    type: ToastType.error,
                  );
                }
              },
            );
          },
        ),
        // Agregar a Playlist
        IconButton(
          icon: Icon(
            Ionicons.add_circle_outline,
            color: AppColors.textSecondary(mode),
            size: 26,
          ),
          onPressed: () =>
              PlaylistActionService.showAddToPlaylistDialog(context, song),
        ),
        // Repetir
        ValueListenableBuilder<LoopMode>(
          valueListenable: manager.loopModeNotifier,
          builder: (context, loopMode, _) {
            Color color = AppColors.textSecondary(mode);
            if (loopMode == LoopMode.one || loopMode == LoopMode.all) {
              color = AppColors.primaryBlueMid;
            }
            IconData icon = Ionicons.repeat;
            if (loopMode == LoopMode.one) {
              icon = Ionicons.repeat; // O icono con 1
            }

            return IconButton(
              icon: Icon(icon, color: color, size: 26),
              onPressed: manager.toggleLoopMode,
            );
          },
        ),
      ],
    );
  }
}

// Tarjeta de canción dentro del detalle de playlist (TV)
import 'package:flutter/material.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:provider/provider.dart';

class TvPlaylistSongTile extends StatelessWidget {
  final LocalSong song;
  final bool removeMode;
  final bool selectedForRemove;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TvPlaylistSongTile({
    super.key,
    required this.song,
    required this.removeMode,
    required this.selectedForRemove,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  /// Construye la tarjeta de canción con soporte a modo eliminar
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    return TvFocusableItem(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: song.artwork != null
                        ? DecorationImage(
                            image: MemoryImage(song.artwork!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.songItemGradient(mode),
                    ),
                    border: Border.all(
                      color: AppColors.themeBorder(mode).withOpacity(0.6),
                    ),
                  ),
                  child: song.artwork == null
                      ? Center(
                          child: Image.asset(
                            'assets/MG-I-T.png',
                            width: 56,
                            opacity: const AlwaysStoppedAnimation(0.8),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary(mode)),
              ),
            ],
          ),
          if (removeMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: selectedForRemove
                      ? Colors.redAccent
                      : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(
                  selectedForRemove
                      ? Icons.delete
                      : Icons.radio_button_unchecked,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

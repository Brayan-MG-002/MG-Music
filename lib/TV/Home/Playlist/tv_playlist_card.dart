// Tarjeta de playlist en la grilla de TV
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:provider/provider.dart';

class TvPlaylistCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const TvPlaylistCard({
    super.key,
    required this.name,
    required this.onTap,
    required this.onLongPress,
  });

  Future<LocalSong?> _getSongByPath(String? path) async {
    if (path == null) return null;
    final allSongs = await SongFetcher().getSongs();
    try {
      return allSongs.firstWhere((s) => s.path == path);
    } catch (_) {
      return null;
    }
  }

  @override
  /// Construye la tarjeta mostrando portada o placeholder y el nombre
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final pm = PlaylistManager();
    return TvFocusableItem(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: pm.getCoverNotifier(name),
              builder: (context, coverPath, _) {
                return FutureBuilder<LocalSong?>(
                  future: _getSongByPath(coverPath),
                  builder: (context, snap) {
                    final artwork = snap.data?.artwork;
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.songItemGradient(mode),
                        ),
                        border: Border.all(
                          color: AppColors.themeBorder(mode).withOpacity(0.6),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: artwork != null
                          ? Image(
                              image: MemoryImage(artwork),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                Ionicons.musical_notes,
                                color: AppColors.textSecondary(mode),
                                size: 40,
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

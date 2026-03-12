import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class PlaylistDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String playlistName;
  final List<LocalSong> songs;
  final VoidCallback onPlay;
  final VoidCallback onShufflePlay;
  final VoidCallback? onEdit;
  final Duration totalDuration;
  final bool isPlaying;

  const PlaylistDetailHeader({
    super.key,
    required this.playlistName,
    required this.songs,
    required this.onPlay,
    required this.onShufflePlay,
    this.onEdit,
    required this.totalDuration,
    required this.isPlaying,
  });

  @override
  /// Altura preferida del header
  Size get preferredSize => const Size.fromHeight(80);

  /// Formatea duración total de la playlist
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h : ${minutes}m';
    } else {
      return '${minutes}m : ${seconds}s';
    }
  }

  @override
  /// Construye el header con título, conteo, duración y botones
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Container(
      height: preferredSize.height,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: AnimationLimiter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: -20.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    Text(
                      playlistName,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColors.textPrimary(mode),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${songs.length} canciones',
                            style: TextStyle(
                              color: AppColors.textSecondary(mode),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Ionicons.time_outline,
                          size: 14,
                          color: AppColors.textSecondary(mode),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDuration(totalDuration),
                            style: TextStyle(
                              color: AppColors.textSecondary(mode),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) =>
                    ScaleAnimation(child: FadeInAnimation(child: widget)),
                children: [
                  if (onEdit != null) ...[
                    _buildPlayButton(
                      icon: Ionicons.pencil_outline,
                      onTap: onEdit!,
                      mode: mode,
                    ),
                    const SizedBox(width: 12),
                  ],
                  _buildPlayButton(
                    icon: Ionicons.shuffle,
                    onTap: onShufflePlay,
                    mode: mode,
                  ),
                  const SizedBox(width: 12),
                  _buildPlayButton(
                    icon: isPlaying ? Ionicons.pause : Ionicons.play,
                    onTap: onPlay,
                    mode: mode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton({
    required IconData icon,
    required VoidCallback onTap,
    required AppThemeMode mode,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: mode == AppThemeMode.dark ? Colors.black : Colors.white,
        border: Border.all(color: AppColors.themeBorder(mode), width: 1.5),
        gradient: LinearGradient(
          colors: AppColors.fabGradient(mode),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.fabAccent(mode).withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: AppColors.textPrimary(mode), size: 24),
          ),
        ),
      ),
    );
  }
}

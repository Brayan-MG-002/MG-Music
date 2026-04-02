import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/ui/mobile/Home/playlist/components/marquee_widget.dart';

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
  Size get preferredSize => Size.fromHeight(95.h);


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
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Container(
      height: preferredSize.height,
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 5.h, top: 20.h),
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
                        fontSize: MediaQuery.of(context).size.height < 700 ? 20.sp : 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final isCompact = screenHeight < 700;
                        final subtitleSize = isCompact ? 11.sp : 13.sp;
                        
                        return MarqueeWidget(
                          child: Row(
                            children: [
                              Text(
                                '${songs.length} canciones',
                                style: TextStyle(
                                  color: AppColors.textSecondary(mode),
                                  fontSize: subtitleSize,
                                ),
                                maxLines: 1,
                              ),
                              SizedBox(width: isCompact ? 6.w : 8.w),
                              Icon(
                                Ionicons.time_outline,
                                size: isCompact ? 12.r : 14.r,
                                color: AppColors.textSecondary(mode),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _formatDuration(totalDuration),
                                style: TextStyle(
                                  color: AppColors.textSecondary(mode),
                                  fontSize: subtitleSize,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        );
                      },
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
        border: Border.all(color: AppColors.themeBorder(mode), width: 1.5.w),
        gradient: LinearGradient(
          colors: AppColors.fabGradient(mode),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.fabAccent(mode).withOpacity(0.5),
            blurRadius: 10.r,
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
            padding: EdgeInsets.all(10.0.r),
            child: Icon(icon, color: AppColors.textPrimary(mode), size: 20.r),
          ),
        ),
      ),
    );
  }
}

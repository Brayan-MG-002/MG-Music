import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/ui/mobile/Home/Player/components/sleep_timer_badge.dart';
import 'package:mg_music/ui/mobile/Home/Player/components/mobile_heart_icon.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'special_components/special_artwork.dart';
import 'special_components/ado_songs_carousel.dart';

class MobileSpecialPlayer extends StatelessWidget {
  const MobileSpecialPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AudioPlayerManager();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0.w, 10.h, 20.0.w, 95.h),
          child: Column(
            children: [
              AnimationConfiguration.synchronized(
                duration: const Duration(milliseconds: 300),
                child: const SlideAnimation(
                  verticalOffset: 20.0,
                  child: FadeInAnimation(
                    child: Center(child: SleepTimerBadge()),
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Expanded(
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 300),
                  child: SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(
                      child: ValueListenableBuilder<LocalSong?>(
                        valueListenable: manager.currentSongNotifier,
                        builder: (context, song, _) {
                          if (song == null) return const SizedBox.shrink();
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SpecialArtwork(song: song),
                              
                              ValueListenableBuilder<List<String>>(
                                valueListenable: FavoritesManager().favoritePathsNotifier,
                                builder: (context, favoritePaths, _) {
                                  final isFavorite = favoritePaths.contains(song.path);
                                  final isAdo = AdoHandler.isAdo(song);
                                  return Transform.scale(
                                    scale: 1.25,
                                    child: MobileHeartIcon(
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
                                    ),
                                  );
                                },
                              ),
                              
                              Flexible(
                                flex: 3,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: 180.h),
                                  child: AdoSongsCarousel(currentSong: song),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

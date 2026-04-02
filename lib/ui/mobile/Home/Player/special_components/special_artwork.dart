import 'package:flutter/material.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:provider/provider.dart';
import 'circular_visualizer.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';

class SpecialArtwork extends StatelessWidget {
  final LocalSong song;

  const SpecialArtwork({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final screenHeight = MediaQuery.of(context).size.height;
    final isAdo = AdoHandler.isAdo(song);
    final isHQ = AdoHandler.isHighQuality(song);

    double baseSize;
    if (ResponsiveService.isTablet) {
      baseSize = 280.0.r;
    } else {
      double hFactor = (screenHeight - 450) / (800 - 450);
      hFactor = hFactor.clamp(0.0, 1.0);
      baseSize = 140.0 + (80.0 * hFactor);
    }
    final size = baseSize.r;

    Gradient? borderGradient;
    Color? borderColor;
    if (isAdo && isHQ) {
      borderGradient = LinearGradient(
        colors: [AppColors.themeBorder(mode), const Color(0xFFFFD700)],
        stops: const [0.4, 1.0],
      );
    } else if (isAdo && !isHQ) {
      borderColor = AppColors.themeBorder(mode).withOpacity(0.3);
    } else if (!isAdo && isHQ) {
      borderColor = const Color(0xFFFFD700);
    } else {
      borderColor = AppColors.themeBorder(mode).withOpacity(0.3);
    }

    final shadowList = [
      BoxShadow(
        color: AppColors.themeBorder(mode).withOpacity(0.4),
        blurRadius: 20.r,
        spreadRadius: 2.r,
        offset: Offset(0, 10.h),
      ),
    ];
    if (isHQ) {
      shadowList.add(
        BoxShadow(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          blurRadius: 35.r,
          spreadRadius: 8.r,
        ),
      );
    }

    return RepaintBoundary(
      child: Center(
        child: SizedBox(
          width: size + 60.r,
          height: size + 60.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: AudioPlayerManager().isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return CircularVisualizer(
                    size: size + 60.r,
                    isPlaying: isPlaying,
                    gradient: borderGradient,
                    color: borderColor,
                    mode: mode,
                  );
                }
              ),
              Container(
                height: size,
                width: size,
                padding: EdgeInsets.all(borderGradient != null ? 3.r : 1.5.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.r),
                  gradient: borderGradient,
                  border: borderGradient == null ? Border.all(color: borderColor!, width: 2.r) : null,
                  boxShadow: shadowList,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: song.artwork != null
                      ? Image.memory(
                          song.artwork!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primaryBlueMid.withOpacity(0.7),
                                mode == AppThemeMode.dark ? Colors.black : Colors.white,
                              ],
                            ),
                          ),
                          child: Center(child: Icon(Icons.music_note, size: 50.r, color: Colors.white)),
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

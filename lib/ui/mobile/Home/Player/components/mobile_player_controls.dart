// m:\MG Proyect\MG Music\MG Music\lib\Mobile\Home\Player\components\mobile_player_controls.dart

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';

import 'package:mg_music/services/ui/responsive_service.dart';

class MobilePlayerControls extends StatelessWidget {
  final AudioPlayerManager manager;

  const MobilePlayerControls({super.key, required this.manager});

  @override
  /// Construye controles principales: anterior, play/pausa y siguiente
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Ionicons.play_skip_back,
            color: AppColors.textPrimary(mode),
            size: 40.r,
          ),
          onPressed: manager.previous,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: manager.isPlayingNotifier,
          builder: (context, isPlaying, _) {
            return Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: mode == AppThemeMode.dark ? Colors.black : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.themeBorder(mode),
                  width: 2.5.w,
                ),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: mode == AppThemeMode.dark
                      ? [Colors.blue.shade900.withOpacity(0.5), Colors.black]
                      : [Colors.blue.shade200.withOpacity(0.8), Colors.white],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.fabAccent(mode).withOpacity(0.3),
                    blurRadius: 15.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 40.r,
                icon: Icon(
                  isPlaying ? Ionicons.pause : Ionicons.play,
                  color: AppColors.textPrimary(
                    mode,
                  ),
                ),
                onPressed: manager.togglePlayPause,
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Ionicons.play_skip_forward,
            color: AppColors.textPrimary(mode),
            size: 40.r,
          ),
          onPressed: manager.next,
        ),
      ],
    );
  }
}

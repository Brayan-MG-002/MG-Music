// Copyright © 2026 Brayan Medrano - MG Music
// Indicador de progreso circular personalizado para la interfaz de TV, adaptado al color del tema.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';

class TvArtworkColorProgressIndicator extends StatelessWidget {
  final Uint8List? artwork;
  final AudioPlayerManager manager;

  const TvArtworkColorProgressIndicator({
    super.key,
    required this.artwork,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    final progressColor = AppColors.primaryBlueMid;

    return ValueListenableBuilder<Duration>(
      valueListenable: manager.positionNotifier,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: manager.durationNotifier,
          builder: (context, duration, _) {
            double progress = 0.0;
            if (duration.inMilliseconds > 0) {
              progress = position.inMilliseconds / duration.inMilliseconds;
            }
            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 500),
              tween: ColorTween(begin: AppColors.primaryBlueMid, end: progressColor),
              builder: (context, color, _) {
                return CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? AppColors.primaryBlueMid,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

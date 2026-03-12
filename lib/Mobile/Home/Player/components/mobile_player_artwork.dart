// m:\MG Proyect\MG Music\MG Music\lib\Mobile\Home\Player\components\mobile_player_artwork.dart

import 'package:flutter/material.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class MobilePlayerArtwork extends StatelessWidget {
  final LocalSong song;

  const MobilePlayerArtwork({super.key, required this.song});

  @override
  /// Construye la carátula con tamaño responsivo y sombra
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    final screenWidth = MediaQuery.of(context).size.width;

    final size = (screenWidth * 0.55).clamp(160.0, 260.0);

    return RepaintBoundary(
      child: Center(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.fabAccent(mode).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: song.artwork != null
                ? Image.memory(
                    song.artwork!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : Image.asset('assets/MG-I-T.png', fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

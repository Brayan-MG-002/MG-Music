import 'package:flutter/material.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:provider/provider.dart';

class MobilePlayerArtwork extends StatelessWidget {
  final LocalSong song;

  const MobilePlayerArtwork({super.key, required this.song});

  @override
  /// Construye la carátula con tamaño responsivo y estilo de poster premium
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    final screenHeight = MediaQuery.of(context).size.height;
    final isAdo = AdoHandler.isAdo(song);

    // Smooth fluid scaling based on height - prioritizing compactness
    double baseSize;
    if (ResponsiveService.isTablet) {
      baseSize = 320.0.r;
    } else {
      // Interpolate between 155 and 245 based on height between 500 and 800
      double hFactor = (screenHeight - 500) / (800 - 500);
      hFactor = hFactor.clamp(0.0, 1.0);
      baseSize = 155.0 + (90.0 * hFactor);
    }

    final size = baseSize.r;

    return RepaintBoundary(
      child: Center(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.themeBorder(mode).withOpacity(0.3),
              width: 1.5.r,
            ),
            boxShadow: [
              // Shadow Base
              BoxShadow(
                color: AppColors.themeBorder(mode).withOpacity(0.4),
                blurRadius: 20.r,
                spreadRadius: 2.r,
                offset: Offset(0, 10.h),
              ),
              // Glow Ambient
              BoxShadow(
                color:
                    (isAdo ? AppColors.adoGlow(mode) : AppColors.primaryBlueMid)
                        .withOpacity(0.2),
                blurRadius: 30.r,
                spreadRadius: 5.r,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
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
                          mode == AppThemeMode.dark
                              ? Colors.black
                              : Colors.white,
                        ],
                        center: Alignment.center,
                        radius: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(size * 0.15),
                        child: Image.asset(
                          'assets/MG-I-T.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

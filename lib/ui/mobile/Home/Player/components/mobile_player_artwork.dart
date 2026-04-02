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
      // Interpolate between 120 and 245 based on height between 450 and 800
      double hFactor = (screenHeight - 450) / (800 - 450);
      hFactor = hFactor.clamp(0.0, 1.0);
      baseSize = 120.0 + (125.0 * hFactor);
    }

    final size = baseSize.r;

    final isHQ = AdoHandler.isHighQuality(song);
    
    Gradient? borderGradient;
    Color? borderColor;
    
    if (isAdo && isHQ) {
      borderGradient = LinearGradient(
        colors: [AppColors.themeBorder(mode), const Color(0xFFFFD700)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.4, 1.0], // Balance para que el dorado sea ~50% visual
      );
    } else if (isAdo && !isHQ) {
      borderColor = AppColors.themeBorder(mode).withOpacity(0.3);
    } else if (!isAdo && isHQ) {
      borderColor = const Color(0xFFFFD700);
    } else {
      borderColor = AppColors.themeBorder(mode).withOpacity(0.3);
    }

    final shadowList = [
      // Shadow Base
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
          color: const Color(0xFFFFD700).withOpacity(0.3), // Brillo exclusivo para HQ
          blurRadius: 35.r,
          spreadRadius: 8.r,
        ),
      );
    }

    Widget innerArtwork = ClipRRect(
      borderRadius: BorderRadius.circular(borderGradient != null ? 20.r - 1.5.r : 20.r),
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
    );

    Widget artworkContainer;
    
    if (borderGradient != null) {
      artworkContainer = Container(
        height: size,
        width: size,
        padding: EdgeInsets.all(1.5.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: borderGradient,
          boxShadow: shadowList,
        ),
        child: innerArtwork,
      );
    } else {
      artworkContainer = Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: borderColor!,
            width: 1.5.r,
          ),
          boxShadow: shadowList,
        ),
        child: innerArtwork,
      );
    }

    return RepaintBoundary(
      child: Center(
        child: artworkContainer,
      ),
    );
  }
}

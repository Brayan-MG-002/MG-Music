import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/services/theme_service.dart';

class PlaylistCard extends StatelessWidget {
  final String name;
  final int songCount;
  final Uint8List? artwork;
  final LocalSong? firstSong;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PlaylistCard({
    super.key,
    required this.name,
    required this.songCount,
    this.artwork,
    this.firstSong,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  /// Construye la tarjeta de playlist con imagen o ícono y textos
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 800),
      child: ScaleAnimation(
        scale: 0.5,
        curve: Curves.elasticOut,
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Positioned.fill(
                    child: Builder(
                      builder: (context) {
                        final imageBytes = artwork ?? firstSong?.artwork;
                        if (imageBytes != null) {
                          return Image.memory(imageBytes, fit: BoxFit.cover);
                        }
                        return Container(
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
                          child: Icon(
                            Ionicons.musical_notes,
                            size: 50,
                            color: AppColors.textSecondary(
                              mode,
                            ).withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          mode == AppThemeMode.dark
                              ? Colors.black.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: AppColors.textPrimary(mode),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$songCount canciones',
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

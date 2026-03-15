// Copyright © 2026 Brayan Medrano - MG Music
// Elemento de canción del grid TV

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class TvHomeSongItem extends StatelessWidget {
  final LocalSong song;
  final bool isAdo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TvHomeSongItem({
    super.key,
    required this.song,
    required this.isAdo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  /// Construye la tarjeta de canción con estados Ado y reproducción
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    return ValueListenableBuilder<LocalSong?>(
      valueListenable: AudioPlayerManager().currentSongNotifier,
      builder: (context, currentSong, _) {
        final isPlaying = currentSong?.id == song.id;

        return TvFocusableItem(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: 12,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.songItemGradient(mode),
              ),
              border: isPlaying
                  ? Border.all(color: Colors.blueAccent, width: 2.5)
                  : isAdo
                  ? Border.all(color: Colors.blue.shade900, width: 1.5)
                  : Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        song.artwork != null
                            ? Image(
                                image: ResizeImage(
                                  MemoryImage(song.artwork!),
                                  width: 250,
                                ),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.transparent,
                                child: Center(
                                  child: Image.asset(
                                    'assets/MG-I-T.png',
                                    width: 55,
                                    opacity: const AlwaysStoppedAnimation(0.7),
                                  ),
                                ),
                              ),

                        if (isAdo && !isPlaying)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Ado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        if (isPlaying)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.blue.shade900.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Ionicons.musical_notes,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying
                          ? Colors.blueAccent
                          : AppColors.textPrimary(mode),
                      fontSize: 11,
                      fontWeight: isPlaying || isAdo
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TvHomeSongShimmerItem extends StatefulWidget {
  const TvHomeSongShimmerItem({super.key});

  @override
  State<TvHomeSongShimmerItem> createState() => _TvHomeSongShimmerItemState();
}

class _TvHomeSongShimmerItemState extends State<TvHomeSongShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  /// Inicializa la animación shimmer
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  /// Libera recursos de la animación
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  /// Construye el contenedor shimmer animado
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade800.withOpacity(0.4 + _anim.value * 0.3),
              Colors.grey.shade700.withOpacity(0.2 + _anim.value * 0.2),
            ],
          ),
        ),
      ),
    );
  }
}

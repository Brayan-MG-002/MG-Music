import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';

class MobileHomeHeader extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onViewModeChanged;

  const MobileHomeHeader({
    super.key,
    required this.isGridView,
    required this.onViewModeChanged,
  });

  @override
  /// Construye encabezado con toggle de vista, título o contador, y shuffle
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Positioned(
      top: 10.0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 42,
        child: AnimationConfiguration.synchronized(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ScaleAnimation(
                  scale: 0.0,
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 1000),
                  child: FadeInAnimation(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.homeHeaderGlow(mode),
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            border: BorderDirectional(
                              top: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5,
                              ),
                              end: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5,
                              ),
                              bottom: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Icon(
                                isGridView ? Ionicons.list : Ionicons.grid,
                                key: ValueKey<bool>(isGridView),
                                color: Colors.white,
                              ),
                            ),
                            onPressed: onViewModeChanged,
                            splashRadius: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ScaleAnimation(
                  scale: 0.0,
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 1000),
                  child: FadeInAnimation(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.homeHeaderGlow(mode),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.themeBorder(mode),
                              width: 1.5,
                            ),
                          ),
                          child: ValueListenableBuilder<DateTime?>(
                            valueListenable:
                                AudioPlayerManager().sleepEndTimeNotifier,
                            builder: (context, endTime, _) {
                              if (endTime == null) {
                                return Text(
                                  'MG Music',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              }
                              return StreamBuilder(
                                stream: Stream.periodic(
                                  const Duration(seconds: 1),
                                ),
                                builder: (context, snapshot) {
                                  final remaining = endTime.difference(
                                    DateTime.now(),
                                  );
                                  if (remaining.isNegative) {
                                    return const SizedBox.shrink();
                                  }
                                  String twoDigits(int n) =>
                                      n.toString().padLeft(2, '0');
                                  String minutes = twoDigits(
                                    remaining.inMinutes.remainder(60),
                                  );
                                  String seconds = twoDigits(
                                    remaining.inSeconds.remainder(60),
                                  );

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Ionicons.timer_outline,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$minutes:$seconds',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(mode),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => AudioPlayerManager()
                                            .setSleepTimer(0),
                                        child: Icon(
                                          Ionicons.close_circle,
                                          color: AppColors.textSecondary(mode),
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ScaleAnimation(
                  scale: 0.0,
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 1000),
                  child: FadeInAnimation(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.homeHeaderGlowReverse(mode),
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            border: BorderDirectional(
                              top: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5,
                              ),
                              start: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5,
                              ),
                              bottom: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: ValueListenableBuilder<bool>(
                            valueListenable:
                                AudioPlayerManager().isShuffleModeNotifier,
                            builder: (context, isShuffle, _) => IconButton(
                              icon: Icon(
                                Ionicons.shuffle,
                                color: isShuffle
                                    ? Colors.lightBlueAccent
                                    : AppColors.icon(mode),
                              ),
                              onPressed: () =>
                                  AudioPlayerManager().toggleShuffleMode(),
                              splashRadius: 20,
                            ),
                          ),
                        ),
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

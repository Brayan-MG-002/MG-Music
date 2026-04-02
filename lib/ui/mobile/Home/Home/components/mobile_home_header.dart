import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class MobileHomeHeader extends StatelessWidget {
  final bool isGridView;
  final bool isScanning; // Nuevo
  final int selectedCount; // Nuevo
  final VoidCallback onViewModeChanged;

  const MobileHomeHeader({
    super.key,
    required this.isGridView,
    required this.isScanning,
    this.selectedCount = 0,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Positioned(
      top: 10.0.h,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 42.h,
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
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15.r),
                        bottomRight: Radius.circular(15.r),
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
                                width: 1.5.w,
                              ),
                              end: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5.w,
                              ),
                              bottom: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5.w,
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
                                color: AppColors.textPrimary(mode),
                              ),
                            ),
                            onPressed: onViewModeChanged,
                            splashRadius: 20.r,
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
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.homeHeaderGlow(mode),
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.themeBorder(mode),
                              width: 1.5.w,
                            ),
                          ),
                          child: ValueListenableBuilder<DateTime?>(
                            valueListenable:
                                AudioPlayerManager().sleepEndTimeNotifier,
                            builder: (context, endTime, _) {
                              if (selectedCount > 0) {
                                return Text(
                                  '$selectedCount seleccionadas',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
                                  ),
                                );
                              }
                              if (endTime == null) {
                                if (isScanning) {
                                  return StreamBuilder<int>(
                                    stream: Stream.periodic(
                                      const Duration(milliseconds: 500),
                                      (x) => x % 3,
                                    ),
                                    builder: (context, snapshot) {
                                      final dots =
                                          "." * ((snapshot.data ?? 0) + 1);
                                      return Text(
                                        'Cargando$dots',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(mode),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.sp,
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Text(
                                  'MG Music',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
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
                                      Icon(
                                        Ionicons.timer_outline,
                                        color: Colors.blue,
                                        size: 16.r,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '$minutes:$seconds',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(mode),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      GestureDetector(
                                        onTap: () => AudioPlayerManager()
                                            .setSleepTimer(0),
                                        child: Icon(
                                          Ionicons.close_circle,
                                          color: AppColors.textSecondary(mode),
                                          size: 20.r,
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
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.r),
                        bottomLeft: Radius.circular(15.r),
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
                                width: 1.5.w,
                              ),
                              start: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5.w,
                              ),
                              bottom: BorderSide(
                                color: AppColors.themeBorder(mode),
                                width: 1.5.w,
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
                                    ? AppColors.primaryBlueFixed
                                    : AppColors.icon(mode),
                              ),
                              onPressed: () =>
                                  AudioPlayerManager().toggleShuffleMode(),
                              splashRadius: 20.r,
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

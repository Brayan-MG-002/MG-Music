import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class SharedCoverHeader extends StatelessWidget {
  final AppThemeMode mode;
  final Uint8List? artwork;
  final bool isGlowActive;
  final Animation<double>? glowAnimation;
  final PreferredSizeWidget? bottom;
  final double expandedHeight;

  const SharedCoverHeader({
    super.key,
    required this.mode,
    this.artwork,
    this.isGlowActive = false,
    this.glowAnimation,
    this.bottom,
    this.expandedHeight = 320.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background(mode),
      toolbarHeight: 0.0,
      expandedHeight: expandedHeight,
      pinned: true,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background(mode),
                AppColors.primaryBlueMid,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 80.h),
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 800),
                  child: FadeInAnimation(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation:
                            glowAnimation ?? const AlwaysStoppedAnimation(0.0),
                        builder: (context, child) {
                          final double animationValue =
                              glowAnimation?.value ?? 0.0;
                          final glowRadius = isGlowActive
                              ? (20 + (animationValue * 25)).r
                              : 20.0.r;
                          final glowOpacity = isGlowActive
                              ? 0.4 + (animationValue * 0.4)
                              : 0.2;

                          return Container(
                            width: 180.r,
                            height: 180.r,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              border: isGlowActive
                                  ? Border.all(
                                      color: AppColors.themeBorder(mode),
                                      width: 2.5.w,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.themeBorder(
                                    mode,
                                  ).withOpacity(0.4),
                                  blurRadius: 20.r,
                                  spreadRadius: 2.r,
                                  offset: Offset(0, 8.h),
                                ),
                                if (isGlowActive)
                                  BoxShadow(
                                    color: AppColors.primaryBlueMid.withOpacity(
                                      glowOpacity,
                                    ),
                                    blurRadius: glowRadius,
                                    spreadRadius: (5 + (animationValue * 5)).r,
                                  )
                                else
                                  BoxShadow(
                                    color: AppColors.primaryBlueMid.withOpacity(
                                      0.2,
                                    ),
                                    blurRadius: 30.r,
                                    spreadRadius: 5.r,
                                  ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: artwork != null
                                  ? Image.memory(artwork!, fit: BoxFit.cover)
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            AppColors.primaryBlueMid.withOpacity(
                                              0.7,
                                            ),
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
                                          padding: EdgeInsets.all(35.r),
                                          child: Image.asset(
                                            'assets/MG-I-T.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}

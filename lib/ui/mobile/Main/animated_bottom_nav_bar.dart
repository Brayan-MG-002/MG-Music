import 'dart:ui';
import 'package:animations_plus/animations_plus.dart' hide ScaleAnimation;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/ui/mobile/Main/bottom_nav_item.dart';
import 'package:mg_music/ui/mobile/Main/painters.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/logic/notification_service.dart';
import 'dart:math' as math;
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/ado_experience_service.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/sleep_timer_modal.dart';
import 'package:mg_music/services/ui/playlist_action_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final bool showFullPlayer;
  final Function(int) onNavItemTap;

  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.showFullPlayer,
    required this.onNavItemTap,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar> {
  bool _iconsVisible = false;
  bool _hasPendingUpdate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _iconsVisible = true;
        });
      }
    });
    _loadPendingUpdate();
  }

  Future<void> _loadPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getInt('pending_update_version_code') ?? 0;
    if (mounted) setState(() => _hasPendingUpdate = code > 0);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = AudioPlayerManager();
    return ValueListenableBuilder<LocalSong?>(
      valueListenable: audioManager.currentSongNotifier,
      builder: (context, song, _) {
        final isAdo = song != null && AdoHandler.isAdo(song);
        final specialEnabled = AdoExperienceService().dedicatedPlayerEnabled;
        final isSpecialExpanded =
            widget.showFullPlayer && isAdo && specialEnabled;

        return SimpleFadeAnimation(
          duration: const Duration(milliseconds: 400),
          delay: const Duration(milliseconds: 150),
          child: SimpleSlideAnimation(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 150),
            direction: SlideDirection.down,
            child: Consumer<ThemeService>(
              builder: (context, themeService, _) {
                final mode = themeService.mode;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.r),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: CustomPaint(
                          painter: NavBarPainter(
                            borderColor: AppColors.themeBorder(mode),
                            mode: mode,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            height:
                                (isSpecialExpanded ? 85.h : 70.h) +
                                MediaQuery.of(context).padding.bottom,
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: isSpecialExpanded
                                  ? _buildSpecialControls(
                                      context,
                                      mode,
                                      audioManager,
                                      song,
                                    )
                                  : _iconsVisible
                                  ? AnimationLimiter(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          _buildAnimatedNavItem(
                                            0,
                                            0,
                                            Ionicons.musical_notes_outline,
                                            Ionicons.musical_notes,
                                            'Pistas',
                                          ),
                                          _buildAnimatedNavItem(
                                            1,
                                            1,
                                            Ionicons.list_outline,
                                            Ionicons.list,
                                            'Playlists',
                                          ),
                                          Consumer<NotificationService>(
                                            builder: (context, notifService, _) {
                                              return _buildAnimatedNavItemWithBadge(
                                                2,
                                                2,
                                                Ionicons.notifications_outline,
                                                Ionicons.notifications,
                                                'Noti',
                                                notifService.unreadCount,
                                              );
                                            },
                                          ),
                                          _buildAnimatedNavItem(
                                            3,
                                            3,
                                            Ionicons.heart_outline,
                                            Ionicons.heart,
                                            'Favoritos',
                                          ),
                                          _buildAnimatedNavItemWithBadge(
                                            4,
                                            4,
                                            Ionicons.settings_outline,
                                            Ionicons.settings,
                                            'Ajustes',
                                            _hasPendingUpdate ? 1 : 0,
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isSpecialExpanded) ...[
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ValueListenableBuilder<Duration>(
                            valueListenable: audioManager.positionNotifier,
                            builder: (context, position, _) {
                              return ValueListenableBuilder<Duration>(
                                valueListenable: audioManager.durationNotifier,
                                builder: (context, duration, _) {
                                  final posMs = position.inMilliseconds
                                      .toDouble();
                                  final durMs = duration.inMilliseconds
                                      .toDouble();
                                  final safeMax = math.max(durMs, posMs);
                                  final progress = safeMax > 0
                                      ? posMs / safeMax
                                      : 0.0;

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0.0,
                                      end: progress,
                                    ),
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder:
                                        (context, animatedProgress, child) {
                                          return CustomPaint(
                                            painter: _SpecialNavBarPainter(
                                              borderColor:
                                                  AppColors.themeBorder(mode),
                                              mode: mode,
                                              progress: animatedProgress,
                                            ),
                                          );
                                        },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: -25.h,
                        left: 0,
                        right: 0,
                        height: 40.h,
                        child: ValueListenableBuilder<Duration>(
                          valueListenable: audioManager.durationNotifier,
                          builder: (context, duration, _) {
                            final durMs = duration.inMilliseconds.toDouble();
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (details) {
                                if (durMs <= 0) return;
                                final width = MediaQuery.of(context).size.width;
                                final dx = details.localPosition.dx.clamp(
                                  0.0,
                                  width,
                                );
                                final relative = dx / width;
                                audioManager.seek(
                                  Duration(
                                    milliseconds: (relative * durMs).toInt(),
                                  ),
                                );
                              },
                              onTapDown: (details) {
                                if (durMs <= 0) return;
                                final width = MediaQuery.of(context).size.width;
                                final dx = details.localPosition.dx.clamp(
                                  0.0,
                                  width,
                                );
                                final relative = dx / width;
                                audioManager.seek(
                                  Duration(
                                    milliseconds: (relative * durMs).toInt(),
                                  ),
                                );
                              },
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),

                      ValueListenableBuilder<Duration>(
                        valueListenable: audioManager.positionNotifier,
                        builder: (context, position, _) {
                          return ValueListenableBuilder<Duration>(
                            valueListenable: audioManager.durationNotifier,
                            builder: (context, duration, _) {
                              return Positioned(
                                top: -20.h,
                                left: 20.w,
                                right: 20.w,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: TextStyle(
                                        color: AppColors.textSecondary(mode),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(
                                        color: AppColors.textSecondary(mode),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialControls(
    BuildContext context,
    AppThemeMode mode,
    AudioPlayerManager manager,
    LocalSong song,
  ) {
    return Column(
      key: const ValueKey('special_controls'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 5.h),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryShort = constraints.maxHeight < 60;
              final iconScale = isVeryShort ? 0.8 : 1.0;

              return AnimationLimiter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpecialNavItem(
                      0,
                      Ionicons.play_skip_back,
                      () => manager.previous(),
                    ),
                    _buildSpecialNavItem(
                      1,
                      Ionicons.add_circle_outline,
                      () => PlaylistActionService.showAddToPlaylistDialog(
                        context,
                        song,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: manager.isPlayingNotifier,
                      builder: (context, isPlaying, _) {
                        return _buildSpecialPlayPause(
                          2,
                          isPlaying,
                          iconScale,
                          mode,
                          manager,
                        );
                      },
                    ),
                    _buildSpecialNavItem(
                      3,
                      Ionicons.timer_outline,
                      () => SleepTimerModal.show(context),
                    ),
                    _buildSpecialNavItem(
                      4,
                      Ionicons.play_skip_forward,
                      () => manager.next(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  Widget _buildAnimatedNavItem(
    int index,
    int position,
    IconData iconOff,
    IconData iconOn,
    String label,
  ) {
    return _buildAnimatedNavItemWithBadge(
      index,
      position,
      iconOff,
      iconOn,
      label,
      0,
    );
  }

  Widget _buildAnimatedNavItemWithBadge(
    int index,
    int position,
    IconData iconOff,
    IconData iconOn,
    String label,
    int unreadCount,
  ) {
    final bool isActuallySelected = widget.selectedIndex == index;

    return Expanded(
      child: _AnimationWrapper(
        position: position,
        child: _BounceOnSelection(
          isSelected: isActuallySelected,
          child: BottomNavItem(
            iconOff: iconOff,
            iconOn: iconOn,
            label: label,
            isSelected: isActuallySelected,
            onTap: () => widget.onNavItemTap(index),
            iconWidget: unreadCount > 0
                ? Badge(
                    label: Text(unreadCount.toString()),
                    child: Icon(
                      isActuallySelected ? iconOn : iconOff,
                      color: isActuallySelected
                          ? AppColors.textPrimary(
                              context.read<ThemeService>().mode,
                            )
                          : AppColors.icon(context.read<ThemeService>().mode),
                      size: 24.r,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialNavItem(
    int position,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return _AnimationWrapper(
      position: position,
      child: IconButton(
        iconSize: 26.r,
        icon: Icon(
          icon,
          color: AppColors.textPrimary(context.read<ThemeService>().mode),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSpecialPlayPause(
    int position,
    bool isPlaying,
    double scale,
    AppThemeMode mode,
    AudioPlayerManager manager,
  ) {
    return _AnimationWrapper(
      position: position,
      child: Container(
        width: 60.r * scale,
        height: 60.r * scale,
        decoration: BoxDecoration(
          color: mode == AppThemeMode.dark ? Colors.black : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.themeBorder(mode), width: 2.0.w),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              mode == AppThemeMode.dark
                  ? AppColors.primaryBlueMid.withOpacity(0.5)
                  : AppColors.primaryBlueMid.withOpacity(0.4),
              mode == AppThemeMode.dark ? Colors.black : Colors.white,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.fabAccent(mode).withOpacity(0.3),
              blurRadius: 10.r * scale,
              spreadRadius: 1.r * scale,
            ),
          ],
        ),
        child: IconButton(
          iconSize: 30.r * scale,
          padding: EdgeInsets.zero,
          icon: Icon(
            isPlaying ? Ionicons.pause : Ionicons.play,
            color: AppColors.textPrimary(mode),
          ),
          onPressed: () => manager.togglePlayPause(),
        ),
      ),
    );
  }
}

class _AnimationWrapper extends StatelessWidget {
  final int position;
  final Widget child;

  const _AnimationWrapper({required this.position, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: position,
      duration: const Duration(milliseconds: 800),
      child: ScaleAnimation(
        scale: 0.0,
        curve: Curves.elasticOut,
        child: FadeInAnimation(child: child),
      ),
    );
  }
}

class _BounceOnSelection extends StatefulWidget {
  final bool isSelected;
  final Widget child;

  const _BounceOnSelection({required this.isSelected, required this.child});

  @override
  State<_BounceOnSelection> createState() => _BounceOnSelectionState();
}

class _BounceOnSelectionState extends State<_BounceOnSelection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  /// Inicializa el control de rebote al seleccionar
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  /// Dispara la animación cuando cambia a seleccionado
  void didUpdateWidget(covariant _BounceOnSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  /// Libera el controlador de animación
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Aplica la animación de escala al hijo
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

class _SpecialNavBarPainter extends CustomPainter {
  final Color borderColor;
  final AppThemeMode mode;
  final double progress;

  _SpecialNavBarPainter({
    required this.borderColor,
    required this.mode,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final borderPath = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(0, 0, 20, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20);

    // Draw progress gradient border and thumb
    final progressPaint = Paint()
      ..shader = AppGradients.of(
        mode,
        GradientDirection.leftRight,
      ).createShader(rect)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final metrics = borderPath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final borderSegment = metrics.first;
      final distance = borderSegment.length * progress;
      final extracted = borderSegment.extractPath(0.0, distance);
      canvas.drawPath(extracted, progressPaint);

      final tangent = borderSegment.getTangentForOffset(distance);
      if (tangent != null && progress > 0) {
        final thumbPaint = Paint()..color = Colors.white;
        canvas.drawCircle(tangent.position, 6.0, thumbPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpecialNavBarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mode != mode;
}

// Copyright © 2026 Brayan Medrano - MG Music
// Barra lateral de navegación para TV

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/ui/tv/Home/Player/tv_player_widget.dart';
import 'package:mg_music/ui/tv/Main/tv_progress_indicator.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';

class TvSidebarPainter extends CustomPainter {
  final Color borderColor;
  final AppThemeMode mode;

  TvSidebarPainter({required this.borderColor, required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: mode == AppThemeMode.dark
            ? [
                Colors.blue.shade900.withOpacity(0.6),
                Colors.blue.shade900.withOpacity(0.2),
              ]
            : [
                Colors.white.withOpacity(0.9),
                Colors.blue.shade300.withOpacity(0.6),
              ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(size.width, size.height, size.width - 20, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = mode == AppThemeMode.dark
            ? Colors.black.withOpacity(0.5)
            : Colors.transparent,
    );

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(size.width, size.height, size.width - 20, size.height)
      ..lineTo(0, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  /// Indica que siempre debe repintarse
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TvSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const TvSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  /// Construye la barra lateral con animaciones y fondo personalizado
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final mode = themeService.mode;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: CustomPaint(
              painter: TvSidebarPainter(
                borderColor: AppColors.themeBorder(mode),
                mode: mode,
              ),
              child: SizedBox(
                width: 100,
                child: AnimationLimiter(
                  child: Column(
                    children: [
                      _buildAnimatedItem(0, _buildSidebarHeader(mode)),
                      _buildAnimatedItem(
                        1,
                        _buildMenuItem(
                          0,
                          Ionicons.musical_notes_outline,
                          Ionicons.musical_notes,
                          'Pistas',
                          mode,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAnimatedItem(
                        2,
                        _buildMenuItem(
                          1,
                          Ionicons.list_outline,
                          Ionicons.list,
                          'Playlists',
                          mode,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAnimatedItem(
                        3,
                        _buildMenuItem(
                          2,
                          Ionicons.heart_outline,
                          Ionicons.heart,
                          'Favoritos',
                          mode,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAnimatedItem(
                        4,
                        _buildMenuItem(
                          3,
                          Ionicons.settings_outline,
                          Ionicons.settings,
                          'Ajustes',
                          mode,
                        ),
                      ),
                      const Spacer(),
                      _buildAnimatedItem(5, _buildSleepTimerStatus(mode)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Envuelve un widget con la animación de entrada
  Widget _buildAnimatedItem(int position, Widget child) {
    return AnimationConfiguration.staggeredList(
      position: position,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        horizontalOffset: -50.0,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  /// Construye el encabezado de la barra lateral (Logo o mini reproductor circular)
  Widget _buildSidebarHeader(AppThemeMode mode) {
    final manager = AudioPlayerManager();
    return ValueListenableBuilder<String>(
      valueListenable: manager.startupModeNotifier,
      builder: (context, startupMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: manager.isRestoringNotifier,
          builder: (context, isRestoring, _) {
            if (isRestoring) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlueLight,
                    strokeWidth: 3,
                  ),
                ),
              );
            }
            return ValueListenableBuilder<LocalSong?>(
              valueListenable: manager.currentSongNotifier,
              builder: (context, song, _) {
                // Logo por defecto
                final Widget logo = Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Image.asset('assets/MG-I-T.png', width: 60),
                );
                // Mini control circular
                final Widget mini = Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: TvFocusableItem(
                    onTap: manager.togglePlayPause,
                    onLongPress: manager.next,
                    borderRadius: 50,
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: TvArtworkColorProgressIndicator(
                              artwork: song?.artwork,
                              manager: manager,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: RotatingArtwork(
                              artwork: song?.artwork,
                              isPlayingNotifier: manager.isPlayingNotifier,
                              size: 60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final showMini = selectedIndex != 0 && song != null;
                return PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder:
                      (child, primaryAnimation, secondaryAnimation) {
                    final inSlide = Tween<Offset>(
                      begin: showMini ? const Offset(1, 0) : const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: primaryAnimation,
                      curve: Curves.easeOutCubic,
                    ));
                    final outSlide = Tween<Offset>(
                      begin: Offset.zero,
                      end: showMini ? const Offset(-1, 0) : const Offset(1, 0),
                    ).animate(CurvedAnimation(
                      parent: secondaryAnimation,
                      curve: Curves.easeInCubic,
                    ));
                    return SlideTransition(
                      position: inSlide,
                      child: SlideTransition(
                        position: outSlide,
                        child: child,
                      ),
                    );
                  },
                  child: showMini
                      ? SizedBox(key: const ValueKey('mini'), child: mini)
                      : SizedBox(key: const ValueKey('logo'), child: logo),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Construye un elemento de menú de la barra lateral
  Widget _buildMenuItem(
    int index,
    IconData iconOff,
    IconData iconOn,
    String label,
    AppThemeMode mode,
  ) {
    final isSelected = selectedIndex == index;

    final color = isSelected
        ? AppColors.textPrimary(mode)
        : AppColors.icon(mode);

    return TvFocusableItem(
      isSelected: isSelected,
      onTap: () => onItemSelected(index),
      borderRadius: 12,
      selectedColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppGradients.of(
                  mode,
                  GradientDirection.centerOut,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.themeBorder(mode), width: 1),
              )
            : null,
        child: Column(
          children: [
            Icon(isSelected ? iconOn : iconOff, color: color, size: 30),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Muestra el estado del temporizador de reposo
  Widget _buildSleepTimerStatus(AppThemeMode mode) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: AudioPlayerManager().sleepEndTimeNotifier,
      builder: (context, endTime, _) {
        if (endTime == null) return const SizedBox.shrink();

        return StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            final now = DateTime.now();
            final remaining = endTime.difference(now);

            if (remaining.isNegative) {
              return const SizedBox.shrink();
            }

            final minutes = remaining.inMinutes;
            final seconds = remaining.inSeconds % 60;
            final timeString =
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

            final color = AppColors.primaryBlueLight;
            return Column(
              children: [
                Icon(Ionicons.timer_outline, color: color, size: 20),
                const SizedBox(height: 5),
                Text(
                  timeString,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

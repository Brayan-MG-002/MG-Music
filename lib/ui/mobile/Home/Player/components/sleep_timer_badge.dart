// Copyright © 2026 Brayan Medrano - MG Music
// Badge del cronómetro del temporizador de sueño — reutilizable en el Player

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';

/// Muestra "MG Music" cuando no hay temporizador activo.
/// Cuando hay temporizador muestra un cronómetro de cuenta regresiva
/// con botón de cancelar — mismo diseño que el header de la Home.
import 'package:mg_music/services/ui/responsive_service.dart';

/// Muestra "MG Music" cuando no hay temporizador activo.
/// Cuando hay temporizador muestra un cronómetro de cuenta regresiva
/// con botón de cancelar — mismo diseño que el header de la Home.
class SleepTimerBadge extends StatelessWidget {
  const SleepTimerBadge({super.key});

  @override
  /// Construye el badge del temporizador o el título por defecto
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return ValueListenableBuilder<DateTime?>(
      valueListenable: AudioPlayerManager().sleepEndTimeNotifier,
      builder: (context, endTime, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: mode == AppThemeMode.dark
                    ? LinearGradient(
                        colors: [
                          Colors.blue.shade900.withOpacity(0.6),
                          Colors.black.withOpacity(0.5),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.blue.shade300.withOpacity(0.6),
                          Colors.white.withOpacity(0.5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.themeBorder(mode),
                  width: 1.5.w,
                ),
              ),
              child: endTime == null
                  ? Text(
                      'MG Music',
                      style: TextStyle(
                        color: AppColors.textPrimary(mode),
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    )
                  : _SleepCountdown(endTime: endTime, mode: mode),
            ),
          ),
        );
      },
    );
  }
}

/// Cronómetro interno — recalcula cada segundo usando Stream.periodic
class _SleepCountdown extends StatelessWidget {
  final DateTime endTime;
  final AppThemeMode mode;
  const _SleepCountdown({required this.endTime, required this.mode});

  @override
  /// Construye el cronómetro con botón para cancelar temporizador
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) return const SizedBox.shrink();

        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final minutes = twoDigits(remaining.inMinutes.remainder(60));
        final seconds = twoDigits(remaining.inSeconds.remainder(60));

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.timer_outline,
              color: mode == AppThemeMode.dark
                  ? Colors.blue
                  : Colors.blue.shade700,
              size: 16.r,
            ),
            SizedBox(width: 6.w),
            Text(
              '$minutes:$seconds',
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => AudioPlayerManager().setSleepTimer(0),
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
  }
}

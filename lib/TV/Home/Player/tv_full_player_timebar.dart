// Barra de tiempo vertical del reproductor TV
// Controla y muestra progreso/duración con navegación por control remoto
import 'package:flutter/material.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/tv_full_player_logic.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/theme_service.dart';

class TvFullPlayerTimeBar extends StatelessWidget {
  final AudioPlayerManager playerManager;
  final TvFullPlayerLogic logic;
  final AppThemeMode mode;

  const TvFullPlayerTimeBar({
    super.key,
    required this.playerManager,
    required this.logic,
    required this.mode,
  });

  @override
  /// Construye la barra de tiempo con slider vertical enfocable
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<Duration>(
              valueListenable: playerManager.durationNotifier,
              builder: (context, duration, _) {
                return Text(
                  logic.formatDuration(duration),
                  style: TextStyle(
                    color: AppColors.textSecondary(mode),
                    fontSize: 12,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder<Duration>(
                valueListenable: playerManager.positionNotifier,
                builder: (context, position, _) {
                  return ValueListenableBuilder<Duration>(
                    valueListenable: playerManager.durationNotifier,
                    builder: (context, duration, _) {
                      return TvFocusableItem(
                        focusNode: logic.sliderFocusNode,
                        onKeyEvent: (node, event) =>
                            logic.handleSliderKeyEvent(context, node, event),
                        onTap: () {},
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.0,
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.grey.shade800,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.2),
                              trackShape: _GradientTrackShape(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: mode == AppThemeMode.dark
                                      ? [Colors.blue.shade900, Colors.black]
                                      : [Colors.blue.shade500, Colors.white],
                                ),
                              ),
                            ),
                            child: Slider(
                              value: position.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0, duration.inMilliseconds.toDouble()),
                              min: 0.0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                playerManager.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<Duration>(
              valueListenable: playerManager.positionNotifier,
              builder: (context, position, _) {
                return Text(
                  logic.formatDuration(position),
                  style: TextStyle(
                    color: AppColors.textPrimary(mode),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientTrackShape extends SliderTrackShape {
  final LinearGradient gradient;
  const _GradientTrackShape({required this.gradient});

  @override
  /// Define el rectángulo preferido del track
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  /// Pinta las secciones activa/inactiva del track con degradado
  void paint(
    PaintingContext context,
    Offset offset, {
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required Offset thumbCenter,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final activeRect = Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom);
    final inactiveRect = Rect.fromLTRB(thumbCenter.dx, rect.top, rect.right, rect.bottom);

    final activePaint = Paint()..shader = gradient.createShader(activeRect);
    final inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor!;

    final r = Radius.circular(rect.height / 2);
    context.canvas.drawRRect(RRect.fromRectAndRadius(inactiveRect, r), inactivePaint);
    context.canvas.drawRRect(RRect.fromRectAndRadius(activeRect, r), activePaint);
  }
}

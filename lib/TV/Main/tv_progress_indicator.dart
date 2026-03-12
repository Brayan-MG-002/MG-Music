// Copyright © 2026 Brayan Medrano - MG Music
// Indicador de progreso con color dominante de carátula para TV

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';

/// Indicador de progreso con color dominante de carátula
class TvArtworkColorProgressIndicator extends StatefulWidget {
  final Uint8List? artwork;
  final AudioPlayerManager manager;

  const TvArtworkColorProgressIndicator({
    super.key,
    required this.artwork,
    required this.manager,
  });

  @override
  State<TvArtworkColorProgressIndicator> createState() =>
      _TvArtworkColorProgressIndicatorState();
}

class _TvArtworkColorProgressIndicatorState
    extends State<TvArtworkColorProgressIndicator> {
  Color _progressColor = Colors.cyanAccent;

  @override
  /// Inicializa el widget y calcula el color inicial
  void initState() {
    super.initState();
    _updateColor();
  }

  @override
  /// Recalcula el color cuando cambia la carátula
  void didUpdateWidget(covariant TvArtworkColorProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.artwork != oldWidget.artwork) {
      _updateColor();
    }
  }

  /// Actualiza el color basado en la carátula
  Future<void> _updateColor() async {
    if (widget.artwork == null) {
      if (mounted) setState(() => _progressColor = Colors.cyanAccent);
      return;
    }
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(MemoryImage(widget.artwork!), width: 50, height: 50),
        maximumColorCount: 10,
      );
      if (mounted) {
        setState(
          () => _progressColor =
              generator.dominantColor?.color ?? Colors.cyanAccent,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _progressColor = Colors.cyanAccent);
    }
  }

  @override
  /// Construye el indicador circular con color animado
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.manager.positionNotifier,
      builder: (context, position, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.manager.durationNotifier,
          builder: (context, duration, _) {
            double progress = 0.0;
            if (duration.inMilliseconds > 0) {
              progress = position.inMilliseconds / duration.inMilliseconds;
            }
            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 500),
              tween: ColorTween(begin: Colors.cyanAccent, end: _progressColor),
              builder: (context, color, _) {
                return CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? Colors.cyanAccent,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

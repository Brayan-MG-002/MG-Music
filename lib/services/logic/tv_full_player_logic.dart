// Copyright © 2026 Brayan Medrano - MG Music
// Lógica de controles para reproductor TV a pantalla completa

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';

class TvFullPlayerLogic {
  final ScrollController scrollController = ScrollController();
  final FocusNode sliderFocusNode = FocusNode();
  final double itemHeight = 60.0;

  void dispose() {
    scrollController.dispose();
    sliderFocusNode.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void scrollToCurrent(int index) {
    if (scrollController.hasClients) {
      final offset = (index * itemHeight) - 170.0;
      scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  KeyEventResult handleSliderKeyEvent(
    BuildContext context,
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is KeyDownEvent) {
      final playerManager = AudioPlayerManager();

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        FocusScope.of(context).focusInDirection(TraversalDirection.left);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        FocusScope.of(context).focusInDirection(TraversalDirection.right);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        final newPos =
            playerManager.positionNotifier.value + const Duration(seconds: 10);
        final duration = playerManager.durationNotifier.value;
        playerManager.seek(newPos < duration ? newPos : duration);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final newPos =
            playerManager.positionNotifier.value - const Duration(seconds: 10);
        playerManager.seek(newPos > Duration.zero ? newPos : Duration.zero);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Lógica para el control de la reproducción de audio

import 'dart:async';
import 'package:just_audio/just_audio.dart';

class PlaybackHandler {
  final AudioPlayer _player;
  Timer? _sleepTimer;
  double _originalVolume = 1.0;

  PlaybackHandler(this._player);

  Future<void> play() async {
    try {
      await _player.play();
    } catch (_) {
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  Future<void> setLoopMode(LoopMode mode) async {
    try {
      await _player.setLoopMode(mode);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } catch (_) {}
  }

  void setSleepTimer(int minutes, Function onTimerEnd) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      return;
    }
    final duration = Duration(minutes: minutes);
    _sleepTimer = Timer(duration, () => onTimerEnd());
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
  }

  Future<void> playWithFade(Future<void> Function() playAction) async {
    final originalVolume = _player.volume;
    const steps = 20;
    const fadeDuration = Duration(milliseconds: 1000);
    final stepDuration = Duration(
      milliseconds: fadeDuration.inMilliseconds ~/ steps,
    );

    if (_player.playing) {
      for (int i = 1; i <= steps; i++) {
        final vol = originalVolume * (1 - (i / steps));
        try {
          await _player.setVolume(vol.clamp(0.0, 1.0));
        } catch (_) {
          break;
        }
        await Future.delayed(stepDuration);
      }
    }

    try {
      await _player.setVolume(0);
    } catch (_) {}

    await playAction();

    for (int i = 1; i <= steps; i++) {
      final vol = originalVolume * (i / steps);
      try {
        await _player.setVolume(vol.clamp(0.0, 1.0));
      } catch (_) {
        break;
      }
      await Future.delayed(stepDuration);
    }

    try {
      await _player.setVolume(originalVolume);
    } catch (_) {}
  }

  Future<void> fadeOutAndPause() async {
    _originalVolume = _player.volume;
    const steps = 20;
    const fadeDuration = Duration(seconds: 4);
    final stepDuration = Duration(
      milliseconds: fadeDuration.inMilliseconds ~/ steps,
    );

    for (int i = 1; i <= steps; i++) {
      if (!_player.playing) break;
      final newVolume = _originalVolume * (1 - (i / steps));
      try {
        await _player.setVolume(newVolume.clamp(0.0, 1.0));
      } catch (_) {
        break;
      }
      await Future.delayed(stepDuration);
    }

    await pause();

    try {
      await _player.setVolume(_originalVolume);
    } catch (_) {}
  }
}

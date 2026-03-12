// Copyright © 2026 Brayan Medrano - MG Music
// Lógica para el control de la reproducción de audio

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackHandler {
  final AudioPlayer _player;
  Timer? _sleepTimer;
  double _originalVolume = 1.0;

  PlaybackHandler(this._player);

  /// Reproduce el audio
  Future<void> play() async {
    try {
      await _player.play();
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }

  /// Pausa el audio
  Future<void> pause() async {
    try {
      await _player.pause();
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }

  /// Cambia la posición de reproducción
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }

  /// Establece el modo de repetición
  Future<void> setLoopMode(LoopMode mode) async {
    try {
      await _player.setLoopMode(mode);
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }

  /// Establece el volumen del reproductor
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }

  /// Configura un temporizador de sueño en minutos
  void setSleepTimer(int minutes, Function onTimerEnd) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      return;
    }
    final duration = Duration(minutes: minutes);
    _sleepTimer = Timer(duration, () => onTimerEnd());
  }

  /// Cancela el temporizador de sueño
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
  }

  /// Realiza un fundido para cambiar de pista sin cortes
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
        } on PlatformException catch (e) {
          if (e.code != 'abort') rethrow;
          break; // Si se aborta el volumen, detenemos el fade
        }
        await Future.delayed(stepDuration);
      }
    }

    try {
      await _player.setVolume(0);
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }

    await playAction();

    for (int i = 1; i <= steps; i++) {
      final vol = originalVolume * (i / steps);
      try {
        await _player.setVolume(vol.clamp(0.0, 1.0));
      } on PlatformException catch (e) {
        if (e.code != 'abort') rethrow;
        break;
      }
      await Future.delayed(stepDuration);
    }

    try {
      await _player.setVolume(originalVolume);
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }

  /// Realiza un fade out y pausa al finalizar
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
      } on PlatformException catch (e) {
        if (e.code != 'abort') rethrow;
        break;
      }
      await Future.delayed(stepDuration);
    }

    await pause();

    try {
      await _player.setVolume(_originalVolume);
    } on PlatformException catch (e) {
      if (e.code != 'abort') rethrow;
    }
  }
}

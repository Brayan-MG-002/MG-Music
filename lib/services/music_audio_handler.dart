// Copyright © 2026 Brayan Medrano - MG Music
// Inicializador simplificado para la app

import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/services/audio_service_adapter.dart';
import 'package:flutter/foundation.dart';

/// Handler simplificado que no usa audio_service
class MusicAudioHandler {
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  static MusicAudioHandler? _instance;

  factory MusicAudioHandler() {
    _instance ??= MusicAudioHandler._internal();
    return _instance!;
  }

  MusicAudioHandler._internal();

  Future<void> skipToNext() async {
    await _playerManager.next();
  }

  Future<void> skipToPrevious() async {
    await _playerManager.previous();
  }

  Future<void> play() async {
    await _playerManager.play();
  }

  Future<void> pause() async {
    await _playerManager.pause();
  }

  Future<void> stop() async {
    await _playerManager.pause();
  }

  Future<void> seek(Duration position) async {
    await _playerManager.seek(position);
  }
}

/// Inicializa de forma mínima sin bloqueos
Future<void> initAudioService() async {
  if (kDebugMode) {
    print('🚀 Inicializando handler...');
  }

  try {
    final handler = MusicAudioHandler();
    AudioServiceAdapter.setHandler(handler);
  } catch (e) {}
}

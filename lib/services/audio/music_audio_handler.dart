// Copyright © 2026 Brayan Medrano - MG Music
// Inicializador simplificado para la app

import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/audio/audio_service_adapter.dart';

/// Handler simplificado que no usa audio_service
class MusicAudioHandler {
  final AudioPlayerManager _playerManager = AudioPlayerManager();
  static MusicAudioHandler? _instance;

  factory MusicAudioHandler() {
    _instance ??= MusicAudioHandler._internal();
    return _instance!;
  }

  MusicAudioHandler._internal();

  /// Salta a la siguiente canción
  Future<void> skipToNext() async {
    await _playerManager.next();
  }

  /// Vuelve a la canción anterior
  Future<void> skipToPrevious() async {
    await _playerManager.previous();
  }

  /// Reanuda la reproducción
  Future<void> play() async {
    await _playerManager.play();
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    await _playerManager.pause();
  }

  /// Detiene la reproducción (pausa)
  Future<void> stop() async {
    await _playerManager.pause();
  }

  /// Busca a una posición específica
  Future<void> seek(Duration position) async {
    await _playerManager.seek(position);
  }
}

/// Inicializa de forma mínima sin bloqueos
Future<void> initAudioService() async {
  try {
    final handler = MusicAudioHandler();
    AudioServiceAdapter.setHandler(handler);
  } catch (e) {}
}

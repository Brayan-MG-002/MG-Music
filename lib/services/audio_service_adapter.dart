// Copyright © 2026 Brayan Medrano - MG Music
// Adaptador simplificado para la notificación

import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/services/music_audio_handler.dart';

/// Adaptador simplificado para manejar notificaciones
class AudioServiceAdapter {
  static MusicAudioHandler? _handler;

  /// Configura el handler
  static void setHandler(MusicAudioHandler handler) {
    _handler = handler;
  }

  /// Actualiza la notificación
  static Future<void> updateNotification(
    LocalSong song, {
    required bool isPlaying,
    required bool showPrevious,
    required bool showNext,
  }) async {
    try {
      if (_handler == null) {
        return;
      }

      await updatePlaybackState(
        isPlaying: isPlaying,
        showPrevious: showPrevious,
        showNext: showNext,
      );
    } catch (e) {}
  }

  /// Actualiza solo el estado
  static Future<void> updatePlaybackState({
    required bool isPlaying,
    required bool showPrevious,
    required bool showNext,
  }) async {
    try {
      if (_handler == null) return;

      // Aquí iría la lógica de actualizar estado
      // Por ahora, solo loguear
    } catch (e) {}
  }
}

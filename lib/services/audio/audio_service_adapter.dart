// Copyright © 2026 Brayan Medrano - MG Music
// Adaptador simplificado para la notificación

import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/music_audio_handler.dart';

class AudioServiceAdapter {
  static MusicAudioHandler? _handler;

  static void setHandler(MusicAudioHandler handler) {
    _handler = handler;
  }

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

  static Future<void> updatePlaybackState({
    required bool isPlaying,
    required bool showPrevious,
    required bool showNext,
  }) async {
    try {
      if (_handler == null) return;
    } catch (e) {}
  }
}

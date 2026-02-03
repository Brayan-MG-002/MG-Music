// Copyright © 2026 Brayan Medrano - MG Music
// Gestión de notificaciones del sistema para reproducción de audio

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';

/// Instala el manejador de eventos de notificación
void _installHandler() {
  NotificationChannel._chan.setMethodCallHandler((call) async {
    if (call.method == 'notificationAction') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final action = args?['action'] as String?;
      final mgr = AudioPlayerManager();

      switch (action) {
        case 'MG_ACTION_PREV':
          await mgr.previous();
        case 'MG_ACTION_PLAY_PAUSE':
          await mgr.togglePlayPause();
        case 'MG_ACTION_NEXT':
          await mgr.next();
      }
    }
  });
}

/// Gestiona la comunicación con notificaciones nativas de Android
class NotificationChannel {
  static const MethodChannel _chan = MethodChannel('mg_music/notification');
  static bool _handlerInstalled = false;

  /// Inicializa el handler una sola vez
  static void _initializeHandler() {
    if (!_handlerInstalled) {
      _installHandler();
      _handlerInstalled = true;
    }
  }

  /// Muestra una notificación de reproducción con controles
  static Future<void> show({
    required String title,
    required String artist,
    String? artUri,
    required bool isPlaying,
    bool showPrevious = true,
    bool showNext = true,
  }) async {
    _initializeHandler();
    try {
      await _chan.invokeMethod('show', {
        'title': title,
        'artist': artist,
        'artUri': artUri,
        'isPlaying': isPlaying,
        'showPrevious': showPrevious,
        'showNext': showNext,
      });
    } catch (e) {}
  }

  /// Actualiza la notificación con todos los parámetros
  static Future<void> update({
    required String title,
    required String artist,
    String? artUri,
    required bool isPlaying,
    bool showPrevious = true,
    bool showNext = true,
  }) async {
    _initializeHandler();
    try {
      await _chan.invokeMethod('update', {
        'title': title,
        'artist': artist,
        'artUri': artUri,
        'isPlaying': isPlaying,
        'showPrevious': showPrevious,
        'showNext': showNext,
      });
    } catch (e) {}
  }

  /// Oculta la notificación
  static Future<void> hide() async {
    try {
      await _chan.invokeMethod('hide');
    } catch (e) {}
  }
}

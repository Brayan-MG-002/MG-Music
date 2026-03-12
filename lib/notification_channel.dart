// Copyright © 2026 Brayan Medrano - MG Music
// Gestión de notificaciones del sistema para reproducción de audio

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';

/// Instala el manejador de eventos de notificación
void _installHandler() {
  if (!Platform.isAndroid) return;
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
        case 'MG_ACTION_FAVORITE':
          final current = mgr.currentSongNotifier.value;
          if (current != null) {
            await FavoritesManager().toggleFavorite(current);
          }
        case 'MG_ACTION_STOP':
          await mgr.pause();
          await NotificationChannel.hide();
      }
    }
  });
}

class NotificationChannel {
  static const MethodChannel _chan = MethodChannel('mg_music/notification');
  static bool _handlerInstalled = false;

  /// Inicializa el handler una sola vez
  static void _initializeHandler() {
    if (!Platform.isAndroid) return;
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
    required bool isFavorite,
    required bool isAdo,
    bool showPrevious = true,
    bool showNext = true,
  }) async {
    if (!Platform.isAndroid) return;
    _initializeHandler();
    try {
      await _chan.invokeMethod('show', {
        'title': title,
        'artist': artist,
        'artUri': artUri,
        'isPlaying': isPlaying,
        'isFavorite': isFavorite,
        'isAdo': isAdo,
        'showPrevious': showPrevious,
        'showNext': showNext,
      });
    } on MissingPluginException {
      debugPrint(
        'NotificationChannel.show: No implementation found for this platform.',
      );
    } catch (e) {
      debugPrint('NotificationChannel.show error: $e');
    }
  }

  /// Actualiza la notificación con todos los parámetros
  static Future<void> update({
    required String title,
    required String artist,
    String? artUri,
    required bool isPlaying,
    required bool isFavorite,
    required bool isAdo,
    bool showPrevious = true,
    bool showNext = true,
  }) async {
    if (!Platform.isAndroid) return;
    _initializeHandler();
    try {
      await _chan.invokeMethod('update', {
        'title': title,
        'artist': artist,
        'artUri': artUri,
        'isPlaying': isPlaying,
        'isFavorite': isFavorite,
        'isAdo': isAdo,
        'showPrevious': showPrevious,
        'showNext': showNext,
      });
    } on MissingPluginException {
      debugPrint(
        'NotificationChannel.update: No implementation found for this platform.',
      );
    } catch (e) {
      debugPrint('NotificationChannel.update error: $e');
    }
  }

  /// Oculta la notificación
  static Future<void> hide() async {
    if (!Platform.isAndroid) return;
    try {
      await _chan.invokeMethod('hide');
    } on MissingPluginException {
      debugPrint(
        'NotificationChannel.hide: No implementation found for this platform.',
      );
    } catch (e) {
      debugPrint('NotificationChannel.hide error: $e');
    }
  }
}

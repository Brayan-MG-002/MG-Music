// Copyright © 2026 Brayan Medrano - MG Music
// Clase stub para compatibilidad. La gestión de notificaciones se realiza ahora íntegramente en MyAudioHandler.

class NotificationChannel {
  static Future<void> show({
    String title = '',
    String artist = '',
    String? artUri,
    bool isPlaying = false,
    bool isFavorite = false,
    bool isAdo = false,
    bool showPrevious = true,
    bool showNext = true,
  }) async {}

  static Future<void> update({
    String title = '',
    String artist = '',
    String? artUri,
    bool isPlaying = false,
    bool isFavorite = false,
    bool isAdo = false,
    bool showPrevious = true,
    bool showNext = true,
  }) async {}

  static Future<void> hide() async {}
}

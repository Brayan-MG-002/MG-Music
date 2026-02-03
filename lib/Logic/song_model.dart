// Copyright © 2026 Brayan Medrano - MG Music
// Modelo de datos para una canción local

import 'dart:typed_data';

/// Representa una canción almacenada localmente en el dispositivo
class LocalSong {
  final int id;
  final String title;
  final String artist;
  final String path;
  final Uint8List? artwork;

  LocalSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    this.artwork,
  });
}

// Copyright © 2026 Brayan Medrano - MG Music
// Obtención de canciones del dispositivo

import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'song_model.dart';

/// Gestor para consultar y obtener canciones del dispositivo
class SongFetcher {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Solicita permisos de audio y almacenamiento
  Future<bool> _requestPermission() async {
    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    final audio = await Permission.audio.request();
    final storage = await Permission.storage.request();

    return audio.isGranted || storage.isGranted;
  }

  /// Obtiene todas las canciones del dispositivo con filtros
  Future<List<LocalSong>> getSongs() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return [];

    final List<LocalSong> songs = [];
    final queriedSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    for (final song in queriedSongs) {
      if (song.isMusic != true) continue;

      // Filtrar audios muy cortos (notas de voz, etc)
      if (song.duration != null && song.duration! < 30 * 1000) continue;

      // Filtrar carpetas de aplicaciones de mensajería
      final path = song.data.toLowerCase();
      if (path.contains('whatsapp') ||
          path.contains('telegram') ||
          path.contains('recordings')) {
        continue;
      }

      // Obtener artwork (portada del álbum)
      Uint8List? artwork;
      try {
        artwork = await _audioQuery.queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          size: 300,
        );
      } catch (_) {}

      songs.add(
        LocalSong(
          id: song.id,
          title: song.title,
          artist: song.artist ?? 'Artista Desconocido',
          path: song.data,
          artwork: artwork,
        ),
      );
    }

    return songs;
  }
}

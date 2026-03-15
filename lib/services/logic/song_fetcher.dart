// Copyright © 2026 Brayan Medrano - MG Music
// Obtención de canciones del dispositivo

import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mg_music/services/models/song_model.dart';

class SongFetcher {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  static List<LocalSong> _cachedSongs = [];

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
  Future<List<LocalSong>> getSongs({
    Function(List<LocalSong>)? onProgress,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedSongs.isNotEmpty) {
      if (onProgress != null) onProgress(List.from(_cachedSongs));
      return _cachedSongs;
    }

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

      if (song.duration != null && song.duration! < 30 * 1000) continue;

      final path = song.data.toLowerCase();
      if (path.contains('whatsapp') ||
          path.contains('telegram') ||
          path.contains('recordings')) {
        continue;
      }

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
          duration: song.duration,
        ),
      );

      if (songs.length == 15 && onProgress != null) {
        onProgress(List.from(songs));
      }
    }

    _cachedSongs = songs;
    return songs;
  }
}

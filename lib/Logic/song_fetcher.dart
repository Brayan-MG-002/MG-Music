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

  /// Obtiene las canciones en fragmentos (chunks) usando un Stream.
  /// Primero carga las primeras [chunkSize] canciones inmediatamente con su artwork.
  /// Luego sigue enviando bloques de [chunkSize] canciones en segundo plano.
  Stream<List<LocalSong>> getSongsStream({int chunkSize = 20}) async* {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    final queriedSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    List<LocalSong> currentChunk = [];

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

      currentChunk.add(
        LocalSong(
          id: song.id,
          title: song.title,
          artist: song.artist ?? 'Artista Desconocido',
          path: song.data,
          artwork: artwork,
        ),
      );

      // Cuando el chunk se llena, emitirlo y crear uno nuevo
      if (currentChunk.length >= chunkSize) {
        yield List.from(currentChunk);
        currentChunk.clear();

        // Pausa ligera para no congelar el Event Loop y permitir renderizado
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // Emitir cualquier canción restante
    if (currentChunk.isNotEmpty) {
      yield List.from(currentChunk);
    }
  }

  /// Método legacy reescrito (no recomendado para UI rápida, pero funcional
  /// si otras clases dependen de obtener la lista completa al instante)
  Future<List<LocalSong>> getSongs() async {
    final songs = <LocalSong>[];
    await for (final chunk in getSongsStream()) {
      songs.addAll(chunk);
    }
    return songs;
  }
}

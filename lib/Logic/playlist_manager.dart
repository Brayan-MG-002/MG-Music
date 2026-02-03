// Copyright © 2026 Brayan Medrano - MG Music
// Gestión de playlists con persistencia en SharedPreferences

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/Logic/song_model.dart';

/// Gestor singleton de playlists personalizadas del usuario
class PlaylistManager {
  static final PlaylistManager _instance = PlaylistManager._internal();
  factory PlaylistManager() => _instance;
  PlaylistManager._internal();

  final ValueNotifier<List<String>> playlistsNotifier = ValueNotifier([]);
  final Map<String, ValueNotifier<List<String>>> _playlistSongsNotifiers = {};
  final Map<String, ValueNotifier<String?>> _playlistCoverNotifiers = {};

  /// Carga las playlists guardadas
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    playlistsNotifier.value = prefs.getStringList('playlist_names') ?? [];
  }

  /// Obtiene el notificador de canciones para una playlist
  ValueNotifier<List<String>> getSongsNotifier(String playlistName) {
    if (!_playlistSongsNotifiers.containsKey(playlistName)) {
      _playlistSongsNotifiers[playlistName] = ValueNotifier([]);
      _loadPlaylistSongs(playlistName);
    }
    return _playlistSongsNotifiers[playlistName]!;
  }

  /// Obtiene el notificador de portada para una playlist
  ValueNotifier<String?> getCoverNotifier(String playlistName) {
    if (!_playlistCoverNotifiers.containsKey(playlistName)) {
      _playlistCoverNotifiers[playlistName] = ValueNotifier(null);
      _loadPlaylistCover(playlistName);
    }
    return _playlistCoverNotifiers[playlistName]!;
  }

  /// Carga las canciones de una playlist
  Future<void> _loadPlaylistSongs(String playlistName) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = prefs.getStringList('playlist_songs_$playlistName') ?? [];
    _playlistSongsNotifiers[playlistName]?.value = songs;
  }

  /// Carga la portada de una playlist
  Future<void> _loadPlaylistCover(String playlistName) async {
    final prefs = await SharedPreferences.getInstance();
    final cover = prefs.getString('playlist_cover_$playlistName');
    _playlistCoverNotifiers[playlistName]?.value = cover;
  }

  /// Crea una nueva playlist
  Future<void> createPlaylist(String name) async {
    if (name.isEmpty || playlistsNotifier.value.contains(name)) return;
    final prefs = await SharedPreferences.getInstance();
    final newList = List<String>.from(playlistsNotifier.value)..add(name);
    playlistsNotifier.value = newList;
    await prefs.setStringList('playlist_names', newList);
  }

  /// Elimina una playlist
  Future<void> deletePlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final newList = List<String>.from(playlistsNotifier.value)..remove(name);
    playlistsNotifier.value = newList;
    await prefs.setStringList('playlist_names', newList);
    await prefs.remove('playlist_songs_$name');
    await prefs.remove('playlist_cover_$name');
    _playlistSongsNotifiers.remove(name);
    _playlistCoverNotifiers.remove(name);
  }

  /// Renombra una playlist
  Future<void> renamePlaylist(String oldName, String newName) async {
    if (newName.isEmpty || playlistsNotifier.value.contains(newName)) return;
    final prefs = await SharedPreferences.getInstance();

    final songs = prefs.getStringList('playlist_songs_$oldName') ?? [];
    final cover = prefs.getString('playlist_cover_$oldName');

    await prefs.setStringList('playlist_songs_$newName', songs);
    if (cover != null) await prefs.setString('playlist_cover_$newName', cover);

    final newList = List<String>.from(playlistsNotifier.value);
    final index = newList.indexOf(oldName);
    if (index != -1) {
      newList[index] = newName;
      playlistsNotifier.value = newList;
      await prefs.setStringList('playlist_names', newList);
    }

    await prefs.remove('playlist_songs_$oldName');
    await prefs.remove('playlist_cover_$oldName');
  }

  /// Añade una canción a una playlist
  Future<void> addSongToPlaylist(String playlistName, LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSongs =
        prefs.getStringList('playlist_songs_$playlistName') ?? [];
    if (!currentSongs.contains(song.path)) {
      currentSongs.add(song.path);
      await prefs.setStringList('playlist_songs_$playlistName', currentSongs);
      _playlistSongsNotifiers[playlistName]?.value = currentSongs;
      if (currentSongs.length == 1) setPlaylistCover(playlistName, song.path);
    }
  }

  /// Elimina una canción de una playlist
  Future<void> removeSongFromPlaylist(
    String playlistName,
    String songPath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSongs =
        prefs.getStringList('playlist_songs_$playlistName') ?? [];
    if (currentSongs.remove(songPath)) {
      await prefs.setStringList('playlist_songs_$playlistName', currentSongs);
      _playlistSongsNotifiers[playlistName]?.value = currentSongs;
    }
  }

  /// Establece la portada de una playlist
  Future<void> setPlaylistCover(String playlistName, String songPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playlist_cover_$playlistName', songPath);
    _playlistCoverNotifiers[playlistName]?.value = songPath;
  }
}

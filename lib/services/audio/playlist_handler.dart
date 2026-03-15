// Copyright © 2026 Brayan Medrano - MG Music
// Lógica para el manejo de la playlist, shuffle y navegación

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mg_music/services/models/song_model.dart';

class PlaylistHandler {
  /// Lista original (orden del Home al momento de iniciar reproducción).
  List<LocalSong> _playlist = [];
  List<LocalSong> _shuffledPlaylist = [];

  bool _isShuffleMode = false;
  int _currentIndex = -1; // Index in _playlist OR _shuffledPlaylist

  bool get isShuffleMode => _isShuffleMode;

  List<LocalSong> get activePlaylist => _playlist;

  int get currentIndex => _currentIndex;

  /// Establece una nueva lista de reproducción
  void setPlaylist(List<LocalSong> newPlaylist) {
    _playlist = List.from(newPlaylist);
    _generateShuffle();
  }

  void _generateShuffle() {
    _shuffledPlaylist = List.from(_playlist)..shuffle();
  }

  /// Activa/desactiva el modo shuffle y reposiciona el índice
  void setShuffleMode(bool shuffle) {
    _isShuffleMode = shuffle;
    if (shuffle) {
      _generateShuffle();
      // Ensure current song is placed first or matched in shuffle list
      final current = this.current();
      if (current != null) {
        _shuffledPlaylist.removeWhere((s) => s.id == current.id);
        _shuffledPlaylist.insert(0, current);
        _currentIndex = 0;
      }
    } else {
      final current = this.current();
      if (current != null) {
        _currentIndex = _playlist.indexWhere((s) => s.id == current.id);
        if (_currentIndex == -1) _currentIndex = 0;
      }
    }
  }

  /// Actualiza la lista base si no hay reproducción
  void updateBasePlaylist(List<LocalSong> newList) {
    final currentSong = current();
    _playlist = List.from(newList);

    if (currentSong != null) {
      final newIndex = _playlist.indexWhere((s) => s.id == currentSong.id);
      _currentIndex = newIndex != -1 ? newIndex : 0;
    }
  }

  LocalSong? songById(int id) {
    try {
      return _playlist.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fija el índice actual según la canción dada
  void setCurrentSong(LocalSong song) {
    if (_isShuffleMode) {
      final index = _shuffledPlaylist.indexWhere((s) => s.id == song.id);
      _currentIndex = index != -1 ? index : 0;
    } else {
      final index = _playlist.indexWhere((s) => s.id == song.id);
      _currentIndex = index != -1 ? index : 0;
    }
  }

  /// Retorna la canción actual
  LocalSong? current() {
    final list = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (_currentIndex >= 0 && _currentIndex < list.length) {
      return list[_currentIndex];
    }
    return null;
  }

  /// Avanza al siguiente elemento
  LocalSong? getNext() {
    final list = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (list.isEmpty) return null;
    _currentIndex = (_currentIndex + 1) % list.length;
    return list[_currentIndex];
  }

  /// Retrocede al anterior
  LocalSong? getPrevious() {
    final list = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (list.isEmpty) return null;
    _currentIndex = (_currentIndex - 1) % list.length;
    if (_currentIndex < 0) _currentIndex = list.length - 1;
    return list[_currentIndex];
  }

  /// Va al primero
  LocalSong? getFirst() {
    final list = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (list.isEmpty) return null;
    _currentIndex = 0;
    return list[_currentIndex];
  }

  /// Va al último
  LocalSong? getLast() {
    final list = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (list.isEmpty) return null;
    _currentIndex = list.length - 1;
    return list[_currentIndex];
  }

  /// Crea una fuente de audio para una sola canción
  AudioSource createSingleSource(LocalSong song) {
    return AudioSource.file(
      song.path,
      tag: MediaItem(
        id: song.id.toString(),
        album: 'MG Music',
        title: song.title,
        artist: song.artist,
        artUri: Uri.parse(
          'content://media/external/audio/media/${song.id}/albumart',
        ),
      ),
    );
  }

  /// Obsoleto: usa createSingleSource
  AudioSource createAudioSource(LocalSong song) => createSingleSource(song);
}

// Copyright © 2026 Brayan Medrano - MG Music
// Handler para audio_service — auto-actualización sin depender del isolate de UI

import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  MyAudioHandler(this._player) {
    _configureAudioSession();

    _player.playerStateStream.listen((_) {
      try { playbackState.add(_transformEvent(_player.playbackEvent)); } catch (_) {}
    });

    _player.positionStream.listen((_) {
      try { playbackState.add(_transformEvent(_player.playbackEvent)); } catch (_) {}
    });

    _player.durationStream.listen((_) {
      try { playbackState.add(_transformEvent(_player.playbackEvent)); } catch (_) {}
    });

    AudioPlayerManager().currentSongNotifier.addListener(_onSongChanged);
    FavoritesManager().favoritePathsNotifier.addListener(_onFavoritesChanged);
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}
  }

  void _onSongChanged() {
    final song = AudioPlayerManager().currentSongNotifier.value;
    if (song != null) {
      _updateMediaItem(song);
    }
  }

  void _onFavoritesChanged() {
    final song = AudioPlayerManager().currentSongNotifier.value;
    if (song != null) {
      _updateMediaItem(song);
    }
  }

  void _updateMediaItem(LocalSong song) {
    final isFavorite = FavoritesManager().isFavorite(song);
    try {
      mediaItem.add(
        MediaItem(
          id: song.id.toString(),
          album: song.artist,
          title: song.title,
          artist: song.artist,
          duration: Duration(milliseconds: song.duration ?? 0),
          artUri: Uri.parse(
            'content://media/external/audio/media/${song.id}/albumart',
          ),
          extras: {'isFavorite': isFavorite, 'isAdo': AdoHandler.isAdo(song)},
        ),
      );
      playbackState.add(_transformEvent(_player.playbackEvent));
    } catch (_) {}
  }

  void updateMetadata(LocalSong song) {
    _updateMediaItem(song);
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } on PlatformException catch (_) {
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } on PlatformException catch (_) {
    } catch (_) {}
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } on PlatformException catch (_) {
    } catch (_) {}
  }

  @override
  Future<void> skipToNext() => AudioPlayerManager().next();

  @override
  Future<void> skipToPrevious() => AudioPlayerManager().previous();

  @override
  Future<void> stop() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    super.click(button);
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'toggleFavorite') {
      final song = AudioPlayerManager().currentSongNotifier.value;
      if (song != null) {
        await FavoritesManager().toggleFavorite(song);
        _updateMediaItem(song);
      }
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> fastForward() async {
    final song = AudioPlayerManager().currentSongNotifier.value;
    if (song != null) {
      await FavoritesManager().toggleFavorite(song);
      _updateMediaItem(song);
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final song = AudioPlayerManager().currentSongNotifier.value;
    final isFavorite = song != null
        ? FavoritesManager().isFavorite(song)
        : false;

    return PlaybackState(
      controls: [
        MediaControl(
          androidIcon: isFavorite
              ? 'drawable/ic_heart_white_24dp'
              : 'drawable/ic_heart_outline_white_24dp',
          label: 'Favorito',
          action: MediaAction.fastForward,
        ),
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl(
          androidIcon: 'drawable/ic_close_white_24dp',
          label: 'Cerrar',
          action: MediaAction.stop,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.stop,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.fastForward,
      },
      androidCompactActionIndices: const [1, 2, 3],
      processingState: () {
        switch (_player.processingState) {
          case ProcessingState.idle:
          case ProcessingState.completed:
            return AudioProcessingState.buffering;
          case ProcessingState.loading:
            return AudioProcessingState.loading;
          case ProcessingState.buffering:
            return AudioProcessingState.buffering;
          case ProcessingState.ready:
            return AudioProcessingState.ready;
        }
      }(),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> onTaskRemoved() async {
  }
}

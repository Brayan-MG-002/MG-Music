// Copyright © 2026 Brayan Medrano - MG Music
// Handler para audio_service con acciones de favorito y cerrar

import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  // Acciones personalizadas
  static const String actionFavorite = 'favorite';
  static const String actionStop = 'stop';

  MyAudioHandler(this._player) {
    _player.playbackEventStream.map(_transformEvent).listen((state) {
      playbackState.add(state);
    });

    FavoritesManager().favoritePathsNotifier.addListener(_refreshState);
  }

  void _refreshState() {
    try {
      playbackState.add(_transformEvent(_player.playbackEvent));
    } catch (_) {}
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } on PlatformException catch (_) {
      // Silenciado para evitar fallos en la UI
    } catch (_) {}
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } on PlatformException catch (_) {
      // Silenciado para evitar fallos en la UI
    } catch (_) {}
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } on PlatformException catch (_) {
      // Silenciado para evitar fallos en la UI
    } catch (_) {}
  }

  @override
  Future<void> skipToNext() => AudioPlayerManager().next();

  @override
  Future<void> skipToPrevious() => AudioPlayerManager().previous();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  /// Actualiza metadatos de la canción en la notificación
  void updateMetadata(LocalSong song) {
    final isFavorite = FavoritesManager().isFavorite(song);

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
        updateMetadata(song);
      }
    }
    return super.customAction(name, extras);
  }

  /// Mapea eventos de JustAudio a AudioService
  PlaybackState _transformEvent(PlaybackEvent event) {
    final song = AudioPlayerManager().currentSongNotifier.value;
    final isFavorite = song != null
        ? FavoritesManager().isFavorite(song)
        : false;

    return PlaybackState(
      controls: [
        // 0: FAVORITE — mapeado como fastForward con icono custom
        MediaControl(
          androidIcon: isFavorite
              ? 'drawable/ic_heart_white_24dp'
              : 'drawable/ic_heart_outline_white_24dp',
          label: 'Favorito',
          action: MediaAction.fastForward,
        ),
        // 1: PREV
        MediaControl.skipToPrevious,
        // 2: PLAY/PAUSE
        if (_player.playing) MediaControl.pause else MediaControl.play,
        // 3: NEXT
        MediaControl.skipToNext,
        // 4: STOP (X)
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
      // Vista compacta: Anterior [1], Play/Pause [2], Siguiente [3]
      androidCompactActionIndices: const [1, 2, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> fastForward() async {
    final song = AudioPlayerManager().currentSongNotifier.value;
    if (song != null) {
      await FavoritesManager().toggleFavorite(song);
      updateMetadata(song);
    }
  }
}

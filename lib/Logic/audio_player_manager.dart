// Copyright © 2026 Brayan Medrano - MG Music
// Este archivo gestiona toda la lógica de reproducción de audio

import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mg_music/notification_channel.dart';

/// Gestor centralizado de reproducción de audio con soporte para playlists,
/// shuffle, repeat, sleep timer y preferencias de usuario
class AudioPlayerManager with WidgetsBindingObserver {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;
  double _originalVolume = 1.0;

  // Constantes de configuración
  static const String _prefStartupMode = 'startup_mode';
  static const String startupAdo = 'ado';
  static const String startupLast = 'last';
  static const String _adoArtistName = 'Ado';
  static const double _adoVolumeBoost = 1.2;

  // Estado de reproducción y playlists
  List<LocalSong> _playlist = [];
  List<LocalSong> _shuffledPlaylist = [];
  final List<LocalSong> _playNextQueue = [];
  LocalSong? _currentPlayingSong;

  int _currentIndex = -1;
  DateTime _lastSaveTime = DateTime.now();
  List<LocalSong>? _cachedSongs;

  bool _isShuffleMode = false;
  bool _playingFromPlayNext = false;
  bool _isPlayingSingleSource = false;
  bool _isInitialized = false;
  bool _isManualSkip = false;
  bool _hasStartupExecuted = false;

  int? _resumeMainIndex;

  // Notificadores para la interfaz
  final ValueNotifier<LocalSong?> currentSongNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isShuffleModeNotifier = ValueNotifier(false);
  final ValueNotifier<LoopMode> loopModeNotifier = ValueNotifier(LoopMode.off);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<List<LocalSong>> activePlaylistNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<String> startupModeNotifier = ValueNotifier(startupAdo);
  final ValueNotifier<bool> showVisualizerNotifier = ValueNotifier(true);
  final ValueNotifier<int?> sleepTimerNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> sleepEndTimeNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isRestoringNotifier = ValueNotifier(false);

  // Getters públicos
  List<LocalSong> get playlist =>
      _isShuffleMode ? _shuffledPlaylist : _playlist;
  int get currentIndex => _currentIndex;
  List<LocalSong> get cachedSongs => _cachedSongs ?? [];

  /// Inicializa los listeners del reproductor y carga configuraciones guardadas
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Monitor de estado del reproductor
    _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
      unawaited(_updateNotification());
    });

    // Monitor de posición de reproducción
    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
      _throttleSavePosition(pos);
    });

    // Monitor de índice actual
    _player.sequenceStateStream.listen((state) async {
      if (state?.currentSource?.tag is! MediaItem) return;

      final mediaItem = state!.currentSource!.tag as MediaItem;
      final songId = int.tryParse(mediaItem.id);
      if (songId == null) return;

      // Evitar re-procesamiento si la canción no ha cambiado
      if (songId == _currentPlayingSong?.id) return;

      // Determinar si el cambio fue manual (next/prev) o automático (fin de canción)
      final bool wasManualSkip = _isManualSkip;
      if (_isManualSkip) {
        _isManualSkip = false; // Consumir el flag
      }

      // Si el cambio fue automático y hay una cola "reproducir después",
      // debemos anular la selección del reproductor.
      if (!wasManualSkip && _playNextQueue.isNotEmpty) {
        await _playNextQueueNext(); // Esto reproducirá la canción correcta
        return; // Salimos para evitar procesar la canción incorrecta
      }

      // Si llegamos aquí, la nueva canción es la correcta. Actualizamos el estado.
      await _updateInternalStateToSong(songId);
    });

    // Monitor de duración
    _player.durationStream.listen((dur) {
      durationNotifier.value = dur ?? Duration.zero;
    });

    // Cargar preferencias guardadas
    final prefs = await SharedPreferences.getInstance();
    startupModeNotifier.value = prefs.getString(_prefStartupMode) ?? startupAdo;
    showVisualizerNotifier.value = prefs.getBool('show_visualizer') ?? true;
  }

  /// Aplica boost de volumen para canciones del artista Ado
  Future<void> _applyAdoVolumeBoost(LocalSong song) async {
    try {
      _originalVolume = _player.volume;
      if (song.artist.toLowerCase().contains(_adoArtistName.toLowerCase())) {
        final boostedVolume = (_originalVolume * _adoVolumeBoost).clamp(
          0.0,
          1.0,
        );
        await _player.setVolume(boostedVolume);
      }
    } catch (e) {}
  }

  /// Actualiza el estado interno a una nueva canción basado en su ID
  Future<void> _updateInternalStateToSong(int songId) async {
    try {
      final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;

      // FIX: Búsqueda segura para evitar crashes si la canción no está en la lista inmediata
      LocalSong? newSong;

      // 1. Intentar en la lista activa
      try {
        newSong = activeList.firstWhere((s) => s.id == songId);
      } catch (_) {}

      // 2. Intentar en la cola de siguientes
      if (newSong == null) {
        try {
          newSong = _playNextQueue.firstWhere((s) => s.id == songId);
        } catch (_) {}
      }

      // 3. Fallback: Buscar en la otra lista (original o shuffle) por si hubo cambio de modo
      if (newSong == null) {
        final otherList = _isShuffleMode ? _playlist : _shuffledPlaylist;
        try {
          newSong = otherList.firstWhere((s) => s.id == songId);
        } catch (_) {}
      }

      // Si no se encuentra, abortar para evitar estados nulos o inconsistentes
      if (newSong == null) {
        // Imprimir siempre para depurar en release
        print("⚠️ Canción ID $songId no encontrada en listas locales.");
        return;
      }

      _currentPlayingSong = newSong;
      currentSongNotifier.value = newSong;

      // Actualizar índice si es posible
      final index = activeList.indexWhere((s) => s.id == songId);
      _currentIndex = index != -1 ? index : 0;

      await _applyAdoVolumeBoost(newSong);
      await _updateNotification();

      // Si la canción que acaba de empezar estaba en la cola, la eliminamos
      _playNextQueue.removeWhere((s) => s.id == songId);
    } catch (e) {
      // Imprimir siempre para depurar en release
      print("Error actualizando estado de canción: $e");
    }
  }

  /// Guarda la posición cada 5 segundos
  void _throttleSavePosition(Duration pos) {
    final now = DateTime.now();
    if (now.difference(_lastSaveTime).inSeconds >= 5) {
      _lastSaveTime = now;
      savePosition();
    }
  }

  /// Guarda la posición actual en SharedPreferences
  Future<void> savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_played_position',
        _player.position.inMilliseconds,
      );
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      savePosition();
    }
  }

  /// Reproduce una canción específica dentro de un contexto
  Future<void> playSong(LocalSong song, List<LocalSong> contextList) async {
    _isManualSkip = true;
    _playlist = List.from(contextList);
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    _isShuffleMode = false;
    isShuffleModeNotifier.value = false;
    _notifyActivePlaylist();
    await _playInternal(song);
  }

  /// Reproduce con efecto fade in/out
  Future<void> playWithFade(LocalSong song, List<LocalSong> contextList) async {
    final originalVolume = _player.volume;
    const steps = 20;
    const fadeDuration = Duration(milliseconds: 1000);
    final stepDuration = Duration(
      milliseconds: fadeDuration.inMilliseconds ~/ steps,
    );

    if (_player.playing) {
      for (int i = 1; i <= steps; i++) {
        final vol = originalVolume * (1 - (i / steps));
        await _player.setVolume(vol);
        await Future.delayed(stepDuration);
      }
    }

    await _player.setVolume(0);
    await playSong(song, contextList);

    for (int i = 1; i <= steps; i++) {
      final vol = originalVolume * (i / steps);
      await _player.setVolume(vol);
      await Future.delayed(stepDuration);
    }
    await _player.setVolume(originalVolume);
  }

  /// Activa modo aleatorio
  Future<void> shufflePlay(List<LocalSong> contextList) async {
    _isManualSkip = true;
    _playlist = List.from(contextList);
    _shuffledPlaylist = List.from(contextList)..shuffle();
    _isShuffleMode = true;
    _currentIndex = 0;
    isShuffleModeNotifier.value = true;
    _notifyActivePlaylist();
    if (_shuffledPlaylist.isNotEmpty) {
      await _playInternal(_shuffledPlaylist[0]);
    }
  }

  /// Actualiza la playlist sin detener la reproducción
  Future<void> updatePlaylist(List<LocalSong> newList) async {
    final current = _currentPlayingSong;
    _playlist = List.from(newList);

    if (_isShuffleMode) {
      _shuffledPlaylist = List.from(newList)..shuffle();
      if (current != null) {
        _shuffledPlaylist.removeWhere((s) => s.id == current.id);
        _shuffledPlaylist.insert(0, current);
      }
    }

    _notifyActivePlaylist();

    if (current != null && _playlist.any((s) => s.id == current.id)) {}
  }

  /// Alterna modo shuffle
  Future<void> toggleShuffleMode() async {
    _isShuffleMode = !_isShuffleMode;
    isShuffleModeNotifier.value = _isShuffleMode;

    final current = _currentPlayingSong;
    if (_isShuffleMode) {
      _shuffledPlaylist = List.from(_playlist)..shuffle();
      if (current != null) {
        _shuffledPlaylist.removeWhere((s) => s.id == current.id);
        _shuffledPlaylist.insert(0, current);
      }
    }

    _notifyActivePlaylist();

    if (current != null) {
      // Forzar la actualización de la cola en el reproductor para que el botón "Siguiente"
      // respete el nuevo orden aleatorio, pero manteniendo la posición actual de reproducción.
      await _playSongAsCurrentWithoutQueue(
        current,
        forceUpdate: true,
        initialPosition: _player.position,
      );
    }
  }

  /// Alterna el modo de repetición: Off <-> One (1-2-1-2)
  Future<void> toggleLoopMode() async {
    if (loopModeNotifier.value == LoopMode.off) {
      await setLoopMode(LoopMode.one);
    } else {
      await setLoopMode(LoopMode.off);
    }
  }

  /// Establece el modo de repetición
  Future<void> setLoopMode(LoopMode mode) async {
    loopModeNotifier.value = mode;
    await _player.setLoopMode(mode);
  }

  /// Añade una canción a la cola de reproducción siguiente
  void addNext(LocalSong song) {
    _playNextQueue.removeWhere((s) => s.id == song.id);
    _playNextQueue.add(song);
    _notifyActivePlaylist();
  }

  /// Pasa a la siguiente canción
  Future<void> next() async {
    _isManualSkip = true;
    if (_playNextQueue.isNotEmpty) {
      if (!_playingFromPlayNext) {
        _resumeMainIndex = _playlist.indexWhere(
          (s) => s.id == _currentPlayingSong?.id,
        );
        _playingFromPlayNext = true;
      }
      await _playNextQueueNext();
      return;
    }

    if (_playingFromPlayNext) {
      _playingFromPlayNext = false;
      final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;
      if (activeList.isEmpty) return;
      var nextIdx = (_resumeMainIndex ?? -1) + 1;
      _resumeMainIndex = null;
      if (nextIdx >= activeList.length) nextIdx = 0;
      _currentIndex = nextIdx;
      await _playSongAsCurrentWithoutQueue(activeList[nextIdx]);
      return;
    }

    final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (activeList.isEmpty) return;

    try {
      // Usar skipToNext() directamente si tenemos una ConcatenatingAudioSource
      if (_player.hasNext) {
        await _player.seekToNext();
      } else {
        // Fallback: reconstruir si es necesario
        final currentIdx = activeList.indexWhere(
          (s) => s.id == _currentPlayingSong?.id,
        );
        if (currentIdx != -1) {
          var nextIdx = currentIdx + 1;
          if (nextIdx >= activeList.length) {
            if (loopModeNotifier.value == LoopMode.all) {
              nextIdx = 0;
            } else {
              return;
            }
          }
          _currentIndex = nextIdx;
          await _playSongAsCurrentWithoutQueue(activeList[nextIdx]);
        }
      }
    } catch (e) {}
  }

  /// Pasa a la canción anterior
  Future<void> previous() async {
    _isManualSkip = true;
    final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;
    if (activeList.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    try {
      // Usar skipToPrevious() directamente si tenemos una ConcatenatingAudioSource
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      } else {
        // Fallback: reconstruir si es necesario
        final currentIdx = activeList.indexWhere(
          (s) => s.id == _currentPlayingSong?.id,
        );
        if (currentIdx <= 0) {
          if (loopModeNotifier.value == LoopMode.all) {
            _currentIndex = activeList.length - 1;
            await _playSongAsCurrentWithoutQueue(activeList[_currentIndex]);
          }
        } else {
          _currentIndex = currentIdx - 1;
          await _playSongAsCurrentWithoutQueue(activeList[_currentIndex]);
        }
      }
    } catch (e) {}
  }

  /// Establece el modo de inicio
  Future<void> setStartupMode(String mode) async {
    startupModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefStartupMode, mode);
  }

  /// Alterna la visibilidad del visualizador
  Future<void> toggleVisualizer(bool value) async {
    showVisualizerNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_visualizer', value);
  }

  /// Establece el temporizador de sueño
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();

    if (minutes <= 0) {
      sleepTimerNotifier.value = null;
      sleepEndTimeNotifier.value = null;
      return;
    }

    sleepTimerNotifier.value = minutes;
    final duration = Duration(minutes: minutes);
    sleepEndTimeNotifier.value = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _fadeOutAndPause();
    });
  }

  /// Baja el volumen gradualmente y pausa la reproducción
  Future<void> _fadeOutAndPause() async {
    final originalVolume = _player.volume;
    const steps = 20;
    const fadeDuration = Duration(seconds: 4);
    final stepDuration = Duration(
      milliseconds: fadeDuration.inMilliseconds ~/ steps,
    );

    for (int i = 1; i <= steps; i++) {
      if (!_player.playing) break;
      final newVolume = originalVolume * (1 - (i / steps));
      await _player.setVolume(newVolume);
      await Future.delayed(stepDuration);
    }

    await pause();
    sleepTimerNotifier.value = null;
    sleepEndTimeNotifier.value = null;
    await _player.setVolume(originalVolume);
  }

  /// Ejecuta el comportamiento de inicio según configuración
  Future<void> executeStartupBehavior(List<LocalSong> allSongs) async {
    if (_hasStartupExecuted) {
      isRestoringNotifier.value = false;
      return;
    }
    if (allSongs.isEmpty) {
      isRestoringNotifier.value = false;
      return;
    }

    _cachedSongs = allSongs;
    final mode = startupModeNotifier.value;
    LocalSong? songToLoad;
    Duration startPos = Duration.zero;

    if (mode == startupLast) {
      final prefs = await SharedPreferences.getInstance();
      final lastPath = prefs.getString('last_played_path');
      final lastPos = prefs.getInt('last_played_position') ?? 0;

      if (lastPath != null) {
        try {
          songToLoad = allSongs.firstWhere((s) => s.path == lastPath);
          startPos = Duration(milliseconds: lastPos);
        } catch (_) {
          // Fallback a Ado si la canción no existe
        }
      }
    } else if (mode == startupAdo) {
      final adoSongs = allSongs
          .where((s) => s.artist.toLowerCase().contains('ado'))
          .toList();
      songToLoad = adoSongs.isNotEmpty
          ? adoSongs[Random().nextInt(adoSongs.length)]
          : allSongs.first;
      startPos = Duration.zero;
    }

    if (songToLoad != null) {
      await setSong(songToLoad, play: false, initialPosition: startPos);
    }
    _hasStartupExecuted = true;
    isRestoringNotifier.value = false;
    _cachedSongs = null; // Liberar la memoria del caché de canciones
  }

  /// Reproducción interna de una canción
  Future<void> _playInternal(LocalSong song) async {
    _isManualSkip = true;
    try {
      _currentPlayingSong = song;
      currentSongNotifier.value = song;
      await _playSongAsCurrentWithoutQueue(song, forceUpdate: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_path', song.path);
      await prefs.setInt('last_played_position', 0);

      // Mostrar notificación inmediatamente
      await _updateNotification();
    } catch (e) {}
  }

  /// Reproduce una canción CON la cola completa para que la notificación vea siguiente/anterior
  Future<void> _playSongAsCurrentWithoutQueue(
    LocalSong song, {
    bool forceUpdate = false,
    Duration? initialPosition,
  }) async {
    try {
      _currentPlayingSong = song;
      currentSongNotifier.value = song;
      _isPlayingSingleSource = false;

      // Crear fuente de audio para la canción actual
      final currentSource = AudioSource.file(
        song.path,
        tag: MediaItem(
          id: song.id.toString(),
          album: "MG Music",
          title: song.title,
          artist: song.artist,
          artUri: Uri.parse(
            "content://media/external/audio/media/${song.id}/albumart",
          ),
        ),
      );

      // Obtener la playlist activa
      final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;
      final currentIdx = activeList.indexWhere((s) => s.id == song.id);

      // Construir lista de fuentes de audio (actual + próximas)
      final sources = <AudioSource>[];

      if (currentIdx != -1) {
        // Agregar la canción actual y todas las siguientes
        for (int i = currentIdx; i < activeList.length; i++) {
          final s = activeList[i];
          sources.add(
            AudioSource.file(
              s.path,
              tag: MediaItem(
                id: s.id.toString(),
                album: "MG Music",
                title: s.title,
                artist: s.artist,
                artUri: Uri.parse(
                  "content://media/external/audio/media/${s.id}/albumart",
                ),
              ),
            ),
          );
        }
      } else {
        // Si no está en la lista, solo agregar la canción actual
        sources.add(currentSource);
      }

      // Crear ConcatenatingAudioSource con todas las canciones
      final concatenatingSource = ConcatenatingAudioSource(children: sources);

      // Verificar si ya hay algo reproduciéndose
      final isCurrentlyPlaying = _player.playing;
      final currentPosition = _player.position;

      // Si la canción actual es la misma que ya está sonando, no reiniciar
      if (!forceUpdate &&
          _player.currentIndex != null &&
          currentIdx != -1 &&
          _player.currentIndex! == (currentIdx)) {
        await _updateNotification();
        return;
      }

      await _player.setAudioSource(
        concatenatingSource,
        initialIndex: currentIdx != -1 ? 0 : 0,
        initialPosition: initialPosition,
      );

      if (isCurrentlyPlaying) {
        await _player.play();
      }

      await _applyAdoVolumeBoost(song);
      await _updateNotification();
    } catch (e) {}
  }

  /// Carga una canción sin reproducir
  Future<void> setSong(
    LocalSong song, {
    bool play = false,
    Duration? initialPosition,
  }) async {
    _isManualSkip = true;
    try {
      _currentPlayingSong = song;
      currentSongNotifier.value = song;

      final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;
      _currentIndex = activeList.indexWhere((s) => s.id == song.id);

      final sources = <AudioSource>[];
      if (_currentIndex != -1) {
        for (int i = _currentIndex; i < activeList.length; i++) {
          final s = activeList[i];
          sources.add(
            AudioSource.file(
              s.path,
              tag: MediaItem(
                id: s.id.toString(),
                album: "MG Music",
                title: s.title,
                artist: s.artist,
                artUri: Uri.parse(
                  "content://media/external/audio/media/${s.id}/albumart",
                ),
              ),
            ),
          );
        }
      } else {
        // Canción no está en la lista, agregar solo
        sources.add(
          AudioSource.file(
            song.path,
            tag: MediaItem(
              id: song.id.toString(),
              album: "MG Music",
              title: song.title,
              artist: song.artist,
              artUri: Uri.parse(
                "content://media/external/audio/media/${song.id}/albumart",
              ),
            ),
          ),
        );
      }

      final concatenatingSource = ConcatenatingAudioSource(children: sources);
      _isPlayingSingleSource = false;
      await _player.setAudioSource(concatenatingSource, initialIndex: 0);

      if (initialPosition != null) await _player.seek(initialPosition);
      if (play) {
        await _player.play();
        await _applyAdoVolumeBoost(song);
      }

      // Actualizar notificación
      await _updateNotification();
    } catch (e) {}
  }

  /// Reproduce el siguiente item de la cola especial
  Future<void> _playNextQueueNext() async {
    _isManualSkip = true;
    if (_playNextQueue.isEmpty) return;
    final nextSong = _playNextQueue.removeAt(0);
    try {
      await _playSongAsCurrentWithoutQueue(nextSong);
      _notifyActivePlaylist();
    } catch (e) {}
  }

  /// Actualiza la notificación del sistema con controles de navegación
  Future<void> _updateNotification() async {
    try {
      final song = currentSongNotifier.value;
      final playing = isPlayingNotifier.value;

      if (song != null) {
        // Por defecto, siempre mostrar los botones
        // Solo ocultarlos en casos muy específicos
        bool showPrevious = true;
        bool showNext = true;

        final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;

        if (activeList.isNotEmpty) {
          final currentIdx = activeList.indexWhere((s) => s.id == song.id);

          if (currentIdx != -1) {
            // Si encontramos la canción actual en la lista
            showPrevious = currentIdx > 0;
            showNext =
                currentIdx < activeList.length - 1 ||
                loopModeNotifier.value == LoopMode.all ||
                _playNextQueue.isNotEmpty;
          } else {
            // Si no encontramos la canción en la lista (puede pasar durante reconstrucciones)
            // Mostrar los botones siempre por seguridad
            showPrevious = true;
            showNext = true;
          }
        }

        // Enviar datos al canal nativo
        await NotificationChannel.show(
          title: song.title,
          artist: song.artist,
          artUri: "content://media/external/audio/media/${song.id}/albumart",
          isPlaying: playing,
          showPrevious: showPrevious,
          showNext: showNext,
        );
      }
    } catch (e, stackTrace) {}
  }

  /// Busca a una posición específica
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Inicia la reproducción
  Future<void> play() async {
    await _player.play();
    await _updateNotificationState();
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    await _player.pause();
    await _updateNotificationState();
  }

  /// Alterna entre reproducción y pausa
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Actualiza solo el estado de reproducción en la notificación
  Future<void> _updateNotificationState() async {
    try {
      final song = currentSongNotifier.value;
      final playing = isPlayingNotifier.value;

      if (song != null) {
        bool showPrevious = true;
        bool showNext = true;

        final activeList = _isShuffleMode ? _shuffledPlaylist : _playlist;
        if (activeList.isNotEmpty) {
          final currentIdx = activeList.indexWhere((s) => s.id == song.id);
          if (currentIdx != -1) {
            showPrevious = currentIdx > 0;
            showNext =
                currentIdx < activeList.length - 1 ||
                loopModeNotifier.value == LoopMode.all ||
                _playNextQueue.isNotEmpty;
          }
        }

        // Usar _updateNotification para asegurar que se muestre (show) y no solo actualice
        await _updateNotification();
      }
    } catch (e) {}
  }

  /// Notifica cambios en la playlist
  void _notifyActivePlaylist() {
    activePlaylistNotifier.value = List.from(playlist);
  }

  /// Libera recursos
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
  }
}

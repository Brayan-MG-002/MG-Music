// Copyright © 2026 Brayan Medrano - MG Music
// Gestor centralizado de reproducción — v2 con autoavance correcto

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/audio/playback_handler.dart';
import 'package:mg_music/services/audio/playlist_handler.dart';
import 'package:mg_music/services/audio/audio_handler.dart';
import 'package:mg_music/services/audio/state_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/errors/error_service.dart';

class AudioPlayerManager with WidgetsBindingObserver {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  final AudioPlayer _player = AdoHandler.buildPlayer();
  late final PlaybackHandler _playbackHandler;
  late final PlaylistHandler _playlistHandler;
  late final StateManager _stateManager;
  late final AdoHandler _adoHandler;
  MyAudioHandler? _audioHandler;

  bool _isInitialized = false;

  /// true mientras haya una canción activa (protege la lista interna de
  /// ser sobrescrita por cambios de filtro/orden del Home).
  bool _playlistLocked = false;

  /// Bloqueo anti-concurrencia para eventos de terminación nativa
  bool _isHandlingCompletion = false;

  final Queue<LocalSong> _nextQueue = Queue<LocalSong>();

  DateTime _lastSaveTime = DateTime.now();

  // Anti-pasmo para hardware decoders muertos
  Timer? _watchdogTimer;
  Duration _lastWatchdogPos = Duration.zero;
  int _watchdogStallCount = 0;
  List<LocalSong>? _cachedSongs;
  
  /// Contador de reintentos para errores de fuente (Source Error)
  int _playRetryCount = 0;

  // Constantes para compatibilidad con UI existente
  static const String startupAdo = StateManager.startupAdo;
  static const String startupLast = StateManager.startupLast;

  // ── Notificadores para la interfaz ────────────────────────────────────────
  final ValueNotifier<LocalSong?> currentSongNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isShuffleModeNotifier = ValueNotifier(false);
  final ValueNotifier<LoopMode> loopModeNotifier = ValueNotifier(LoopMode.off);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<List<LocalSong>> activePlaylistNotifier = ValueNotifier(
    [],
  );
  final ValueNotifier<String> startupModeNotifier = ValueNotifier(
    StateManager.startupAdo,
  );
  final ValueNotifier<bool> showVisualizerNotifier = ValueNotifier(true);
  final ValueNotifier<int?> sleepTimerNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> sleepEndTimeNotifier = ValueNotifier(null);
  final ValueNotifier<bool> isRestoringNotifier = ValueNotifier(false);
  // ── AdoBoost ──────────────────────────────────────────────────────────────
  final ValueNotifier<bool> adoBoostEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<double> adoBoostLevelNotifier = ValueNotifier(
    AdoHandler.defaultBoostLevel,
  );

  // ── Getters ───────────────────────────────────────────────────────────────
  List<LocalSong> get playlist => _playlistHandler.activePlaylist;
  int get currentIndex => _playlistHandler.currentIndex;
  List<LocalSong> get cachedSongs => _cachedSongs ?? [];
  AudioPlayer get player => _player;

  AudioPlayerManager._internal() {
    WidgetsBinding.instance.addObserver(this);
    _playbackHandler = PlaybackHandler(_player);
    _playlistHandler = PlaylistHandler();
    _stateManager = StateManager();
    _adoHandler = AdoHandler();
  }

  /// Establece el manejador de metadatos/acciones del sistema
  void setAudioHandler(MyAudioHandler handler) {
    _audioHandler = handler;
  }

  /// Inicializa preferencias, listeners y watchdog
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _stateManager.loadPreferences();
    startupModeNotifier.value = _stateManager.startupMode;
    showVisualizerNotifier.value = _stateManager.showVisualizer;
    isShuffleModeNotifier.value = _playlistHandler.isShuffleMode;
    loopModeNotifier.value = _player.loopMode;

    adoBoostEnabledNotifier.value = await AdoHandler.getBoostEnabled();
    adoBoostLevelNotifier.value = await AdoHandler.getBoostLevel();

    _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;

      if (state.processingState == ProcessingState.completed) {
        if (!_isHandlingCompletion) unawaited(_handleSongCompleted());
      } else if (!state.playing &&
          state.processingState == ProcessingState.ready) {
        final durMs = durationNotifier.value.inMilliseconds;
        final posMs = positionNotifier.value.inMilliseconds;
        if (durMs > 0 && posMs > 0 && posMs >= durMs - 1000) {
          if (!_isHandlingCompletion) {
            unawaited(_handleSongCompleted());
          }
        }
      }

      unawaited(_updateNotification());
    });

    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      final isPlaying = isPlayingNotifier.value;
      if (isPlaying && !_isHandlingCompletion) {
        final currentPos = positionNotifier.value;
        final durMs = durationNotifier.value.inMilliseconds;

        if (currentPos == _lastWatchdogPos) {
          _watchdogStallCount++;
          if (_watchdogStallCount >= 2 &&
              durMs > 0 &&
              currentPos.inMilliseconds >= durMs - 1500) {
            _watchdogStallCount = 0;
            unawaited(_handleSongCompleted());
          }
        } else {
          _watchdogStallCount = 0;
          _lastWatchdogPos = currentPos;
        }
      } else {
        _watchdogStallCount = 0;
      }
    });

    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
      _throttleSavePosition(pos);

      final durMs = durationNotifier.value.inMilliseconds;
      final posMs = pos.inMilliseconds;
      if (durMs > 0 && posMs > 0 && posMs >= durMs - 400) {
        if (!_isHandlingCompletion) {
          unawaited(_handleSongCompleted());
        }
      }
    });

    _player.durationStream.listen((dur) {
      durationNotifier.value = dur ?? Duration.zero;
    });
  }

  /// Reproduce una canción y bloquea la lista activa
  Future<void> playSong(LocalSong song, [List<LocalSong>? contextList]) async {
    await _saveCurrentPositionIfPlaying();

    if (loopModeNotifier.value == LoopMode.one) {
      await setLoopMode(LoopMode.off);
    }

    if (contextList != null && contextList != _playlistHandler.activePlaylist) {
      _playlistHandler.setPlaylist(contextList);
      if (isShuffleModeNotifier.value) {
        _playlistHandler.setShuffleMode(true);
      }
    }

    _playlistHandler.setCurrentSong(song);

    _playlistLocked = true;
    await _playInternal(song);
  }

  /// Reproduce en modo aleatorio desde una lista de contexto
  Future<void> shufflePlay(List<LocalSong> contextList) async {
    await _saveCurrentPositionIfPlaying();

    _playlistHandler.setPlaylist(contextList);

    _playlistHandler.setShuffleMode(true);
    isShuffleModeNotifier.value = true;
    _playlistLocked = true;

    final activeList = _playlistHandler.activePlaylist;
    if (activeList.isNotEmpty) {
      final firstSong = _playlistHandler.getFirst();
      if (firstSong != null) {
        await _playInternal(firstSong);
      }
    }
  }

  Future<void> playWithFade(
    LocalSong song, [
    List<LocalSong>? contextList,
  ]) async {
    await _playbackHandler.playWithFade(() => playSong(song, contextList));
  }

  /// Actualiza la lista base si no hay reproducción activa
  Future<void> updatePlaylist(List<LocalSong> newList) async {
    if (_playlistLocked) return;
    _playlistHandler.updateBasePlaylist(newList);
    _notifyActivePlaylist();
  }

  /// Activa/desactiva el modo aleatorio
  Future<void> toggleShuffleMode() async {
    final isShuffle = !isShuffleModeNotifier.value;
    isShuffleModeNotifier.value = isShuffle;
    _playlistHandler.setShuffleMode(isShuffle);

    _notifyActivePlaylist();
    unawaited(_updateNotification());
  }

  /// Alterna entre repetir uno y sin repetir
  Future<void> toggleLoopMode() async {
    final newMode = loopModeNotifier.value == LoopMode.off
        ? LoopMode.one
        : LoopMode.off;
    await setLoopMode(newMode);
  }

  /// Establece el modo de repetición nativo
  Future<void> setLoopMode(LoopMode mode) async {
    try {
      loopModeNotifier.value = mode;
      final nativeMode = (mode == LoopMode.one) ? LoopMode.off : mode;
      await _playbackHandler.setLoopMode(nativeMode);
    } on PlatformException catch (_) {
      // Ignorar abortos y errores de estado en re-aplicación de modo
    } catch (_) {}
  }

  /// Inserta una canción para reproducirla a continuación
  void addNext(LocalSong song) {
    _nextQueue.addFirst(song);
    unawaited(_updateNotification());
  }

  /// Avanza a la siguiente canción respetando cola y modos
  Future<void> next() async {
    if (loopModeNotifier.value == LoopMode.one) {
      await setLoopMode(LoopMode.off);
    }

    if (_nextQueue.isNotEmpty) {
      final queuedSong = _nextQueue.removeFirst();
      await playSong(queuedSong);
      return;
    }

    final nextSong = _playlistHandler.getNext();
    if (nextSong != null) {
      await playSong(nextSong);
    } else if (loopModeNotifier.value == LoopMode.all) {
      final first = _playlistHandler.getFirst();
      if (first != null) {
        await playSong(first);
      }
    }
  }

  /// Retrocede a la canción anterior o reinicia la actual
  Future<void> previous() async {
    if (loopModeNotifier.value == LoopMode.one) {
      await setLoopMode(LoopMode.off);
    }

    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevSong = _playlistHandler.getPrevious();
    if (prevSong != null) {
      await playSong(prevSong);
    } else if (loopModeNotifier.value == LoopMode.all) {
      final last = _playlistHandler.getLast();
      if (last != null) {
        await playSong(last);
      }
    }
  }

  /// Busca una posición en la pista actual
  Future<void> seek(Duration position) async =>
      await _playbackHandler.seek(position);
  /// Reanuda la reproducción
  Future<void> play() async => await _playbackHandler.play();
  /// Pausa la reproducción
  Future<void> pause() async => await _playbackHandler.pause();
  /// Alterna entre reproducir y pausar
  Future<void> togglePlayPause() async =>
      _player.playing ? await pause() : await play();

  /// Define el modo de inicio de la app
  Future<void> setStartupMode(String mode) async {
    await _stateManager.setStartupMode(mode);
    startupModeNotifier.value = mode;
  }

  /// Habilita/deshabilita el visualizador de música
  Future<void> toggleVisualizer(bool value) async {
    await _stateManager.toggleVisualizer(value);
    showVisualizerNotifier.value = value;
  }

  /// Configura el temporizador de reposo en minutos
  void setSleepTimer(int minutes) {
    if (minutes <= 0) {
      _playbackHandler.cancelSleepTimer();
      sleepTimerNotifier.value = null;
      sleepEndTimeNotifier.value = null;
      return;
    }
    sleepTimerNotifier.value = minutes;
    sleepEndTimeNotifier.value = DateTime.now().add(Duration(minutes: minutes));
    _playbackHandler.setSleepTimer(minutes, _fadeOutAndPause);
  }

  /// Pausa al finalizar la canción actual (una sola vez)
  void setSleepAtEndOfSong() {
    sleepTimerNotifier.value = -1;
    sleepEndTimeNotifier.value = null;
  }

  /// Maneja el fin de pista y decide el siguiente paso
  Future<void> _handleSongCompleted() async {
    if (_isHandlingCompletion) return;
    _isHandlingCompletion = true;
    try {
      try {
        await pause();
      } catch (_) {}

      if (sleepTimerNotifier.value == -1) {
        sleepTimerNotifier.value = null;
        sleepEndTimeNotifier.value = null;
        await seek(Duration.zero);
        return;
      }

      if (loopModeNotifier.value == LoopMode.one) {
        await setLoopMode(LoopMode.off);
        await seek(Duration.zero);
        await play();
        return;
      }

      if (_nextQueue.isNotEmpty) {
        final manualNext = _nextQueue.removeFirst();
        await playSong(manualNext);
        return;
      }

      final nextSong = _playlistHandler.getNext();
      if (nextSong != null) {
        await playSong(nextSong);
      } else if (loopModeNotifier.value == LoopMode.all) {
        final first = _playlistHandler.getFirst();
        if (first != null) {
          await playSong(first);
        }
      } else {
        try {
          await pause();
        } catch (_) {}
        await seek(Duration.zero);
      }
    } on PlatformException catch (e) {
      if (e.code != 'abort') {
        unawaited(
          ErrorService().handleAudioError(
            error: e,
            song: currentSongNotifier.value,
          ),
        );
      }
    } catch (e) {
      unawaited(
        ErrorService().handleAudioError(
          error: e,
          song: currentSongNotifier.value,
        ),
      );
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isHandlingCompletion = false;
    }
  }

  /// Reduce volumen gradualmente y pausa
  Future<void> _fadeOutAndPause() async {
    await _playbackHandler.fadeOutAndPause();
    sleepTimerNotifier.value = null;
    sleepEndTimeNotifier.value = null;
  }

  /// Activa o desactiva el AdoBoost globalmente
  Future<void> setAdoBoostEnabled(bool enabled) async {
    adoBoostEnabledNotifier.value = enabled;
    await AdoHandler.setBoostEnabled(enabled);
    final current = currentSongNotifier.value;
    if (current != null) {
      unawaited(
        _adoHandler.applyAdoVolumeBoost(
          _player,
          current,
          1.0,
          boostEnabled: enabled,
          boostLevel: adoBoostLevelNotifier.value,
        ),
      );
    }
  }

  /// Cambia y persiste el nivel de AdoBoost
  Future<void> setAdoBoostLevel(double level) async {
    final clamped = level.clamp(1.0, 1.5);
    adoBoostLevelNotifier.value = clamped;
    await AdoHandler.setBoostLevel(clamped);
    final current = currentSongNotifier.value;
    if (current != null && adoBoostEnabledNotifier.value) {
      unawaited(
        _adoHandler.applyAdoVolumeBoost(
          _player,
          current,
          1.0,
          boostEnabled: true,
          boostLevel: clamped,
        ),
      );
    }
  }

  /// Ejecuta el comportamiento de inicio (restaurar o elegir Ado)
  Future<void> executeStartupBehavior(List<LocalSong> allSongs) async {
    isRestoringNotifier.value = true;
    _cachedSongs = allSongs;
    final startup = await _stateManager.getStartupSong(allSongs);
    if (startup != null) {
      await setSong(
        startup['song'],
        play: false,
        initialPosition: startup['position'],
      );
    }
    isRestoringNotifier.value = false;
    _cachedSongs = null;
  }

  /// Reproduce internamente una canción y actualiza estado
  Future<void> _playInternal(
    LocalSong song, {
    bool keepPosition = false,
  }) async {
    final initialPosition = keepPosition ? _player.position : Duration.zero;

    currentSongNotifier.value = song;
    _playlistHandler.setCurrentSong(song);
    _notifyActivePlaylist();

    unawaited(_stateManager.saveLastPlayedSong(song));

    try {
      final source = _playlistHandler.createSingleSource(song);
      await _player.setAudioSource(source, initialPosition: initialPosition);

      unawaited(
        _adoHandler.applyAdoVolumeBoost(
          _player,
          song,
          1.0,
          boostEnabled: adoBoostEnabledNotifier.value,
          boostLevel: adoBoostLevelNotifier.value,
        ),
      );

      _audioHandler?.updateMetadata(song);
      await _player.play();

      unawaited(_updateNotification());
    } on PlatformException catch (e) {
      if (e.code != 'abort') {
        await _handlePlaybackError(e, song);
      }
    } catch (e) {
      await _handlePlaybackError(e, song);
    }
  }

  /// Maneja errores de reproducción con reintentos globales (3 veces) y autoavance
  Future<void> _handlePlaybackError(Object error, LocalSong song) async {
    // 0. Filtrar errores de aborto/interrupción (no son errores reales para el usuario)
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('abort') || errorStr.contains('interrupted')) {
      return;
    }

    // 0.1 Detectar archivos eliminados o inaccesibles (No reintentar, avanzar directo)
    final isMissingFile = errorStr.contains('filenotfound') || 
                          errorStr.contains('enoent') || 
                          errorStr.contains('source error') || // El "Source error" persistente suele ser fatal
                          (error is PlatformException && (error.code == 'file_not_found' || error.code == '0'));

    if (isMissingFile) {
      debugPrint('📂 Archivo no encontrado. Saltando reintentos y avanzando.');
      _playRetryCount = 0;
      unawaited(ErrorService().handleAudioError(error: error, song: song));
      
      await Future.delayed(const Duration(milliseconds: 2000));
      await next();
      return;
    }

    // 1. Reintento silencioso (cualquier error)
    if (_playRetryCount < 3) {
      _playRetryCount++;
      debugPrint('⚠️ Error de reproducción detectado. Reintentando... ($_playRetryCount/3)');
      
      // Pequeño delay de recuperación para hardware/red
      await Future.delayed(const Duration(milliseconds: 1200));
      return _playInternal(song);
    }

    // 2. Fallo total tras 3 intentos
    _playRetryCount = 0; // Reset para la siguiente canción
    debugPrint('❌ Fallo persistente tras 3 reintentos. Mostrando reporte.');

    // Notificamos al servicio de errores (esto muestra el modal)
    unawaited(
      ErrorService().handleAudioError(
        error: error,
        song: song,
      ),
    );

    // 3. Auto-avance (Safe-Skip)
    // Esperamos 2.5 segundos para que la UI respire y el usuario procese el modal
    await Future.delayed(const Duration(milliseconds: 2500));
    await next();
  }

  /// Fija la canción actual sin reproducir obligatoriamente
  Future<void> setSong(
    LocalSong song, {
    bool play = false,
    Duration? initialPosition,
  }) async {
    _updateInternalStateToSong(song);
    _notifyActivePlaylist();

    try {
      final source = _playlistHandler.createSingleSource(song);
      await _player.setAudioSource(source, initialPosition: initialPosition);

      if (play) await _player.play();
    } on PlatformException catch (e) {
      if (e.code != 'abort') {
        await _handlePlaybackError(e, song);
      }
    } catch (e) {
      await _handlePlaybackError(e, song);
    }
  }

  /// Sincroniza estado interno con una canción
  void _updateInternalStateToSong(LocalSong song) {
    currentSongNotifier.value = song;
    _playlistHandler.setCurrentSong(song);
    _adoHandler.applyAdoVolumeBoost(_player, song, 1.0);
    _audioHandler?.updateMetadata(song);
    unawaited(_updateNotification());
  }

  /// Guarda la posición de la pista actual si está sonando
  Future<void> _saveCurrentPositionIfPlaying() async {
    if (currentSongNotifier.value != null && _player.playing) {
      await _stateManager.savePosition(_player.position);
      await _stateManager.savePositionFor(currentSongNotifier.value!, _player.position);
    }
  }

  /// Guarda la posición actual sin condiciones
  Future<void> savePosition() async {
    await _stateManager.savePosition(_player.position);
    final song = currentSongNotifier.value;
    if (song != null) {
      await _stateManager.savePositionFor(song, _player.position);
    }
  }

  /// Ahorra escrituras guardando posición cada ~2s
  void _throttleSavePosition(Duration pos) {
    if (DateTime.now().difference(_lastSaveTime).inSeconds >= 2) {
      _lastSaveTime = DateTime.now();
      unawaited(savePosition());
    }
  }

  /// Actualiza la notificación del sistema (si aplica)
  Future<void> _updateNotification() async {
  }

  /// Fuerza un refresco de la notificación
  Future<void> refreshNotification() async {
    await _updateNotification();
  }

  /// Emite la playlist activa a la UI
  void _notifyActivePlaylist() {
    activePlaylistNotifier.value = List.from(_playlistHandler.activePlaylist);
  }

  @override
  /// Guarda posición en estados de pausa/inactividad
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(savePosition());
    }
  }

  /// Libera recursos y observadores
  void dispose() {
    _watchdogTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
  }
}

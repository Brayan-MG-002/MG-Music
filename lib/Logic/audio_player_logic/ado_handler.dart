// Copyright © 2026 Brayan Medrano - MG Music
// Lógica para el manejo especial de canciones de Ado — con AdoBoost.

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:just_audio/just_audio.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdoHandler {
  static const String _adoArtistName = 'Ado';
  static const String _prefBoostEnabled = 'ado_boost_enabled';
  static const String _prefBoostLevel = 'ado_boost_level';
  static const double defaultBoostLevel = 1.2;

  // Loudness enhancer (solo Android)
  static AndroidLoudnessEnhancer? _loudnessEnhancer;

  /// Crea el AudioPlayer con LoudnessEnhancer en Android
  static AudioPlayer buildPlayer() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _loudnessEnhancer = AndroidLoudnessEnhancer();
      return AudioPlayer(
        audioPipeline: AudioPipeline(androidAudioEffects: [_loudnessEnhancer!]),
      );
    }
    return AudioPlayer();
  }

  /// Obtiene si el boost está habilitado
  static Future<bool> getBoostEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefBoostEnabled) ?? true;
  }

  /// Obtiene el nivel actual de boost
  static Future<double> getBoostLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefBoostLevel) ?? defaultBoostLevel;
  }

  /// Guarda si el boost está habilitado
  static Future<void> setBoostEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBoostEnabled, enabled);
  }

  /// Guarda el nivel de boost (clamp 1.0–1.5)
  static Future<void> setBoostLevel(double level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefBoostLevel, level.clamp(1.0, 1.5));
  }

  /// Convierte multiplicador (1.0–2.0) a dB (0–12 dB)
  static double _levelToDb(double level) => (level - 1.0) * 12.0;

  /// Determina si el nombre de artista contiene “Ado”
  static bool isAdoString(String artistName) {
    final regex = RegExp(r'\b' + _adoArtistName + r'\b', caseSensitive: false);
    return regex.hasMatch(artistName);
  }

  /// Determina si una canción es de Ado
  static bool isAdo(LocalSong song) {
    return isAdoString(song.artist);
  }

  /// Aplica/restaura AdoBoost según plataforma y configuración
  Future<void> applyAdoVolumeBoost(
    AudioPlayer player,
    LocalSong song,
    double originalVolume, {
    bool boostEnabled = true,
    double boostLevel = defaultBoostLevel,
  }) async {
    try {
      final isAdoSong = isAdo(song);

      final shouldBoost = isAdoSong && boostEnabled;

      if (defaultTargetPlatform == TargetPlatform.android &&
          _loudnessEnhancer != null) {
        // Android: usar LoudnessEnhancer para superar el límite de volumen
        if (shouldBoost) {
          final gainDb = _levelToDb(boostLevel);
          await _loudnessEnhancer!.setEnabled(true);
          await _loudnessEnhancer!.setTargetGain(gainDb);
        } else {
          await _loudnessEnhancer!.setEnabled(false);
          await _loudnessEnhancer!.setTargetGain(0.0);
        }
        // Asegurar que el volumen del player esté en 1.0
        if (player.volume != originalVolume) {
          await player.setVolume(originalVolume);
        }
      } else {
        // iOS / otras plataformas: usar setVolume (sin boost real, se mantiene en 1.0)
        if (player.volume != originalVolume) {
          await player.setVolume(originalVolume);
        }
      }
    } catch (_) {}
  }
}

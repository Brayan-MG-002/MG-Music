// Copyright © 2026 Brayan Medrano - MG Music
// Lógica para el manejo del estado y preferencias

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'dart:math';
import 'package:mg_music/services/audio/ado_handler.dart';

class StateManager {
  static const String _prefStartupMode = 'startup_mode';
  static const String startupAdo = 'ado';
  static const String startupLast = 'last';

  String _startupMode = startupAdo;
  bool _showVisualizer = true;
  bool _hasStartupExecuted = false;

  String get startupMode => _startupMode;
  bool get showVisualizer => _showVisualizer;
  bool get hasStartupExecuted => _hasStartupExecuted;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _startupMode = prefs.getString(_prefStartupMode) ?? startupAdo;
    _showVisualizer = prefs.getBool('show_visualizer') ?? true;
  }

  Future<void> setStartupMode(String mode) async {
    _startupMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefStartupMode, mode);
  }

  Future<void> toggleVisualizer(bool value) async {
    _showVisualizer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_visualizer', value);
  }

  Future<Map<String, dynamic>?> getStartupSong(List<LocalSong> allSongs) async {
    if (_hasStartupExecuted) return null;
    _hasStartupExecuted = true;

    LocalSong? songToLoad;
    Duration startPos = Duration.zero;

    if (_startupMode == startupLast) {
      final prefs = await SharedPreferences.getInstance();
      final lastPath = prefs.getString('last_played_path');
      int lastPos = prefs.getInt('last_played_position') ?? 0;

      if (lastPath != null) {
        try {
          final matchingSongs = allSongs.where((s) => s.path == lastPath);
          if (matchingSongs.isNotEmpty) songToLoad = matchingSongs.first;
          lastPos = prefs.getInt('last_pos_$lastPath') ?? lastPos;
          startPos = Duration(milliseconds: lastPos);
        } catch (_) {}
      }
    } else if (_startupMode == startupAdo) {
      final adoSongs = allSongs.where((s) => AdoHandler.isAdo(s)).toList();
      if (adoSongs.isNotEmpty) {
        songToLoad = adoSongs[Random().nextInt(adoSongs.length)];
      }
    }

    if (songToLoad != null) {
      return {'song': songToLoad, 'position': startPos};
    }
    return null;
  }

  Future<void> savePosition(Duration position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_played_position', position.inMilliseconds);
    } catch (e) {}
  }

  Future<void> savePositionFor(LocalSong song, Duration position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_pos_${song.path}', position.inMilliseconds);
    } catch (e) {}
  }

  Future<void> saveLastPlayedSong(LocalSong song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_path', song.path);
    } catch (e) {}
  }
}

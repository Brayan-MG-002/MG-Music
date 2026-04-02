// Copyright © 2026 Brayan Medrano - MG Music
// Servicio para exportar e importar configuraciones, playlists y favoritos.

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/ado_experience_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<String> getBackupDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('backup_custom_path');
    
    if (customPath != null && await Directory(customPath).exists()) {
      return customPath;
    }

    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/MG Music');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final mgDir = Directory('${docDir.path}/MG Music Backups');
      if (!await mgDir.exists()) {
        await mgDir.create(recursive: true);
      }
      return mgDir.path;
    }
  }

  Future<void> setBackupDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_custom_path', path);
  }

  Future<Map<String, dynamic>> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();

    bool hasStorage = false;
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted) {
        hasStorage = true;
      } else {
        if (await Permission.manageExternalStorage.request().isGranted ||
            await Permission.storage.request().isGranted) {
          hasStorage = true;
        }
      }
    } else {
      hasStorage = true;
    }

    if (!hasStorage) {
      return {'success': false, 'message': 'Permisos de almacenamiento denegados.'};
    }

    try {
      final Map<String, dynamic> backupData = {};
      final keys = prefs.getKeys();

      final bool incSettings = prefs.getBool('backup_cfg_settings') ?? true;
      final bool incFavorites = prefs.getBool('backup_cfg_favorites') ?? true;
      final bool incPlaylists = prefs.getBool('backup_cfg_playlists') ?? true;
      final bool incTheme = prefs.getBool('backup_cfg_theme') ?? true;
      final bool incRoutes = prefs.getBool('backup_cfg_routes') ?? true;
      final bool incAdo = prefs.getBool('backup_cfg_ado') ?? true;

      for (var key in keys) {
        bool include = false;

        if (key == 'favorite_songs') {
          if (incFavorites) include = true;
        } else if (key == 'playlist_names' || key.startsWith('playlist_songs_')) {
          if (incPlaylists) include = true;
        } else if (key.startsWith('app_theme_')) {
          if (incTheme) include = true;
        } else if (key == 'music_scan_folders' || key == 'scan_all_device') {
          if (incRoutes) include = true;
        } else if (key.startsWith('ado_')) {
          if (incAdo) include = true;
        } else {
          if (!key.startsWith('backup_cfg_') && incSettings) {
            include = true;
          }
        }

        if (include) {
          var value = prefs.get(key);
          backupData[key] = value;
        }
      }


      final now = DateTime.now();
      final packageInfo = await PackageInfo.fromPlatform();
      
      List<String> contents = [];
      if (incSettings) contents.add('Ajustes');
      if (incFavorites) {
        final favs = prefs.getStringList('favorite_songs') ?? [];
        contents.add('${favs.length} Favoritos');
      }
      if (incPlaylists) {
        final names = prefs.getStringList('playlist_names') ?? [];
        contents.add('${names.length} Playlists');
      }
      if (incTheme) contents.add('Tema');
      if (incRoutes) contents.add('Rutas');
      if (incAdo) contents.add('Experiencia Temática');

      final Map<String, dynamic> finalData = {
        'metadata': {
          'created_at': now.toIso8601String(),
          'app_version': packageInfo.version,
          'summary': contents.join(', '),
        },
        'data': backupData,
      };

      final jsonString = jsonEncode(finalData);

      final targetDir = await getBackupDirectory();
      final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(now);
      final fileName = 'backup_mgmusic_${dateStr}_v${packageInfo.version}.json';
      final file = File('$targetDir/$fileName');
      await file.writeAsString(jsonString);

      return {
        'success': true,
        'message': 'Copia guardada en:\n$targetDir/$fileName'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al exportar: $e'};
    }
  }

  Future<Map<String, dynamic>> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return {'success': false, 'message': 'Importación cancelada.'};
      }

      final file = File(result.files.single.path!);
      return await importFromFile(file);
    } catch (e) {
      return {'success': false, 'message': 'Error al importar: $e'};
    }
  }

  Future<Map<String, dynamic>> importFromFile(File file) async {
    try {
      final jsonString = await file.readAsString();
      final Map<String, dynamic> rawData = jsonDecode(jsonString);
      
      final Map<String, dynamic> backupData = rawData.containsKey('data') 
          ? rawData['data'] 
          : rawData;

      final prefs = await SharedPreferences.getInstance();

      int playlistsFails = 0;
      int favoritesFails = 0;
      int playlistsRestored = 0;
      int favoritesRestored = 0;

      for (var key in backupData.keys) {
        var value = backupData[key];

        if (key == 'favorite_songs' && value is List) {
          final List<String> validFavs = [];
          for (var item in value) {
            if (File(item.toString()).existsSync()) {
              validFavs.add(item.toString());
              favoritesRestored++;
            } else {
              favoritesFails++;
            }
          }
          await prefs.setStringList(key, validFavs);
        } else if (key.startsWith('playlist_songs_') && value is List) {
          final List<String> validSongs = [];
          for (var item in value) {
            if (File(item.toString()).existsSync()) {
              validSongs.add(item.toString());
              playlistsRestored++;
            } else {
              playlistsFails++;
            }
          }
          await prefs.setStringList(key, validSongs);
        } else {
          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is List) {
            await prefs.setStringList(key, value.map((e) => e.toString()).toList());
          }
        }
      }

      await PlaylistManager().init();
      await FavoritesManager().init();
      
      final bool boostEnabled = prefs.getBool('ado_boost_enabled') ?? false;
      final double boostLevel = prefs.getDouble('ado_boost_level') ?? 1.2;
      final manager = AudioPlayerManager();
      await manager.setAdoBoostEnabled(boostEnabled);
      await manager.setAdoBoostLevel(boostLevel);
      
      await ThemeService().reloadFromPrefs();
      await AdoExperienceService().init();

      return {
        'success': true,
        'playlistsRestored': playlistsRestored,
        'playlistsFails': playlistsFails,
        'favoritesRestored': favoritesRestored,
        'favoritesFails': favoritesFails,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error al importar: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final dirPath = await getBackupDirectory();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];

      final List<FileSystemEntity> files = dir.listSync();
      final List<Map<String, dynamic>> backups = [];

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stats = await entity.stat();
          final details = await getBackupDetails(entity.path);
          
          backups.add({
            'path': entity.path,
            'name': entity.path.split('/').last.split('\\').last,
            'size': stats.size,
            'modified': stats.modified,
            'metadata': details,
          });
        }
      }

      backups.sort((a, b) => (b['modified'] as DateTime).compareTo(a['modified'] as DateTime));
      return backups;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBackupDetails(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is Map && data.containsKey('metadata')) {
        return data['metadata'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteBackup(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

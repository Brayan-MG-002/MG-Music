// Copyright © 2026 Brayan Medrano - MG Music
// Obtención de canciones del dispositivo

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:audiotags/audiotags.dart' as tags;

typedef SongFoundCallback = void Function(LocalSong song);

class SongFetcher {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static final List<LocalSong> _cachedSongs = [];
  static final ValueNotifier<int> onLibraryChanged = ValueNotifier(0);
  static final ValueNotifier<List<LocalSong>> songsNotifier =
      ValueNotifier<List<LocalSong>>([]);
  static final ValueNotifier<bool> isScanningNotifier = ValueNotifier(false);

  static bool _isScanning = false;
  static bool get isScanning => _isScanning;
  static set _setScanningState(bool value) {
    _isScanning = value;
    isScanningNotifier.value = value;
  }

  static bool _cacheLoadedFromDisk = false;

  static Future<File> _getCacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/mg_songs_cache_v2.json');
  }

  static Future<void> _saveCacheToDisk(List<LocalSong> songs) async {
    try {
      final file = await _getCacheFile();
      final List<Map<String, dynamic>> data = songs.map((s) {
        return {
          'id': s.id,
          'title': s.title,
          'artist': s.artist,
          'path': s.path,
          'duration': s.duration,
        };
      }).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {}
  }

  static Future<List<LocalSong>> _loadCacheFromDisk() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final List<dynamic> data = jsonDecode(raw);
      final dir = await getApplicationSupportDirectory();
      final artworksDir = Directory('${dir.path}/artworks_v2');
      if (!await artworksDir.exists()) {
        await artworksDir.create(recursive: true);
      }

      final futures = data.map((item) async {
        final path = item['path'] as String? ?? '';
        if (path.isEmpty || !File(path).existsSync()) return null;

        final id = item['id'] as int? ?? path.hashCode;
        Uint8List? artwork;
        try {
          final artFile = File('${artworksDir.path}/${id.abs()}.png');
          if (await artFile.exists()) {
            artwork = await artFile.readAsBytes();
          }
        } catch (_) {}

        return LocalSong(
          id: id,
          title: item['title'] as String? ?? '',
          artist: item['artist'] as String? ?? 'Artista Desconocido',
          path: path,
          duration: item['duration'] as int? ?? 0,
          artwork: artwork,
        );
      }).toList();

      final results = await Future.wait(futures);
      final songs = results.whereType<LocalSong>().toList();

      return songs;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> hasDiskCache() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) return false;
      final stat = await file.stat();
      return stat.size > 10;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearCache() async {
    _cachedSongs.clear();
    _cacheLoadedFromDisk = false;
    songsNotifier.value = [];
    try {
      final file = await _getCacheFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<bool> _requestPermission() async {
    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    await Permission.audio.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();

    return await Permission.audio.isGranted ||
        await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted;
  }

  static Future<void> saveOverride(
    String path,
    String title,
    String artist, [
    Uint8List? artwork,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('song_metadata_overrides_v2');
    Map<String, dynamic> overrides = {};
    if (jsonStr != null) {
      try {
        overrides = Map<String, dynamic>.from(jsonDecode(jsonStr));
      } catch (_) {}
    }
    overrides[path] = {'title': title, 'artist': artist};
    await prefs.setString('song_metadata_overrides_v2', jsonEncode(overrides));

    if (artwork != null) {
      try {
        final directory = Directory(
          '/storage/emulated/0/Pictures/MG Music/.overrides',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final fileName = "${path.hashCode.abs()}.png";
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(artwork);
      } catch (e) {}
    }
  }

  Future<void> startScan({
    SongFoundCallback? onSongFound,
    VoidCallback? onScanComplete,
    bool forceRefresh = false,
  }) async {
    if (_isScanning && !forceRefresh) return;

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      onScanComplete?.call();
      return;
    }

    final hasCache = await hasDiskCache();
    final bool isLightScan = hasCache && !forceRefresh;

    if (!isLightScan) {
      _setScanningState = true;
    } else {
      isScanningNotifier.value = true;
    }
    _isScanning = true;

    if (hasCache && !forceRefresh) {
      if (!_cacheLoadedFromDisk) {
        final diskSongs = await _loadCacheFromDisk();
        if (diskSongs.isNotEmpty) {
          _cachedSongs.clear();
          _cachedSongs.addAll(diskSongs);
          _cacheLoadedFromDisk = true;
          songsNotifier.value = List.unmodifiable(_cachedSongs);
        }
      } else {
        songsNotifier.value = List.unmodifiable(_cachedSongs);
      }
    }

    if (isLightScan) {
      _runLightScan(
        onSongFound: onSongFound,
        onComplete: () {
          _isScanning = false;
          _setScanningState = false;
          onScanComplete?.call();
        },
      );
    } else {
      _runFullScan(
        onSongFound: onSongFound,
        onComplete: () {
          _isScanning = false;
          _setScanningState = false;
          onScanComplete?.call();
        },
      );
    }
  }

  Future<List<LocalSong>> getSongs({
    Function(List<LocalSong>)? onProgress,
    bool forceRefresh = false,
  }) async {
    final completer = <LocalSong>[];

    await startScan(
      forceRefresh: forceRefresh,
      onSongFound: (song) {
        completer.add(song);
        onProgress?.call(List.from(completer));
      },
      onScanComplete: () {},
    );

    int waited = 0;
    while (_isScanning && waited < 12000) {
      await Future.delayed(const Duration(milliseconds: 10));
      waited++;
    }

    return List.from(_cachedSongs);
  }

  Future<void> _runLightScan({
    SongFoundCallback? onSongFound,
    VoidCallback? onComplete,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool scanAllDevice = prefs.getBool('scan_all_device') ?? true;
      final List<String> selectedFolders =
          prefs.getStringList('music_scan_folders') ?? [];

      final existingPathsInCache = _cachedSongs.map((s) => s.path).toSet();

      final toRemove = <String>{};
      for (final path in existingPathsInCache) {
        if (!File(path).existsSync()) {
          toRemove.add(path);
        }
      }
      if (toRemove.isNotEmpty) {
        _cachedSongs.removeWhere((s) => toRemove.contains(s.path));
        songsNotifier.value = List.unmodifiable(_cachedSongs);
      }

      final queriedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final currentPaths = _cachedSongs.map((s) => s.path).toSet();
      int lastNotifiedLen = _cachedSongs.length;

      void notifyBatched() {
        if (_cachedSongs.length - lastNotifiedLen >= 20) {
          songsNotifier.value = List.unmodifiable(_cachedSongs);
          lastNotifiedLen = _cachedSongs.length;
        }
      }

      Map<String, dynamic> overrides = {};
      final String? jsonStr = prefs.getString('song_metadata_overrides_v2');
      if (jsonStr != null) {
        try {
          overrides = Map<String, dynamic>.from(jsonDecode(jsonStr));
        } catch (_) {}
      }

      bool added = false;
      for (final song in queriedSongs) {
        if (song.isMusic != true) continue;
        final path = song.data;
        if (currentPaths.contains(path)) continue;
        if (!File(path).existsSync()) continue;
        if (song.duration != null && song.duration! < 60 * 1000) continue;

        if (!scanAllDevice && selectedFolders.isNotEmpty) {
          final pathLower = path.toLowerCase();
          bool inFolder = false;
          for (final folder in selectedFolders) {
            if (pathLower.startsWith(folder.toLowerCase())) {
              inFolder = true;
              break;
            }
          }
          if (!inFolder) continue;
        }

        String finalTitle = song.title;
        String finalArtist = song.artist ?? 'Artista Desconocido';
        if (overrides.containsKey(path)) {
          final ov = overrides[path];
          finalTitle = ov['title'] as String? ?? finalTitle;
          finalArtist = ov['artist'] as String? ?? finalArtist;
        }

        Uint8List? artwork;
        try {
          artwork = await _audioQuery.queryArtwork(
            song.id,
            ArtworkType.AUDIO,
            size: 300,
          );
          
          if (artwork == null) {
            artwork = await _extractArtworkFallback(path);
          }

          if (artwork != null) {
            final dir = await getApplicationSupportDirectory();
            final artworksDir = Directory('${dir.path}/artworks_v2');
            if (!await artworksDir.exists()) {
              await artworksDir.create(recursive: true);
            }
            final artFile = File('${artworksDir.path}/${song.id.abs()}.png');
            await artFile.writeAsBytes(artwork);
          }
        } catch (_) {}

        final newSong = LocalSong(
          id: song.id,
          title: finalTitle,
          artist: finalArtist,
          path: path,
          artwork: artwork,
          duration: song.duration,
        );

        _cachedSongs.add(newSong);
        currentPaths.add(path);
        notifyBatched();
        onSongFound?.call(newSong);
        added = true;
      }

      if (added && _cachedSongs.length > lastNotifiedLen) {
        songsNotifier.value = List.unmodifiable(_cachedSongs);
      }

      if (added || toRemove.isNotEmpty) {
        await _saveCacheToDisk(_cachedSongs);
      }
    } catch (e) {
    } finally {
      onComplete?.call();
    }
  }

  Future<void> _runFullScan({
    SongFoundCallback? onSongFound,
    VoidCallback? onComplete,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool scanAllDevice = prefs.getBool('scan_all_device') ?? true;
      final List<String> selectedFolders =
          prefs.getStringList('music_scan_folders') ?? [];

      Map<String, dynamic> overrides = {};
      final String? jsonStr = prefs.getString('song_metadata_overrides_v2');
      if (jsonStr != null) {
        try {
          overrides = Map<String, dynamic>.from(jsonDecode(jsonStr));
        } catch (_) {}
      }

      _cachedSongs.clear();
      songsNotifier.value = [];

      final Set<String> existingPaths = {};
      int lastNotifiedLen = 0;

      void notifyBatched() {
        if (_cachedSongs.length <= 15 ||
            (_cachedSongs.length - lastNotifiedLen >= 20)) {
          songsNotifier.value = List.unmodifiable(_cachedSongs);
          lastNotifiedLen = _cachedSongs.length;
        }
      }

      final queriedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      for (final song in queriedSongs) {
        if (song.isMusic != true) continue;
        final path = song.data;
        if (!File(path).existsSync()) continue;
        if (song.duration != null && song.duration! < 60 * 1000) continue;

        final pathLower = path.toLowerCase();

        if (!scanAllDevice && selectedFolders.isNotEmpty) {
          bool inFolder = false;
          for (final folder in selectedFolders) {
            if (pathLower.startsWith(folder.toLowerCase())) {
              inFolder = true;
              break;
            }
          }
          if (!inFolder) continue;
        }

        Uint8List? artwork;
        try {
          final overrideArtFile = File(
            '/storage/emulated/0/Pictures/MG Music/.overrides/${path.hashCode.abs()}.png',
          );
          if (await overrideArtFile.exists()) {
            artwork = await overrideArtFile.readAsBytes();
          }
        } catch (_) {}

        if (artwork == null) {
          try {
            artwork = await _audioQuery.queryArtwork(
              song.id,
              ArtworkType.AUDIO,
              size: 300,
            );

            if (artwork == null) {
              artwork = await _extractArtworkFallback(path);
            }

            if (artwork != null) {
              final dir = await getApplicationSupportDirectory();
              final artworksDir = Directory('${dir.path}/artworks_v2');
              if (!await artworksDir.exists()) {
                await artworksDir.create(recursive: true);
              }
              final artFile = File('${artworksDir.path}/${song.id.abs()}.png');
              await artFile.writeAsBytes(artwork);
            }
          } catch (_) {}
        }

        String finalTitle = song.title;
        String finalArtist = song.artist ?? 'Artista Desconocido';
        if (overrides.containsKey(path)) {
          final ov = overrides[path];
          finalTitle = ov['title'] as String? ?? finalTitle;
          finalArtist = ov['artist'] as String? ?? finalArtist;
        }

        final newSong = LocalSong(
          id: song.id,
          title: finalTitle,
          artist: finalArtist,
          path: path,
          artwork: artwork,
          duration: song.duration,
        );

        _cachedSongs.add(newSong);
        existingPaths.add(path);

        notifyBatched();
        onSongFound?.call(newSong);
      }

      if (_cachedSongs.length > lastNotifiedLen) {
        songsNotifier.value = List.unmodifiable(_cachedSongs);
        lastNotifiedLen = _cachedSongs.length;
      }

      final List<String> foldersToScan = [];
      if (scanAllDevice) {
        foldersToScan.add('/storage/emulated/0');
      } else if (selectedFolders.isNotEmpty) {
        foldersToScan.addAll(selectedFolders);
      }

      final audioExtensions = [
        '.mp3',
        '.m4a',
        '.flac',
        '.wav',
        '.ogg',
        '.aac',
        '.opus',
        '.alac',
        '.wma',
      ];

      for (final folderPath in foldersToScan) {
        await _manualRecursiveScan(
          folderPath,
          existingPaths,
          audioExtensions,
          onSongFound,
          notifyBatched,
        );
      }

      if (_cachedSongs.length > lastNotifiedLen) {
        songsNotifier.value = List.unmodifiable(_cachedSongs);
      }

      await _saveCacheToDisk(_cachedSongs);
    } catch (e) {
    } finally {
      onComplete?.call();
    }
  }

  Future<void> _manualRecursiveScan(
    String folderPath,
    Set<String> existingPaths,
    List<String> audioExtensions,
    SongFoundCallback? onSongFound,
    VoidCallback notifyBatched,
  ) async {
    final dir = Directory(folderPath);

    final junkKeywords = [
      'whatsapp',
      'telegram audio',
      'telegram video',
      'snapchat',
      'instagram',
      'alarms',
      'ringtones',
      'notifications',
      'sent',
      '.thumbnails',
      'cache',
      'lost+found',
    ];

    if (junkKeywords.any((kw) => folderPath.toLowerCase().contains(kw))) {
      return;
    }

    if (folderPath.contains('/Android/data') ||
        folderPath.contains('/Android/obb')) {
      return;
    }

    try {
      if (!await dir.exists()) return;

      final List<FileSystemEntity> entities = await dir
          .list(recursive: false, followLinks: false)
          .toList()
          .catchError((e) => <FileSystemEntity>[]);

      for (final entity in entities) {
        if (entity is Directory) {
          await _manualRecursiveScan(
            entity.path,
            existingPaths,
            audioExtensions,
            onSongFound,
            notifyBatched,
          );
        } else if (entity is File) {
          final path = entity.path;
          if (existingPaths.contains(path)) continue;

          final fileName = path.split(Platform.isWindows ? '\\' : '/').last;
          if (fileName.startsWith('.')) continue;

          final parts = fileName.split('.');
          if (parts.length > 1) {
            final ext = '.${parts.last.toLowerCase()}';
            if (audioExtensions.contains(ext)) {
              try {
                final fileSize = await entity.length();
                if (fileSize < 1024 * 1024) continue;
              } catch (_) {
                continue;
              }

              final newSong = LocalSong(
                id: path.hashCode,
                title: parts.sublist(0, parts.length - 1).join('.'),
                artist: 'Artista Desconocido',
                path: path,
                duration: 0,
              );

              _cachedSongs.add(newSong);
              existingPaths.add(path);
              notifyBatched();
              onSongFound?.call(newSong);
            }
          }
        }
      }
    } catch (e) {
    }
  }

  static Future<Uint8List?> _extractArtworkFallback(String path) async {
    try {
      final tag = await tags.AudioTags.read(path);
      if (tag != null && tag.pictures.isNotEmpty) {
        return tag.pictures.first.bytes;
      }
    } catch (_) {}
    return null;
  }
}

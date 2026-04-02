// Copyright © 2026 Brayan Medrano - MG Music
// Gestión de canciones favoritas con persistencia local

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/models/song_model.dart';

class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  static const _favoritesKey = 'favorite_songs';
  final ValueNotifier<List<String>> _favoritePathsNotifier = ValueNotifier([]);

  ValueListenable<List<String>> get favoritePathsNotifier =>
      _favoritePathsNotifier;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritePaths = prefs.getStringList(_favoritesKey) ?? [];
    _favoritePathsNotifier.value = favoritePaths;
  }

  Future<void> addFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFavorites = _favoritePathsNotifier.value.toList();
    if (!currentFavorites.contains(song.path)) {
      currentFavorites.add(song.path);
      _favoritePathsNotifier.value = currentFavorites;
      await prefs.setStringList(_favoritesKey, currentFavorites);
    }
  }

  Future<bool> removeFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();

    final mainId = prefs.getString('main_favorite_song_id');
    if (mainId == song.id.toString()) {
      return false;
    }

    final currentFavorites = _favoritePathsNotifier.value.toList();
    if (currentFavorites.remove(song.path)) {
      _favoritePathsNotifier.value = currentFavorites;
      await prefs.setStringList(_favoritesKey, currentFavorites);
    }
    return true;
  }

  Future<bool> toggleFavorite(LocalSong song) async {
    if (isFavorite(song)) {
      return await removeFavorite(song);
    } else {
      await addFavorite(song);
      return true;
    }
  }

  bool isFavorite(LocalSong song) {
    return _favoritePathsNotifier.value.contains(song.path);
  }

  Future<void> setMainFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('main_favorite_song_id', song.id.toString());
  }

  Future<bool> isMainFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    final mainId = prefs.getString('main_favorite_song_id');
    return mainId == song.id.toString();
  }

  List<String> getFavoritePaths() {
    return _favoritePathsNotifier.value;
  }

  Future<String?> getMainFavoriteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('main_favorite_song_id');
  }
}

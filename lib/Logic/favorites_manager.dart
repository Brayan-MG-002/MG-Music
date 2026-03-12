// Copyright © 2026 Brayan Medrano - MG Music
// Gestión de canciones favoritas con persistencia local

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/Logic/song_model.dart';

class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  static const _favoritesKey = 'favorite_songs';
  final ValueNotifier<List<String>> _favoritePathsNotifier = ValueNotifier([]);

  ValueListenable<List<String>> get favoritePathsNotifier =>
      _favoritePathsNotifier;

  /// Carga los favoritos guardados
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritePaths = prefs.getStringList(_favoritesKey) ?? [];
    _favoritePathsNotifier.value = favoritePaths;
  }

  /// Añade una canción a favoritos
  Future<void> addFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFavorites = _favoritePathsNotifier.value.toList();
    if (!currentFavorites.contains(song.path)) {
      currentFavorites.add(song.path);
      _favoritePathsNotifier.value = currentFavorites;
      await prefs.setStringList(_favoritesKey, currentFavorites);
    }
  }

  /// Elimina una canción de favoritos
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
    return true; // Se eliminó correctamente o no estaba
  }

  /// Alterna el estado favorito de una canción
  Future<bool> toggleFavorite(LocalSong song) async {
    if (isFavorite(song)) {
      return await removeFavorite(song);
    } else {
      await addFavorite(song);
      return true;
    }
  }

  /// Verifica si una canción está en favoritos
  bool isFavorite(LocalSong song) {
    return _favoritePathsNotifier.value.contains(song.path);
  }

  /// Establece la canción principal protegida contra eliminación
  Future<void> setMainFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('main_favorite_song_id', song.id.toString());
  }

  /// Verifica si es la favorita principal
  Future<bool> isMainFavorite(LocalSong song) async {
    final prefs = await SharedPreferences.getInstance();
    final mainId = prefs.getString('main_favorite_song_id');
    return mainId == song.id.toString();
  }

  /// Retorna la lista de rutas de canciones favoritas
  List<String> getFavoritePaths() {
    return _favoritePathsNotifier.value;
  }

  /// Obtiene el id de la favorita principal
  Future<String?> getMainFavoriteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('main_favorite_song_id');
  }
}

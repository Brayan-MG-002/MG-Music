// Copyright © 2026 Brayan Medrano - MG Music
// Página de favoritos TV

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/song_fetcher.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

class TvFavoritesPage extends StatefulWidget {
  final VoidCallback onOpenPlayer;
  const TvFavoritesPage({super.key, required this.onOpenPlayer});

  @override
  State<TvFavoritesPage> createState() => _TvFavoritesPageState();
}

class _TvFavoritesPageState extends State<TvFavoritesPage> {
  final SongFetcher _songFetcher = SongFetcher();
  final FavoritesManager _favoritesManager = FavoritesManager();
  final AudioPlayerManager _playerManager = AudioPlayerManager();

  List<LocalSong> _favoriteSongs = [];
  bool _isLoading = true;
  bool _isRemoveMode = false;
  Set<String> _songsToRemove = {};

  @override
  void initState() {
    super.initState();
    _loadFavoriteSongs();
    _favoritesManager.favoritePathsNotifier.addListener(_loadFavoriteSongs);
  }

  @override
  void dispose() {
    _favoritesManager.favoritePathsNotifier.removeListener(_loadFavoriteSongs);
    super.dispose();
  }

  Future<void> _loadFavoriteSongs() async {
    setState(() => _isLoading = true);
    final allSongs = await _songFetcher.getSongs();
    final favoritePaths = _favoritesManager.getFavoritePaths();

    final favorites = allSongs
        .where((song) => favoritePaths.contains(song.path))
        .toList();

    favorites.sort((a, b) {
      final aIsAdo = a.artist.toLowerCase().contains('ado');
      final bIsAdo = b.artist.toLowerCase().contains('ado');
      if (aIsAdo && !bIsAdo) return -1;
      if (!aIsAdo && bIsAdo) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _favoriteSongs = favorites;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    if (_favoriteSongs.isEmpty) {
      return const Center(
        child: Text(
          'Aún no has agregado canciones a favoritos.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade900, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              _buildActionButton(Ionicons.shuffle, 'Aleatorio', () {
                if (_favoriteSongs.isNotEmpty) {
                  _playerManager.shufflePlay(_favoriteSongs);
                  widget.onOpenPlayer();
                }
              }),
              const SizedBox(width: 15),
              _buildActionButton(
                _isRemoveMode
                    ? Ionicons.checkmark_circle
                    : Ionicons.trash_outline,
                _isRemoveMode ? 'Listo' : 'Eliminar',
                () {
                  if (_isRemoveMode) {
                    _removeSelectedFavorites();
                  }
                  setState(() {
                    _isRemoveMode = !_isRemoveMode;
                    _songsToRemove.clear();
                  });
                },
                color: _isRemoveMode ? Colors.green : Colors.redAccent,
              ),
              const Spacer(),
              const Text(
                'Tus Canciones Favoritas',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_isRemoveMode)
          Container(
            width: double.infinity,
            color: Colors.red.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: const Text(
              'MODO ELIMINAR: Selecciona canciones y pulsa "Listo" para borrarlas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.85,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = _favoriteSongs[index];
              return TvFocusableItem(
                onTap: () {
                  if (_isRemoveMode) {
                    setState(() {
                      if (_songsToRemove.contains(song.path)) {
                        _songsToRemove.remove(song.path);
                      } else {
                        _songsToRemove.add(song.path);
                      }
                    });
                  } else {
                    if (_playerManager.currentSongNotifier.value?.id ==
                        song.id) {
                      widget.onOpenPlayer();
                    } else {
                      _playerManager.playSong(song, _favoriteSongs);
                    }
                  }
                },
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: song.artwork != null
                                  ? DecorationImage(
                                      image: MemoryImage(song.artwork!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.grey.shade800,
                            ),
                            child: song.artwork == null
                                ? Center(
                                    child: Image.asset(
                                      'assets/MG-I-T.png',
                                      width: 60,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (_isRemoveMode)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _songsToRemove.contains(song.path)
                                ? Ionicons.trash
                                : Ionicons.radio_button_off,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _removeSelectedFavorites() {
    for (final path in _songsToRemove) {
      final song = _favoriteSongs.firstWhere((s) => s.path == path);
      _favoritesManager.removeFavorite(song);
    }
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey.shade800).withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

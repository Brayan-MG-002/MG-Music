// Copyright © 2026 Brayan Medrano - MG Music
// Diálogos del home TV usando GlobalModalService y CustomToastService

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/playlist_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/global_modal_service.dart';
import 'package:mg_music/services/custom_toast_service.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';
import 'package:mg_music/services/playlist_action_service.dart';

/// Muestra el modal de ordenar canciones
void showTvSortModal({
  required AppThemeMode mode,
  required VoidCallback onAdoPrimero,
  required VoidCallback onAZ,
  required VoidCallback onZA,
}) {
  GlobalModalService.show(
    title: 'Ordenar por',
    icon: Ionicons.swap_vertical,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _modalOption(
          icon: Ionicons.star,
          label: 'Ado (Por defecto)',
          onTap: () {
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
            onAdoPrimero();
          },
          mode: mode,
          highlighted: true,
        ),
        const SizedBox(height: 4),
        _modalOption(
          icon: Ionicons.text,
          label: 'Alfabético (A–Z)',
          onTap: () {
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
            onAZ();
          },
          mode: mode,
        ),
        const SizedBox(height: 4),
        _modalOption(
          icon: Ionicons.swap_vertical,
          label: 'Inverso (Z–A)',
          onTap: () {
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
            onZA();
          },
          mode: mode,
        ),
      ],
    ),
    actions: [
      ModalActionButton(
        label: 'Cancelar',
        onPressed: () =>
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!),
        color: Colors.grey,
      ),
    ],
  );
}

/// Muestra el modal de filtrar por artista
void showTvArtistModal({
  required AppThemeMode mode,
  required List<String> artists,
  required void Function(String?) onArtistSelected,
}) {
  GlobalModalService.show(
    title: 'Filtrar por Artista',
    icon: Ionicons.people_outline,
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modalOption(
            icon: Ionicons.people,
            label: 'Todos los artistas',
            onTap: () {
              Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
              onArtistSelected(null);
            },
            mode: mode,
          ),
          const Divider(color: Colors.white12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                children: artists
                    .map(
                      (a) => _modalOption(
                        icon: Ionicons.person,
                        label: a,
                        onTap: () {
                          Navigator.pop(
                            GlobalModalService.navigatorKey.currentContext!,
                          );
                          onArtistSelected(a);
                        },
                        mode: mode,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      ModalActionButton(
        label: 'Cancelar',
        onPressed: () =>
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!),
        color: Colors.grey,
      ),
    ],
  );
}

/// Muestra el menú contextual de opciones de una canción
void showTvSongOptionsModal({
  required LocalSong song,
  required AppThemeMode mode,
}) {
  final isAdo = AdoHandler.isAdo(song);

  GlobalModalService.show(
    title: song.title,
    icon: isAdo ? Ionicons.star : Ionicons.musical_note,
    primaryColor: isAdo ? Colors.blue.shade900 : null,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _modalOption(
          icon: Ionicons.play_forward,
          label: 'Reproducir siguiente',
          onTap: () {
            AudioPlayerManager().addNext(song);
            final ctx = GlobalModalService.navigatorKey.currentContext!;
            Navigator.pop(ctx);
            CustomToastService.show(
              ctx,
              message: 'Siguiente: ${song.title}',
              type: ToastType.info,
              icon: Ionicons.play_forward,
            );
          },
          mode: mode,
        ),
        const SizedBox(height: 4),

        ValueListenableBuilder<List<String>>(
          valueListenable: FavoritesManager().favoritePathsNotifier,
          builder: (context, paths, _) {
            final isFav = paths.contains(song.path);
            return _modalOption(
              icon: isFav ? Ionicons.heart : Ionicons.heart_outline,
              label: isFav ? 'Quitar de Favoritos' : 'Agregar a Favoritos',
              onTap: () async {
                final ctx = GlobalModalService.navigatorKey.currentContext!;
                if (isFav) {
                  final isMain = await FavoritesManager().isMainFavorite(song);
                  if (isMain) {
                    Navigator.pop(ctx);
                    CustomToastService.show(
                      ctx,
                      message: 'No se puede quitar: es la principal',
                      type: ToastType.error,
                    );
                    return;
                  }
                  final ok = await FavoritesManager().removeFavorite(song);
                  Navigator.pop(ctx);
                  if (ok) {
                    CustomToastService.show(
                      ctx,
                      message: 'Quitado de Favoritos',
                      type: ToastType.warning,
                    );
                  } else {
                    CustomToastService.show(
                      ctx,
                      message: 'No se pudo quitar',
                      type: ToastType.error,
                    );
                  }
                } else {
                  await FavoritesManager().addFavorite(song);
                  Navigator.pop(ctx);
                  CustomToastService.show(
                    ctx,
                    message: 'Añadido a Favoritos ❤️',
                    type: ToastType.success,
                  );
                }
              },
              mode: mode,
              iconColor: isFav ? (isAdo ? Colors.blue : Colors.red) : null,
            );
          },
        ),
        const SizedBox(height: 4),

        _modalOption(
          icon: Ionicons.list,
          label: 'Añadir a Playlist',
          onTap: () {
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!);
            PlaylistActionService.showAddToPlaylistDialog(
              GlobalModalService.navigatorKey.currentContext!,
              song,
            );
          },
          mode: mode,
        ),
      ],
    ),
    actions: [
      ModalActionButton(
        label: 'Cerrar',
        onPressed: () =>
            Navigator.pop(GlobalModalService.navigatorKey.currentContext!),
        color: Colors.grey,
      ),
    ],
  );
}

/// Crea una opción estilizada para un modal
Widget _modalOption({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  required AppThemeMode mode,
  Color? iconColor,
  bool highlighted = false,
}) {
  return TvFocusableItem(
    onTap: onTap,
    borderRadius: 10,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: highlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlueMid.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? AppColors.textSecondary(mode),
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlighted
                    ? AppColors.textPrimary(mode)
                    : AppColors.textSecondary(mode),
                fontSize: 15,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

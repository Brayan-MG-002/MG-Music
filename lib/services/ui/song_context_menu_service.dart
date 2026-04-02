// Copyright © 2026 Brayan Medrano - MG Music
// Servicio especializado en la gestión del menú contextual de canciones, proporcionando opciones de reproducción, favoritos, playlists y edición, con soporte adaptativo para móvil y TV (Android TV).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/playlist_action_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';

class SongContextMenuService {
  static void showOptions(
    BuildContext context,
    LocalSong song, {
    VoidCallback? onFavoriteToggled,
    VoidCallback? onEditSong,
    VoidCallback? onSongDeleted,
    VoidCallback? onMultiSelect,
    bool isTv = false,
    bool showEditDelete = true,
  }) {
    final isFav = FavoritesManager().isFavorite(song);

    if (isTv) {
      _showTvOptions(
        context,
        song,
        isFav: isFav,
        onFavoriteToggled: onFavoriteToggled,
        onEditSong: onEditSong,
        onSongDeleted: onSongDeleted,
        onMultiSelect: onMultiSelect,
        showEditDelete: showEditDelete,
      );
      return;
    }

    BottomModalService.show(
      context,
      title: song.title,
      subtitle: song.artist,
      artwork: song.artwork,
      options: [
        BottomModalOption(
          icon: Ionicons.play_skip_forward_outline,
          label: "Reproducir Siguiente",
          onTap: () {
            AudioPlayerManager().addNext(song);
            Navigator.pop(context);
            CustomToastService.show(
              context,
              message: "Siguiente: ${song.title}",
              type: ToastType.ado,
              icon: Ionicons.play_skip_forward,
            );
          },
        ),
        if (onMultiSelect != null)
          BottomModalOption(
            icon: Ionicons.checkbox_outline,
            label: "Selección múltiple",
            onTap: () {
              Navigator.pop(context);
              onMultiSelect();
            },
          ),
        BottomModalOption(
          icon: isFav ? Ionicons.heart_dislike : Ionicons.heart,
          label: isFav ? "Quitar de Favoritos" : "Agregar a Favoritos",
          onTap: () async {
            final success = await FavoritesManager().toggleFavorite(song);
            if (!context.mounted) return;

            if (!success) {
              Navigator.pop(context);
              CustomToastService.show(
                context,
                message: 'No puedes desmarcar tu canción principal',
                type: ToastType.error,
              );
              return;
            }

            if (onFavoriteToggled != null) onFavoriteToggled();
            Navigator.pop(context);
            CustomToastService.show(
              context,
              message: isFav ? "Eliminado de Favoritos" : "Agregado a Favoritos",
              type: isFav ? ToastType.warning : ToastType.success,
              icon: isFav ? Ionicons.heart_dislike : Ionicons.heart,
            );
          },
        ),
        BottomModalOption(
          icon: Ionicons.add_circle_outline,
          label: "Agregar a Playlist",
          onTap: () {
            Navigator.pop(context);
            PlaylistActionService.showAddToPlaylistDialog(context, song);
          },
        ),
        if (showEditDelete)
          BottomModalOption(
            icon: Ionicons.create_outline,
            label: "Editar canción",
            onTap: () {
              Navigator.pop(context);
              if (onEditSong != null) onEditSong();
            },
          ),
        if (showEditDelete)
          BottomModalOption(
            icon: Ionicons.trash_outline,
            label: "Eliminar del dispositivo",
            color: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () async {
              Navigator.pop(context);

              final confirmed = await GlobalModalService.showConfirmation(
                title: 'Eliminar pista',
                message:
                    '¿Eliminar "${song.title}" del almacenamiento?\n\nEsta acción es permanente y no se puede deshacer.',
                icon: Ionicons.warning_outline,
                confirmText: 'Eliminar',
                cancelText: 'Cancelar',
                confirmButtonColor: Colors.redAccent,
              );

              if (!confirmed) return;

              try {
                final file = File(song.path);
                if (await file.exists()) {
                  await file.delete();
                }
                if (onSongDeleted != null) onSongDeleted();
                CustomToastService.show(
                  GlobalModalService.navigatorKey.currentContext!,
                  message: 'Pista eliminada: ${song.title}',
                  type: ToastType.success,
                  icon: Ionicons.checkmark_circle,
                );
              } catch (_) {
                CustomToastService.show(
                  GlobalModalService.navigatorKey.currentContext!,
                  message: 'Error al eliminar la pista',
                  type: ToastType.error,
                  icon: Ionicons.alert_circle,
                );
              }
            },
          ),
      ],
    );
  }

  static void _showTvOptions(
    BuildContext context,
    LocalSong song, {
    required bool isFav,
    VoidCallback? onFavoriteToggled,
    VoidCallback? onEditSong,
    VoidCallback? onSongDeleted,
    VoidCallback? onMultiSelect,
    bool showEditDelete = true,
  }) {
    final mode = Provider.of<ThemeService>(context, listen: false).mode;

    GlobalModalService.show(
      title: song.title,
      icon: Ionicons.musical_notes,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tvOption(
            icon: Ionicons.play_skip_forward,
            label: "Reproducir Siguiente",
            mode: mode,
            onTap: () {
              AudioPlayerManager().addNext(song);
              Navigator.pop(context);
              CustomToastService.show(
                context,
                message: "Siguiente: ${song.title}",
                type: ToastType.ado,
                icon: Ionicons.play_skip_forward,
              );
            },
          ),
          if (onMultiSelect != null)
            _tvOption(
              icon: Ionicons.checkbox_outline,
              label: "Selección múltiple",
              mode: mode,
              onTap: () {
                Navigator.pop(context);
                onMultiSelect();
              },
            ),
          _tvOption(
            icon: isFav ? Ionicons.heart_dislike : Ionicons.heart,
            label: isFav ? "Quitar de Favoritos" : "Agregar a Favoritos",
            mode: mode,
            iconColor: isFav ? Colors.redAccent : null,
            onTap: () async {
              final success = await FavoritesManager().toggleFavorite(song);
              if (!context.mounted) return;

              if (!success) {
                Navigator.pop(context);
                CustomToastService.show(
                  context,
                  message: 'No puedes desmarcar tu canción principal',
                  type: ToastType.error,
                );
                return;
              }

              if (onFavoriteToggled != null) onFavoriteToggled();
              Navigator.pop(context);
              CustomToastService.show(
                context,
                message:
                    isFav ? "Eliminado de Favoritos" : "Agregado a Favoritos",
                type: isFav ? ToastType.warning : ToastType.success,
                icon: isFav ? Ionicons.heart_dislike : Ionicons.heart,
              );
            },
          ),
          _tvOption(
            icon: Ionicons.add_circle_outline,
            label: "Agregar a Playlist",
            mode: mode,
            onTap: () {
              Navigator.pop(context);
              PlaylistActionService.showAddToPlaylistDialog(context, song);
            },
          ),
          if (showEditDelete)
            _tvOption(
              icon: Ionicons.create_outline,
              label: "Editar canción",
              mode: mode,
              onTap: () {
                Navigator.pop(context);
                if (onEditSong != null) onEditSong();
              },
            ),
          if (showEditDelete)
            _tvOption(
              icon: Ionicons.trash_outline,
              label: "Eliminar",
              mode: mode,
              iconColor: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);

                final confirmed = await GlobalModalService.showConfirmation(
                  title: 'Eliminar pista',
                  message: '¿Eliminar "${song.title}"?\nEsta acción es permanente.',
                  icon: Ionicons.warning_outline,
                  confirmText: 'Eliminar',
                  cancelText: 'Cancelar',
                  confirmButtonColor: Colors.redAccent,
                );

                if (!confirmed) return;

                try {
                  final file = File(song.path);
                  if (await file.exists()) {
                    await file.delete();
                  }
                  if (onSongDeleted != null) onSongDeleted();
                  CustomToastService.show(
                    context,
                    message: 'Pista eliminada',
                    type: ToastType.success,
                  );
                } catch (_) {}
              },
            ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: "Cancelar",
          color: Colors.grey,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  static Widget _tvOption({
    required IconData icon,
    required String label,
    required AppThemeMode mode,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: TvFocusableItem(
        onTap: onTap,
        borderRadius: 12.r,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.icon(mode), size: 22.r),
              SizedBox(width: 16.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

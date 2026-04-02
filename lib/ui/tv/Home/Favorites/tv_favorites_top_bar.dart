// Copyright © 2026 Brayan Medrano - MG Music
// Barra superior personalizada para la sección de favoritos en TV, con acciones rápidas de reproducción y edición.

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:provider/provider.dart';

class TvFavoritesTopBar extends StatelessWidget {
  final VoidCallback onShuffle;
  final bool removeMode;
  final VoidCallback onToggleRemoveMode;

  const TvFavoritesTopBar({
    super.key,
    required this.onShuffle,
    required this.removeMode,
    required this.onToggleRemoveMode,
  });

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.sidebarGradient(mode),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.themeBorder(mode), width: 2),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _chipButton(
            icon: Ionicons.shuffle,
            label: 'Aleatorio',
            onTap: onShuffle,
            mode: mode,
          ),
          const SizedBox(width: 10),
          _chipButton(
            icon: removeMode ? Ionicons.checkmark_circle : Ionicons.trash_outline,
            label: removeMode ? 'Listo' : 'Eliminar',
            onTap: onToggleRemoveMode,
            mode: mode,
            color: removeMode ? Colors.green : Colors.redAccent,
          ),
          const Spacer(),
          Text(
            'Tus Canciones Favoritas',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppThemeMode mode,
    Color? color,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: () {
          if (color == Colors.redAccent) {
            final bg = mode == AppThemeMode.dark ? Colors.black : Colors.white;
            return BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.redAccent, bg.withOpacity(0.9)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.themeBorder(mode)),
            );
          }
          return BoxDecoration(
            color: (color ?? AppColors.iconContainer(mode)).withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.themeBorder(mode)),
          );
        }(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: AppColors.textPrimary(mode)),
            ),
          ],
        ),
      ),
    );
  }
}

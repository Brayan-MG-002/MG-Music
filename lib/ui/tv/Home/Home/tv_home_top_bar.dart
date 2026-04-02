// Copyright © 2026 Brayan Medrano - MG Music
// Barra de herramientas superior para el Inicio en TV, con acceso a filtros, ordenamiento y controles de reproducción mini.

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/ui/tv/Home/Player/tv_player_widget.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class TvHomeTopBar extends StatelessWidget {
  final AppThemeMode mode;
  final VoidCallback onShuffle;
  final VoidCallback onSort;
  final VoidCallback onArtists;
  final VoidCallback onOpenPlayer;

  const TvHomeTopBar({
    super.key,
    required this.mode,
    required this.onShuffle,
    required this.onSort,
    required this.onArtists,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlueMid.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _TvTopBarButton(
            icon: Ionicons.shuffle,
            label: 'Aleatorio',
            onTap: onShuffle,
            mode: mode,
          ),
          const SizedBox(width: 8),

          Expanded(child: TvPlayerWidget(onTap: onOpenPlayer)),
          const SizedBox(width: 8),

          _TvTopBarButton(
            icon: Ionicons.swap_vertical,
            label: 'Orden',
            onTap: onSort,
            mode: mode,
          ),
          const SizedBox(width: 8),

          _TvTopBarButton(
            icon: Ionicons.people_outline,
            label: 'Artistas',
            onTap: onArtists,
            mode: mode,
          ),
        ],
      ),
    );
  }
}

class _TvTopBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeMode mode;

  const _TvTopBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary(mode), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Modales específicos para la interfaz de TV: ordenamiento y filtrado de canciones, utilizando GlobalModalService.

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';

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

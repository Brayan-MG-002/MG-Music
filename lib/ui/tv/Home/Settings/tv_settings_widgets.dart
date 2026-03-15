// Copyright © 2026 Brayan Medrano - MG Music
// Widgets reutilizables de la configuración TV

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/ui/theme_service.dart';

/// Título de sección en la página de ajustes TV
class TvSettingsSectionTitle extends StatelessWidget {
  final String title;
  final AppThemeMode mode;

  const TvSettingsSectionTitle({
    super.key,
    required this.title,
    required this.mode,
  });

  @override
  /// Construye el título de sección
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryBlueMid,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlueMid.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de acción de configuración (botón con flecha)
class TvSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final AppThemeMode mode;
  final bool isActive;
  final bool disabled;

  const TvSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.mode,
    this.isActive = false,
    this.disabled = false,
  });

  @override
  /// Construye un tile de acción
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: TvFocusableItem(
        onTap: disabled ? null : onTap,
        borderRadius: 20,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.blue : AppColors.themeBorder(mode),
              width: 2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isActive
                    ? Colors.blue.shade900.withOpacity(0.6)
                    : AppColors.primaryBlueMid.withOpacity(0.2),
                AppColors.surface(mode).withOpacity(0.0),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mode == AppThemeMode.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isActive
                          ? Colors.blue
                          : AppColors.textPrimary(mode),
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (!disabled)
                    Icon(
                      Ionicons.chevron_forward,
                      color: AppColors.primaryBlueMid,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile de switch (toggle ON/OFF)
class TvSettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppThemeMode mode;

  const TvSettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.mode,
  });

  @override
  /// Construye un tile con interruptor
  Widget build(BuildContext context) {
    return TvFocusableItem(
      onTap: () => onChanged(!value),
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.themeBorder(mode), width: 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlueMid.withOpacity(0.2),
              AppColors.surface(mode).withOpacity(0.0),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mode == AppThemeMode.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.textPrimary(mode),
                    size: 22,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.blue.shade700,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary(mode),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid de 2 columnas para un par de tiles de ajustes TV
class TvSettingsRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const TvSettingsRow({super.key, required this.left, required this.right});

  @override
  /// Construye una fila de 2 columnas para ajustes
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// Widget de un solo tile que ocupa todo el ancho (para el AdoBoost, tema, etc.)
class TvSettingsFullRow extends StatelessWidget {
  final Widget child;

  const TvSettingsFullRow({super.key, required this.child});

  @override
  /// Construye un contenedor de ancho completo
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
  }
}

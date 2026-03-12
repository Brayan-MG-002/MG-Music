// Encabezado del detalle de una playlist en TV
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:provider/provider.dart';

class TvPlaylistDetailHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRename;
  final VoidCallback onShuffle;
  final VoidCallback onPlay;
  final bool canActions;
  final bool removeMode;
  final VoidCallback onToggleRemoveMode;

  const TvPlaylistDetailHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onRename,
    required this.onShuffle,
    required this.onPlay,
    required this.canActions,
    required this.removeMode,
    required this.onToggleRemoveMode,
  });

  @override
  /// Construye el encabezado con navegación y acciones de playlist
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
          _iconButton(Ionicons.arrow_back, onBack, mode),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _iconButton(Ionicons.pencil, onRename, mode),
          const Spacer(),
          if (canActions) ...[
            _chipButton(Ionicons.shuffle, 'Aleatorio', onShuffle, mode),
            const SizedBox(width: 10),
            _chipButton(Ionicons.play, 'Reproducir', onPlay, mode),
            const SizedBox(width: 10),
            _chipButton(
              removeMode ? Ionicons.checkmark_circle : Ionicons.trash_outline,
              removeMode ? 'Listo' : 'Eliminar',
              onToggleRemoveMode,
              mode,
              color: removeMode ? Colors.green : Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap, AppThemeMode mode) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: AppColors.textPrimary(mode), size: 22),
      ),
    );
  }

  Widget _chipButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    AppThemeMode mode, {
    Color? color,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.iconContainer(mode)).withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.themeBorder(mode)),
        ),
        child: Row(
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

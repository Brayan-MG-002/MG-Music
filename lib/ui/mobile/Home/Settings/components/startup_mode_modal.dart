import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupModeModal extends StatelessWidget {
  const StartupModeModal({super.key});

  /// Abre el modal inferior para elegir el modo de inicio
  static void show(BuildContext context) async {
    final currentMode = AudioPlayerManager().startupModeNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    final hasAdoSongs = prefs.getBool('has_ado_songs') ?? true;

    final themeMode = Provider.of<ThemeService>(context, listen: false).mode;

    final options = [
      _createOption(
        context,
        'Prioridad Ado',
        hasAdoSongs
            ? 'Elige una canción aleatoria de Ado al iniciar.'
            : 'No tienes canciones de Ado en tu biblioteca.',
        AudioPlayerManager.startupAdo,
        currentMode,
        themeMode,
        enabled: hasAdoSongs,
      ),
      _createOption(
        context,
        'Continuar reproducción',
        'Carga la última canción y posición.',
        AudioPlayerManager.startupLast,
        currentMode,
        themeMode,
      ),
    ];

    BottomModalService.show(
      context,
      title: 'Inicio de App',
      subtitle: 'Comportamiento al abrir la aplicación',
      options: options,
    );
  }

  /// Crea una opción de modo de inicio estilizada
  static BottomModalOption _createOption(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    String groupValue,
    AppThemeMode mode, {
    bool enabled = true,
  }) {
    final isSelected = value == groupValue;

    return BottomModalOption(
      icon: isSelected ? Ionicons.radio_button_on : Ionicons.radio_button_off,
      label: title,
      subtitle: subtitle,
      color: !enabled
          ? AppColors.surface(mode).withOpacity(0.5)
          : isSelected
          ? AppColors.primaryBlueMid
          : AppColors.surface(mode),
      textColor: !enabled
          ? AppColors.textSecondary(mode).withOpacity(0.5)
          : isSelected
          ? AppColors.textPrimary(
              AppThemeMode.dark,
            ) // Mantenemos blanco pq el fondo es primaryBlueMid
          : AppColors.textPrimary(mode),
      onTap: !enabled
          ? null
          : () {
              AudioPlayerManager().setStartupMode(value);
              Navigator.pop(context);
            },
    );
  }

  @override
  /// Widget vacío, la UI se construye en el bottom modal
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Modal de temporizador de sueño rediseñado

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Claves en SharedPreferences para tiempos personalizados editables
const _kSlot1 = 'sleep_timer_slot1'; // default: 15 min
const _kSlot2 = 'sleep_timer_slot2'; // default: 30 min
const _kSlot3 = 'sleep_timer_slot3'; // default: 60 min

class SleepTimerModal extends StatelessWidget {
  const SleepTimerModal({super.key});

  /// Abre el modal inferior del temporizador
  static void show(BuildContext context) {
    BottomModalService.show(
      context,
      title: 'Temporizador de Apagado',
      subtitle: 'Detener reproducción automáticamente',
      child: const SleepTimerModal(),
    );
  }

  @override
  /// Construye el contenido principal del modal
  Widget build(BuildContext context) {
    return _SleepTimerContent(context: context);
  }
}

class _SleepTimerContent extends StatefulWidget {
  final BuildContext context;
  const _SleepTimerContent({required this.context});

  @override
  State<_SleepTimerContent> createState() => _SleepTimerContentState();
}

class _SleepTimerContentState extends State<_SleepTimerContent> {
  // Duraciones editables por slot (cargadas de SharedPreferences)
  Duration _slot1 = const Duration(minutes: 15);
  Duration _slot2 = const Duration(minutes: 30);
  Duration _slot3 = const Duration(minutes: 60);
  bool _loading = true;

  @override
  /// Carga los slots guardados
  void initState() {
    super.initState();
    _loadSlots();
  }

  /// Lee duraciones de preferencias
  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _slot1 = Duration(seconds: prefs.getInt(_kSlot1) ?? 15 * 60);
      _slot2 = Duration(seconds: prefs.getInt(_kSlot2) ?? 30 * 60);
      _slot3 = Duration(seconds: prefs.getInt(_kSlot3) ?? 60 * 60);
      _loading = false;
    });
  }

  /// Guarda la duración de un slot
  Future<void> _saveSlot(String key, Duration d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, d.inSeconds);
  }

  /// Formatea duración como etiqueta corta
  String _label(Duration d) {
    if (d.inSeconds == 0) return '0 s';
    final parts = <String>[];
    if (d.inHours > 0) parts.add('${d.inHours} h');
    final mins = d.inMinutes.remainder(60);
    if (mins > 0) parts.add('$mins min');
    final secs = d.inSeconds.remainder(60);
    if (secs > 0) parts.add('$secs s');
    return parts.join(' ');
  }

  /// Edita una duración usando el selector global
  Future<void> _editSlot(String key, Duration current) async {
    Navigator.of(widget.context).pop();
    final result = await GlobalModalService.showDurationPicker(
      title: 'Editar Tiempo',
      initialValue: current,
    );
    if (result != null && result.inSeconds > 0) {
      await _saveSlot(key, result);
      if (mounted)
        setState(() {
          if (key == _kSlot1) _slot1 = result;
          if (key == _kSlot2) _slot2 = result;
          if (key == _kSlot3) _slot3 = result;
        });
      if (mounted) SleepTimerModal.show(widget.context);
    } else if (result != null) {
      if (mounted) SleepTimerModal.show(widget.context);
    }
  }

  /// Activa el temporizador con duración específica
  void _activate(Duration d) {
    Navigator.of(widget.context).pop();
    final mins = (d.inSeconds / 60).round();
    AudioPlayerManager().setSleepTimer(mins);
    CustomToastService.show(
      widget.context,
      message: 'Apagado en ${_label(d)}',
      type: ToastType.ado,
    );
  }

  /// Activa pausa al final de la canción
  void _activateEndOfSong() {
    Navigator.of(widget.context).pop();
    AudioPlayerManager().setSleepAtEndOfSong();
    CustomToastService.show(
      widget.context,
      message: 'Se pausará al terminar la canción actual',
      type: ToastType.ado,
    );
  }

  @override
  /// Construye la lista de opciones de temporizador
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final mode = context.watch<ThemeService>().mode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEditableOption(_slot1, _kSlot1, mode),
        _buildEditableOption(_slot2, _kSlot2, mode),
        _buildEditableOption(_slot3, _kSlot3, mode),

        _buildSpecialOption(
          icon: Ionicons.musical_note_outline,
          label: 'Al terminar canción',
          onTap: _activateEndOfSong,
          color: const Color.fromARGB(255, 31, 162, 147),
          mode: mode,
        ),

        _buildSpecialOption(
          icon: Ionicons.close_circle_outline,
          label: 'Desactivar',
          onTap: () {
            Navigator.of(widget.context).pop();
            AudioPlayerManager().setSleepTimer(0);
          },
          color: Colors.red.shade700,
          mode: mode,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  /// Construye una opción editable con acción y botón de edición
  Widget _buildEditableOption(Duration d, String key, AppThemeMode mode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.themeBorder(mode).withOpacity(0.5)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryBlueMid.withOpacity(0.3),
            AppColors.surface(mode),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
      child: ListTile(
        leading: Icon(
          Ionicons.time_outline,
          color: AppColors.textPrimary(mode),
        ),
        title: Text(
          _label(d),
          style: TextStyle(color: AppColors.textPrimary(mode)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: () => _activate(d),
        trailing: GestureDetector(
          onTap: () => _editSlot(key, d),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueMid.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryBlueMid.withOpacity(0.5),
              ),
            ),
            child: Icon(
              Ionicons.pencil_outline,
              color: AppColors.primaryBlueMid,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// Construye una opción especial con color (ej. desactivar)
  Widget _buildSpecialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required AppThemeMode mode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withOpacity(0.25), AppColors.surface(mode)],
          stops: const [0.0, 0.7],
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: onTap,
      ),
    );
  }
}

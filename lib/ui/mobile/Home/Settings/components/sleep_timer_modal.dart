// Copyright © 2026 Brayan Medrano - MG Music


import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


const _kSlot1 = 'sleep_timer_slot1'; // default: 15 min
const _kSlot2 = 'sleep_timer_slot2'; // default: 30 min

class SleepTimerModal extends StatelessWidget {
  const SleepTimerModal({super.key});


  static void show(BuildContext context) {
    BottomModalService.show(
      context,
      title: 'Temporizador de Apagado',
      subtitle: 'Detener reproducción automáticamente',
      child: const SleepTimerModal(),
    );
  }

  @override
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }


  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _slot1 = Duration(seconds: prefs.getInt(_kSlot1) ?? 15 * 60);
      _slot2 = Duration(seconds: prefs.getInt(_kSlot2) ?? 30 * 60);
      _loading = false;
    });
  }


  Future<void> _saveSlot(String key, Duration d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, d.inSeconds);
  }


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
        });
      if (mounted) SleepTimerModal.show(widget.context);
    } else if (result != null) {
      if (mounted) SleepTimerModal.show(widget.context);
    }
  }


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
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(30.r),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final mode = context.watch<ThemeService>().mode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSpecialOption(
          icon: Ionicons.musical_note_outline,
          label: 'Al terminar canción',
          onTap: _activateEndOfSong,
          color: AppColors.primaryBlueMid,
          mode: mode,
        ),

        _buildEditableOption(_slot1, _kSlot1, mode),
        _buildEditableOption(_slot2, _kSlot2, mode),

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

        SizedBox(height: 10.h),
      ],
    );
  }


  Widget _buildEditableOption(Duration d, String key, AppThemeMode mode) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
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
          size: 20.r,
        ),
        title: Text(
          _label(d),
          style: TextStyle(
            color: AppColors.textPrimary(mode), 
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: () => _activate(d),
        trailing: GestureDetector(
          onTap: () => _editSlot(key, d),
          child: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueMid.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primaryBlueMid.withOpacity(0.5),
              ),
            ),
            child: Icon(
              Ionicons.pencil_outline,
              color: AppColors.primaryBlueMid,
              size: 16.r,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSpecialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required AppThemeMode mode,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withOpacity(0.5)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withOpacity(0.25), AppColors.surface(mode)],
          stops: const [0.0, 0.7],
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20.r),
        title: Text(
          label, 
          style: TextStyle(
            color: color, 
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: onTap,
      ),
    );
  }
}

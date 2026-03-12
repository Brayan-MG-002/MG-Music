// Copyright © 2026 Brayan Medrano - MG Music
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/services/global_modal_service.dart';

class TvExitDialog extends StatefulWidget {
  const TvExitDialog({super.key});

  @override
  State<TvExitDialog> createState() => _TvExitDialogState();
}

class _TvExitDialogState extends State<TvExitDialog> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (!_shown) {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final confirmed = await GlobalModalService.showConfirmation(
          title: '¿Salir?',
          message: '¿Quieres salir de MG Music?',
          icon: Ionicons.power,
          confirmText: 'Salir',
          cancelText: 'Cancelar',
          confirmButtonColor: Colors.redAccent,
        );
        if (!mounted) return;
        if (confirmed) {
          await AudioPlayerManager().savePosition();
          if (mounted) Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pop(false);
        }
      });
    }
    return const SizedBox.shrink();
  }
}

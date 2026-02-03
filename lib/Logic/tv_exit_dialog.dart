// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo de confirmación para salir de la TV

import 'package:flutter/material.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

/// Diálogo de confirmación para salir de la aplicación en TV
class TvExitDialog extends StatelessWidget {
  const TvExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.shade900, width: 2),
      ),
      title: const Text('¿Salir?', style: TextStyle(color: Colors.white)),
      content: const Text(
        '¿Quieres salir de MG Music?',
        style: TextStyle(color: Colors.white70),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TvFocusableItem(
          onTap: () => Navigator.of(context).pop(false),
          borderRadius: 8,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        TvFocusableItem(
          onTap: () async {
            await AudioPlayerManager().savePosition();
            if (context.mounted) Navigator.of(context).pop(true);
          },
          borderRadius: 8,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Salir',
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

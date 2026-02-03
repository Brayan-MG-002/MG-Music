// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo de carga durante búsqueda de actualizaciones

import 'package:flutter/material.dart';

/// Diálogo de carga que se muestra mientras se buscan actualizaciones
class UpdateLoadingDialog extends StatelessWidget {
  const UpdateLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Buscando actualizaciones...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor espera',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

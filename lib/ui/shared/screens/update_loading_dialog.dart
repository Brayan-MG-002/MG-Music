// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo de carga durante búsqueda de actualizaciones

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:mg_music/services/ui/theme_service.dart';

/// Diálogo de carga que se muestra mientras se buscan actualizaciones
class UpdateLoadingDialog extends StatelessWidget {
  const UpdateLoadingDialog({super.key});

  @override
  /// Construye el diálogo de carga mientras se buscan actualizaciones
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background(mode),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.themeBorder(mode).withOpacity(0.3),
                    AppColors.background(mode).withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.7],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.themeBorder(mode),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeBorder(mode).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlueMid,
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Buscando actualizaciones...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary(mode),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor espera',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(mode),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

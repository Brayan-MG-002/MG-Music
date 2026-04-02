// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de carga animada que se muestra durante la verificación de nuevas versiones.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class UpdateLoadingDialog extends StatelessWidget {
  const UpdateLoadingDialog({super.key});

  @override
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
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.themeBorder(mode),
                  width: 1.2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeBorder(mode).withOpacity(0.3),
                    blurRadius: 12.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 40.r,
                      width: 40.r,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlueMid,
                        ),
                        strokeWidth: 2.r,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Buscando actualizaciones...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary(mode),
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor espera',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(mode),
                        fontSize: 12.sp,
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

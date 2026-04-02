// Copyright © 2026 Brayan Medrano - MG Music
// Servicio para la gestión de modales inferiores (BottomSheets) personalizados, con soporte para opciones dinámicas y animaciones staggered.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class BottomModalOption {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;

  BottomModalOption({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.color,
    this.textColor,
  });
}

class BottomModalService {
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    Uint8List? artwork,
    List<BottomModalOption>? options,
    Widget? heroContent,
    Widget? child,
    String? footerText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final mode = Provider.of<ThemeService>(context, listen: false).mode;

        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          child: Container(
            color: AppColors.primaryBlueMid, // Borde superior simulado
            padding: EdgeInsets.only(top: 2.h),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.background(mode),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background(mode),
                    AppColors.primaryBlueMid.withOpacity(0.5),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
              child: AnimationLimiter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0.h,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Cabecera (Imagen + textos)
                      Row(
                        children: [
                          AnimationConfiguration.synchronized(
                            child: ScaleAnimation(
                              scale: 0.5,
                              duration: const Duration(milliseconds: 400),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: artwork != null
                                    ? Image.memory(
                                        artwork,
                                        width: 55.r,
                                        height: 55.r,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/MG-I-T.png',
                                        width: 55.r,
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                if (subtitle != null)
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: AppColors.textSecondary(mode),
                                      fontSize: 14.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Divider(
                        color: AppColors.themeBorder(mode).withOpacity(0.4),
                      ),
                      SizedBox(height: 10.h),

                      // Contenido hero (imagen grande, etc.)
                      if (heroContent != null) ...[
                        Center(child: heroContent),
                        SizedBox(height: 20.h),
                      ],

                      // Contenido central (texto, inputs, etc.)
                      if (child != null) ...[child, SizedBox(height: 20.h)],

                      // Generación dinámica de opciones
                      if (options != null)
                        ...options.map((opt) => _buildModalOption(opt, mode)),

                      // Pie de página (texto legal/informativo)
                      if (footerText != null) ...[
                        SizedBox(height: 20.h),
                        Text(
                          footerText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildModalOption(BottomModalOption option, AppThemeMode mode) {
    final color = option.color ?? AppColors.primaryBlueMid;
    final textColor = option.textColor ?? AppColors.textPrimary(mode);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2.w),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withOpacity(0.3), AppColors.background(mode)],
          stops: const [0.0, 0.7],
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
        visualDensity: VisualDensity.compact,
        leading: Icon(option.icon, color: textColor, size: 24.r),
        title: Text(
          option.label,
          style: TextStyle(color: textColor, fontSize: 13.sp),
        ),
        subtitle: option.subtitle != null
            ? Text(
                option.subtitle!,
                style: TextStyle(
                  color: AppColors.textSecondary(mode).withOpacity(0.7),
                  fontSize: 11.sp,
                ),
              )
            : null,
        onTap: option.onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      ),
    );
  }
}

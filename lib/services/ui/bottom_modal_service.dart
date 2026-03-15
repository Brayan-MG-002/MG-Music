import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Modelo simple para definir una opción del menú
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
  /// Muestra un modal inferior con estilo personalizado y opciones dinámicas.
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: AppColors.primaryBlueMid, // Borde superior simulado
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              padding: const EdgeInsets.all(16),
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
                      verticalOffset: 50.0,
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
                                borderRadius: BorderRadius.circular(8),
                                child: artwork != null
                                    ? Image.memory(
                                        artwork,
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/MG-I-T.png',
                                        width: 55,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (subtitle != null)
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: AppColors.textSecondary(mode),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        color: AppColors.themeBorder(mode).withOpacity(0.4),
                      ),
                      const SizedBox(height: 10),

                      // Contenido hero (imagen grande, etc.)
                      if (heroContent != null) ...[
                        Center(child: heroContent),
                        const SizedBox(height: 20),
                      ],

                      // Contenido central (texto, inputs, etc.)
                      if (child != null) ...[child, const SizedBox(height: 20)],

                      // Generación dinámica de opciones
                      if (options != null)
                        ...options.map((opt) => _buildModalOption(opt, mode)),

                      // Pie de página (texto legal/informativo)
                      if (footerText != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          footerText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 14,
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

  /// Construye un ítem de opción para el modal inferior
  static Widget _buildModalOption(BottomModalOption option, AppThemeMode mode) {
    final color = option.color ?? AppColors.primaryBlueMid;
    final textColor = option.textColor ?? AppColors.textPrimary(mode);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withOpacity(0.3), AppColors.background(mode)],
          stops: const [0.0, 0.7],
        ),
      ),
      child: ListTile(
        leading: Icon(option.icon, color: textColor),
        title: Text(option.label, style: TextStyle(color: textColor)),
        subtitle: option.subtitle != null
            ? Text(
                option.subtitle!,
                style: TextStyle(
                  color: AppColors.textSecondary(mode).withOpacity(0.7),
                  fontSize: 12,
                ),
              )
            : null,
        onTap: option.onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

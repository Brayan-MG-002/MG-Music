// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo de actualización disponible

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mg_music/Logic/version_model.dart';
import 'package:mg_music/services/theme_service.dart';

/// Diálogo que muestra información de actualización disponible
class UpdateDialog extends StatefulWidget {
  final VersionModel versionData;
  final bool isTv;

  const UpdateDialog({super.key, required this.versionData, this.isTv = false});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  AnimationController? _glowController;

  /// Abre la URL en el navegador
  Future<void> _launchURL() async {
    try {
      final url = widget.versionData.websiteUrl;
      if (kDebugMode) print('Intentando abrir URL: $url');

      final uri = Uri.parse(url);

      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (kDebugMode) print('URL lanzada con inAppBrowserView');
      } catch (e) {
        if (kDebugMode) print('Error con inAppBrowserView: $e');
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (kDebugMode) print('URL lanzada con externalApplication');
        } catch (e2) {
          if (kDebugMode) print('Error con externalApplication: $e2');
          try {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            if (kDebugMode) print('URL lanzada con platformDefault');
          } catch (e3) {
            if (kDebugMode) print('Error con platformDefault: $e3');
            await launchUrl(uri);
            if (kDebugMode) print('URL lanzada sin modo específico');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error abriendo URL: $e');
    }
  }

  @override
  /// Inicializa controladores de animación y pulso crítico
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.linear,
    );
    _entryController.forward();

    if (widget.versionData.importance == 'critical') {
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      _glowController?.repeat(reverse: true);
    }
  }

  @override
  /// Libera recursos de animación
  void dispose() {
    _entryController.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  /// Obtiene el color según la importancia
  Color _getImportanceColor() {
    switch (widget.versionData.importance) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  /// Obtiene el ícono según la importancia
  IconData _getImportanceIcon() {
    switch (widget.versionData.importance) {
      case 'critical':
        return Icons.error_outline;
      case 'high':
        return Icons.warning_amber;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.update;
    }
  }

  /// Obtiene el nombre en texto según la importancia
  String _getImportanceName() {
    switch (widget.versionData.importance) {
      case 'critical':
        return 'Alta';
      case 'high':
        return 'Media-Alta';
      case 'medium':
        return 'Media';
      default:
        return 'Normal';
    }
  }

  @override
  /// Construye el diálogo de actualización con animaciones y acciones
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final importanceColor = _getImportanceColor();
    final importanceIcon = _getImportanceIcon();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            if (_glowController != null) _glowController!,
          ]),
          builder: (context, _) {
            List<BoxShadow> shadows = [
              BoxShadow(
                color: AppColors.themeBorder(mode).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ];
            if (_glowController != null) {
              final glowValue = _glowController!.value;
              shadows.add(
                BoxShadow(
                  color: Colors.red.withOpacity(0.5 * glowValue),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              );
            }

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
                      constraints: BoxConstraints(
                        maxWidth: widget.isTv ? 800 : 500,
                      ),
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
                          width: 2,
                        ),
                        boxShadow: shadows,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(widget.isTv ? 32.0 : 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    importanceIcon,
                                    color: importanceColor,
                                    size: widget.isTv ? 32 : 24,
                                  ),
                                  SizedBox(width: widget.isTv ? 16 : 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nueva versión',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.textPrimary(
                                                  mode,
                                                ),
                                                fontSize: widget.isTv
                                                    ? 24
                                                    : null,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'v${widget.versionData.version} · ${_getImportanceName()}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: importanceColor,
                                                fontSize: widget.isTv
                                                    ? 16
                                                    : null,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: widget.isTv ? 28 : 20),
                              Text(
                                widget.versionData.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary(mode),
                                      fontWeight: FontWeight.w600,
                                      fontSize: widget.isTv ? 20 : null,
                                    ),
                              ),
                              SizedBox(height: widget.isTv ? 20 : 16),
                              if (widget.versionData.changelog.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(
                                    widget.isTv ? 16 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(mode),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.themeBorder(
                                        mode,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    widget.versionData.changelog,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary(mode),
                                          height: 1.5,
                                          fontSize: widget.isTv ? 16 : null,
                                        ),
                                  ),
                                ),
                              if (widget.versionData.changelog.isNotEmpty)
                                SizedBox(height: widget.isTv ? 28 : 20),
                              SizedBox(height: widget.isTv ? 16 : 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (!widget.versionData.forceUpdate)
                                    Expanded(
                                      child: _NeonButton(
                                        label: 'Ahora no',
                                        onPressed: () => Navigator.pop(context),
                                        color: Colors.grey,
                                        isTv: widget.isTv,
                                        mode: mode,
                                      ),
                                    ),
                                  if (!widget.versionData.forceUpdate)
                                    SizedBox(width: widget.isTv ? 16 : 12),
                                  Expanded(
                                    child: _NeonButton(
                                      label: 'Actualizar',
                                      onPressed: () async {
                                        await _launchURL();
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      color: importanceColor,
                                      isTv: widget.isTv,
                                      mode: mode,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Botón personalizado con estilo neón y degradado
class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isTv;
  final AppThemeMode mode;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.mode,
    this.isTv = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.6), AppColors.background(mode)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isTv ? 16 : 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTv ? 16 : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

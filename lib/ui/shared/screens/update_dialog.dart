// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo personalizado para informar sobre nuevas actualizaciones disponibles, con soporte para Mobile y TV.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/models/version_model.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/ui/shared/screens/update_screen.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';

class UpdateDialog extends StatefulWidget {
  final VersionModel versionData;
  final bool isTv;
  final bool isBeta;

  const UpdateDialog({
    super.key,
    required this.versionData,
    this.isTv = false,
    this.isBeta = false,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  AnimationController? _glowController;


  @override
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
    if (widget.isBeta) return 'Beta';
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
                blurRadius: 15.r,
                spreadRadius: 1.r,
              ),
            ];
            if (_glowController != null) {
              final glowValue = _glowController!.value;
              shadows.add(
                BoxShadow(
                  color: Colors.red.withOpacity(0.5 * glowValue),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                ),
              );
            }

            return PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: widget.isTv ? 800.w : 420.w,
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
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.themeBorder(mode),
                          width: 1.5.w,
                        ),
                        boxShadow: shadows,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(widget.isTv ? 32.r : 20.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    importanceIcon,
                                    color: importanceColor,
                                    size: widget.isTv ? 32.r : 22.r,
                                  ),
                                  SizedBox(width: widget.isTv ? 16.w : 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.isBeta
                                              ? 'Versión Beta disponible'
                                              : 'Nueva versión',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.textPrimary(
                                                  mode,
                                                ),
                                                fontSize: widget.isTv
                                                    ? 24.sp
                                                    : 16.sp,
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
                                                    ? 16.sp
                                                    : 11.sp,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: widget.isTv ? 24.h : 18.h),
                              Text(
                                widget.versionData.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary(mode),
                                      fontWeight: FontWeight.w600,
                                      fontSize: widget.isTv ? 20.sp : 15.sp,
                                    ),
                              ),
                              SizedBox(height: widget.isTv ? 20.h : 16.h),
                              if (widget.versionData.changelog.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(
                                    widget.isTv ? 16.r : 12.r,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(mode),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: AppColors.themeBorder(
                                        mode,
                                      ).withOpacity(0.2),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    widget.versionData.changelog,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary(mode),
                                          height: 1.4,
                                          fontSize: widget.isTv ? 16.sp : 13.sp,
                                        ),
                                  ),
                                ),
                              if (widget.versionData.changelog.isNotEmpty)
                                SizedBox(height: widget.isTv ? 24.h : 18.h),
                              SizedBox(height: widget.isTv ? 12.h : 4.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                    Expanded(
                                      child: _NeonButton(
                                        label: 'Ahora no',
                                        onPressed: () async {
                                          try {
                                            final prefs = await SharedPreferences.getInstance();
                                            if (widget.isBeta) {
                                              await prefs.setInt(
                                                'ignored_beta_version_code',
                                                widget.versionData.versionCode,
                                              );
                                            }
                                            // Snooze 2 días + marcar actualización pendiente
                                            final until = DateTime.now()
                                                .add(const Duration(days: 2))
                                                .millisecondsSinceEpoch;
                                            await prefs.setInt('update_snoozed_until', until);
                                            await prefs.setInt('snoozed_version_code', widget.versionData.versionCode);
                                            await prefs.setInt('pending_update_version_code', widget.versionData.versionCode);
                                          } catch (e) {}
                                          if (context.mounted) Navigator.pop(context);
                                        },
                                        color: Colors.grey,
                                        isTv: widget.isTv,
                                        mode: mode,
                                      ),
                                    ),
                                  if (!widget.versionData.forceUpdate)
                                    SizedBox(width: widget.isTv ? 16.w : 12.w),
                                  Expanded(
                                    child: _NeonButton(
                                      label: 'Actualizar',
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => UpdateScreen(
                                              versionData: widget.versionData,
                                              isTv: widget.isTv,
                                            ),
                                            fullscreenDialog: true,
                                          ),
                                        );
                                      },
                                      color: importanceColor,
                                      isTv: widget.isTv,
                                      autofocus: widget.isTv,
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

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isTv;
  final bool autofocus;
  final AppThemeMode mode;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.mode,
    this.isTv = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget buttonContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.6), AppColors.background(mode)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10.r,
            spreadRadius: 1.r,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30.r),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isTv ? 16 : 12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTv ? 16.sp : 13.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isTv) {
      return TvFocusableItem(
        onTap: onPressed,
        autofocus: autofocus,
        borderRadius: 30.r,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}

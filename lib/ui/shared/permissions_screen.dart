// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de gestión de permisos y configuración inicial (Onboarding) para Mobile y TV.

import 'dart:io';

import 'package:animations/animations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/ui/shared/splash.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/theme_settings_modal.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/folder_settings_modal.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/logic/backup_service.dart';

class PermissionsScreen extends StatefulWidget {
  final bool isTv;
  const PermissionsScreen({super.key, required this.isTv});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();

  static Future<List<Map<String, dynamic>>> getRequiredPermissions(
    bool isTv,
  ) async {
    final List<Map<String, dynamic>> perms = [];

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        perms.add({
          'permission': Permission.audio,
          'title': 'Música y Audio',
          'subtitle':
              'Permite el acceso para encontrar y reproducir tus canciones con la mejor calidad.',
          'icon': Ionicons.musical_notes,
        });
        perms.add({
          'permission': Permission.notification,
          'title': 'Notificaciones',
          'subtitle':
              'Mantén el control de tu música desde la barra de estado y pantalla de bloqueo.',
          'icon': Ionicons.notifications_outline,
        });
      } else {
        perms.add({
          'permission': Permission.storage,
          'title': 'Acceso a Archivos',
          'subtitle':
              'Necesario para escanear tu biblioteca musical y mostrar tus canciones.',
          'icon': Ionicons.folder_open_outline,
        });
      }

      if (sdkInt >= 30) {
        perms.add({
          'permission': Permission.manageExternalStorage,
          'title': 'Acceso a Todos los Archivos',
          'subtitle':
              'Necesario para guardar las copias de seguridad y las apk de las actualizaciones de la aplicación.',
          'icon': Ionicons.folder_open_outline,
        });
      }

      perms.add({
        'permission': Permission.requestInstallPackages,
        'title': 'Instalar Actualizaciones',
        'subtitle': 'Permite instalar la actualización cuando ya se descargue.',
        'icon': Ionicons.download_outline,
      });
    }
    return perms;
  }

  static Future<bool> checkAllPermissions(bool isTv) async {
    final prefs = await SharedPreferences.getInstance();
    final bool themeConfigured =
        prefs.getBool('theme_selected_onboarding') ?? false;
    final bool backupAsked = prefs.getBool('backup_asked_onboarding') ?? false;
    final bool folderConfigured =
        prefs.getBool('folder_configured_onboarding') ?? false;

    if (!backupAsked) return false;
    if (!folderConfigured) return false;
    if (!themeConfigured) return false;

    for (final permData in await getRequiredPermissions(isTv)) {
      if (permData['permission'] == null) continue;
      final perm = permData['permission'] as Permission;
      final status = await perm.status;
      if (!status.isGranted && !status.isLimited) {
        // Verificar si este permiso ha sido omitido permanentemente
        final isSkipped =
            prefs.getBool('skipped_perm_${perm.toString()}') ?? false;
        if (!isSkipped) return false;
      }
    }
    return true;
  }
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  List<Map<String, dynamic>> _permissionsToRequest = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _detectedBackups = [];
  bool _isLoadingBackups = false;

  // Animación del brillo del logo
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _checkPermissionsAndBuildList().then((_) {
      _loadBackups();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndBuildList() async {
    final prefs = await SharedPreferences.getInstance();
    final missingPermissions = <Map<String, dynamic>>[];
    for (final permData in await PermissionsScreen.getRequiredPermissions(
      widget.isTv,
    )) {
      if (permData['permission'] != null) {
        final perm = permData['permission'] as Permission;
        final status = await perm.status;
        if (!status.isGranted && !status.isLimited) {
          // Si no está otorgado, verificamos si fue omitido
          final isSkipped =
              prefs.getBool('skipped_perm_${perm.toString()}') ?? false;
          if (!isSkipped) {
            missingPermissions.add(permData);
          }
        }
      }
    }

    final bool themeConfigured =
        prefs.getBool('theme_selected_onboarding') ?? false;
    final bool backupAsked = prefs.getBool('backup_asked_onboarding') ?? false;
    final bool folderConfigured =
        prefs.getBool('folder_configured_onboarding') ?? false;

    if (!backupAsked) {
      missingPermissions.add({
        'isBackupRestore': true,
        'title': 'Restaurar Copia',
        'subtitle':
            '¿Tienes una copia de seguridad anterior? Restáurala para recuperar tus configuraciones, listas y favoritos.',
        'icon': Ionicons.cloud_download_outline,
      });
    }

    if (!folderConfigured) {
      missingPermissions.add({
        'isFolderSelection': true,
        'title': 'Ubicación de Música',
        'subtitle': 'Configura dónde debe buscar la música la aplicación.',
        'icon': Ionicons.folder_open_outline,
      });
    }

    if (!themeConfigured) {
      missingPermissions.add({
        'isThemeSelection': true,
        'title': 'Experiencia Visual',
        'subtitle':
            'Elige el tema con el que prefieres usar la aplicación. Puedes cambiarlo luego en Ajustes.',
        'icon': Ionicons.color_palette_outline,
      });
    }

    if (!mounted) return;

    if (missingPermissions.isEmpty) {
      _navigateToSplash();
    } else {
      setState(() {
        _permissionsToRequest = missingPermissions;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBackups() async {
    final hasBackupPage =
        _permissionsToRequest.any((p) => p['isBackupRestore'] == true);
    if (!hasBackupPage) return;

    setState(() => _isLoadingBackups = true);
    try {
      final backups = await BackupService().listBackups();
      if (mounted) {
        setState(() {
          _detectedBackups = backups.take(3).toList();
          _isLoadingBackups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBackups = false);
    }
  }

  Future<void> _requestPermission(Map<String, dynamic> item,
      [String? backupPath]) async {
    if (item['isBackupRestore'] == true) {
      final prefs = await SharedPreferences.getInstance();

      // Si el item tiene un backupPath, es una restauración directa desde la lista
      if (backupPath != null) {
        final result = await BackupService().importFromFile(File(backupPath));
        if (result['success'] == true) {
          await prefs.setBool('backup_asked_onboarding', true);
          await prefs.setBool('theme_selected_onboarding', true);
          _navigateToSplash();
          return;
        }
      }

      await prefs.setBool('backup_asked_onboarding', true);

      final result = await BackupService().importBackup();
      if (result['success'] == true) {
        await prefs.setBool('theme_selected_onboarding', true);
        _navigateToSplash();
      } else {
        if (result['message'] == 'Importación cancelada.') {
          return;
        }
        _goToNextPage();
      }
      return;
    }

    if (item['isThemeSelection'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_selected_onboarding', true);
      _goToNextPage();
      return;
    }

    if (item['isFolderSelection'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('folder_configured_onboarding', true);
      _goToNextPage();
      return;
    }

    final permission = item['permission'] as Permission;
    final status = await permission.request();

    if (status.isGranted || status.isLimited) {
      _goToNextPage();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        await openAppSettings();
      }
      _goToNextPage();
    } else {
      _goToNextPage();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _permissionsToRequest.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      _navigateToSplash();
    }
  }

  void _navigateToSplash() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    final horizontalPadding = widget.isTv ? 100.w : 24.w;
    final imageSize = widget.isTv ? 200.r : 150.r;
    final titleSize = widget.isTv ? 32.sp : 24.sp;
    final subtitleSize = widget.isTv ? 20.sp : 16.sp;
    final buttonTextSize = widget.isTv ? 18.sp : 16.sp;

    final mode = context.watch<ThemeService>().mode;

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background(mode),
              AppColors.background(mode),
              AppColors.primaryBlueMid.withOpacity(0.4),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlueMid,
                    strokeWidth: 3.w,
                  ),
                )
              : Center(
                  child: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (child, primaryAnimation, secondaryAnimation) {
                      return SharedAxisTransition(
                        animation: primaryAnimation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.horizontal,
                        fillColor: Colors.transparent,
                        child: child,
                      );
                    },
                    child: _permissionsToRequest.isEmpty
                        ? const SizedBox.shrink()
                        : _buildPermissionPage(
                            key: ValueKey(_currentPage),
                            item: _permissionsToRequest[_currentPage],
                            imageSize: imageSize,
                            horizontalPadding: horizontalPadding,
                            onPressed: () => _requestPermission(
                              _permissionsToRequest[_currentPage],
                            ),
                            onSkip: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final item = _permissionsToRequest[_currentPage];
                              if (item['isBackupRestore'] == true) {
                                await prefs.setBool(
                                    'backup_asked_onboarding', true);
                              }
                              _goToNextPage();
                            },
                            onRestoreDirect: (path) => _requestPermission(
                              _permissionsToRequest[_currentPage],
                              path,
                            ),
                            titleSize: titleSize,
                            subtitleSize: subtitleSize,
                            buttonTextSize: buttonTextSize,
                            mode: mode,
                          ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionPage({
    Key? key,
    required Map<String, dynamic> item,
    required double imageSize,
    required double horizontalPadding,
    required VoidCallback onPressed,
    required VoidCallback onSkip,
    required Function(String) onRestoreDirect,
    required double titleSize,
    required double subtitleSize,
    required double buttonTextSize,
    required AppThemeMode mode,
  }) {
    final bool isBackupRestore = item['isBackupRestore'] == true;
    final bool isThemeSelection = item['isThemeSelection'] == true;
    final bool isFolderSelection = item['isFolderSelection'] == true;
    final bool isComplexPage = isThemeSelection || isFolderSelection;

    final String title = item['title'];
    final String subtitle = item['subtitle'];
    final IconData icon = item['icon'];

    final adjustedImageSize = isComplexPage ? imageSize * 0.75 : imageSize;
    final topSpacing = isComplexPage ? 16.h : 32.h;
    final bottomSpacing = isComplexPage ? 24.h : 40.h;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: widget.isTv ? 40.h : 20.h,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.isTv ? 700.w : 500.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 500),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0.h,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlueMid.withOpacity(
                              0.25 * _glowController.value,
                            ),
                            blurRadius: 32.r,
                            spreadRadius: 6.r,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/MG-I-T.png',
                        width: adjustedImageSize,
                        height: adjustedImageSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Ionicons.musical_notes,
                          size: adjustedImageSize,
                          color: AppColors.primaryBlueMid,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: topSpacing),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(mode),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: AppColors.textSecondary(mode),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: bottomSpacing),
                if (isThemeSelection)
                  ThemeSettingsContent(isTv: widget.isTv)
                else if (isFolderSelection)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: FolderSettingsContent(isTv: widget.isTv),
                  )
                else
                  widget.isTv
                      ? TvFocusableItem(
                          onTap: onPressed,
                          borderRadius: 30.r,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryBlueMid,
                                  AppColors.background(mode),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(
                                color: AppColors.themeBorder(mode),
                                width: 2.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  color: AppColors.textPrimary(mode),
                                  size: 24.r,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  isBackupRestore
                                      ? 'Restaurar Copia'
                                      : 'Conceder Permiso',
                                  style: TextStyle(
                                    fontSize: buttonTextSize,
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _FocusableButton(
                          onTap: onPressed,
                          isPrimary: true,
                          mode: mode,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                color: AppColors.textPrimary(mode),
                                size: 24.r,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                isBackupRestore
                                    ? 'Restaurar Copia'
                                    : 'Conceder Permiso',
                                style: TextStyle(
                                  fontSize: buttonTextSize,
                                  color: AppColors.textPrimary(mode),
                                ),
                              ),
                            ],
                          ),
                        ),
                if (isBackupRestore) ...[
                  if (_isLoadingBackups)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: CircularProgressIndicator(strokeWidth: 2.w),
                    )
                  else if (_detectedBackups.isNotEmpty)
                    _buildBackupList(mode)
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Text(
                        'No se encontraron copias automáticas.',
                        style: TextStyle(
                          color: AppColors.textSecondary(mode).withOpacity(0.5),
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  SizedBox(height: 16.h),
                  _buildSkipButton(onSkip, mode, buttonTextSize),
                ],
                SizedBox(height: 24.h),
                if (isThemeSelection || isFolderSelection)
                  widget.isTv
                      ? TvFocusableItem(
                          onTap: onPressed,
                          borderRadius: 30.r,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlueMid.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Text(
                              'Continuar a la App',
                              style: TextStyle(
                                color: AppColors.primaryBlueMid,
                                fontSize: buttonTextSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: onPressed,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primaryBlueMid,
                              width: 1.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 30.w,
                              vertical: 12.h,
                            ),
                            backgroundColor:
                                AppColors.primaryBlueMid.withOpacity(0.1),
                          ),
                          child: Text(
                            'Continuar a la App',
                            style: TextStyle(
                              color: AppColors.textPrimary(mode),
                              fontWeight: FontWeight.bold,
                              fontSize: buttonTextSize,
                            ),
                          ),
                        ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupList(AppThemeMode mode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12.h, top: 20.h),
          child: Text(
            'Copias detectadas:',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._detectedBackups.map((backup) {
          final metadata = backup['metadata'] as Map<String, dynamic>?;
          final date = backup['modified'] as DateTime;
          final dateStr = "${date.day}/${date.month}/${date.year}";

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueMid.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryBlueMid.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: ListTile(
              onTap: () {
                _requestPermission(
                    _permissionsToRequest[_currentPage], backup['path']);
              },
              leading: Icon(Ionicons.archive_outline,
                  color: AppColors.primaryBlueMid),
              title: Text(
                'Copia del $dateStr',
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                metadata?['summary'] ?? 'Sin detalles',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 12.sp,
                ),
              ),
              trailing: Icon(
                Ionicons.chevron_forward,
                size: 16.r,
                color: AppColors.textSecondary(mode),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSkipButton(
    VoidCallback onSkip,
    AppThemeMode mode,
    double textSize,
  ) {
    return OutlinedButton(
      onPressed: onSkip,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primaryBlueMid, width: 1.w),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
      ),
      child: Text(
        'Omitir y continuar',
        style: TextStyle(
          color: AppColors.primaryBlueMid,
          fontWeight: FontWeight.bold,
          fontSize: textSize,
        ),
      ),
    );
  }
}

class _FocusableButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isPrimary;
  final AppThemeMode mode;

  const _FocusableButton({
    required this.onTap,
    required this.child,
    required this.isPrimary,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isPrimary
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueMid.withOpacity(0.8),
                  AppColors.background(mode),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.themeBorder(mode),
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlueMid.withOpacity(0.3),
                  blurRadius: 10.r,
                  spreadRadius: 1.r,
                ),
              ],
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
            child: child,
          ),
        ),
      ),
    );
  }
}

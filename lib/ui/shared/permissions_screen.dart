// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de solicitud de permisos para Mobile y TV

import 'dart:io' show Platform;

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

/// Pantalla de solicitud de permisos adaptativa para Mobile y TV
class PermissionsScreen extends StatefulWidget {
  final bool isTv;
  const PermissionsScreen({super.key, required this.isTv});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();

  /// Obtiene la lista de permisos requeridos según el dispositivo
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
    }
    return perms;
  }

  /// Verifica si todos los permisos están otorgados
  static Future<bool> checkAllPermissions(bool isTv) async {
    for (final permData in await getRequiredPermissions(isTv)) {
      final status = await (permData['permission'] as Permission).status;
      if (!status.isGranted && !status.isLimited) {
        return false;
      }
    }
    return true;
  }
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  int _currentPage = 0;
  List<Map<String, dynamic>> _permissionsToRequest = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndBuildList();
  }

  /// Verifica permisos faltantes y construye la lista
  Future<void> _checkPermissionsAndBuildList() async {
    final missingPermissions = <Map<String, dynamic>>[];
    for (final permData in await PermissionsScreen.getRequiredPermissions(
      widget.isTv,
    )) {
      final status = await (permData['permission'] as Permission).status;
      if (!status.isGranted && !status.isLimited) {
        missingPermissions.add(permData);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final bool themeConfigured =
        prefs.getBool('theme_selected_onboarding') ?? false;

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

  /// Solicita un permiso específico o guarda la preferencia de tema
  Future<void> _requestPermission(Map<String, dynamic> item) async {
    if (item['isThemeSelection'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_selected_onboarding', true);
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

  /// Avanza a la siguiente "tarjeta" de permisos con animación
  void _goToNextPage() {
    if (_currentPage < _permissionsToRequest.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      _navigateToSplash();
    }
  }

  /// Navega a la pantalla splash
  void _navigateToSplash() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  /// Construye la UI de la pantalla de permisos
  Widget build(BuildContext context) {
    final horizontalPadding = widget.isTv ? 100.0 : 24.0;
    final imageSize = widget.isTv ? 200.0 : 150.0;
    final titleSize = widget.isTv ? 32.0 : 24.0;
    final subtitleSize = widget.isTv ? 20.0 : 16.0;
    final buttonTextSize = widget.isTv ? 18.0 : 16.0;

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

  /// Construye una página de solicitud de permiso
  Widget _buildPermissionPage({
    Key? key,
    required Map<String, dynamic> item,
    required double imageSize,
    required double horizontalPadding,
    required VoidCallback onPressed,
    required double titleSize,
    required double subtitleSize,
    required double buttonTextSize,
    required AppThemeMode mode,
  }) {
    final bool isThemeSelection = item['isThemeSelection'] == true;
    final String title = item['title'];
    final String subtitle = item['subtitle'];
    final IconData icon = item['icon'];
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            Image.asset('assets/MG-I-T.png', width: imageSize),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(mode),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleSize,
                color: AppColors.textSecondary(mode),
              ),
            ),
            const SizedBox(height: 40),
            if (isThemeSelection)
              _buildThemeSelector(mode)
            else
              widget.isTv
                  ? TvFocusableItem(
                      onTap: onPressed,
                      borderRadius: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
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
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.themeBorder(mode),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: AppColors.textPrimary(mode)),
                            const SizedBox(width: 10),
                            Text(
                              'Conceder Permiso',
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
                          Icon(icon, color: AppColors.textPrimary(mode)),
                          const SizedBox(width: 10),
                          Text(
                            'Conceder Permiso',
                            style: TextStyle(
                              fontSize: buttonTextSize,
                              color: AppColors.textPrimary(mode),
                            ),
                          ),
                        ],
                      ),
                    ),
            const SizedBox(height: 20),
            if (isThemeSelection)
              widget.isTv
                  ? TvFocusableItem(
                      onTap: onPressed,
                      borderRadius: 30,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueMid.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
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
                        side: BorderSide(color: AppColors.primaryBlueMid),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        backgroundColor: AppColors.primaryBlueMid.withOpacity(
                          0.1,
                        ),
                      ),
                      child: Text(
                        'Continuar a la App',
                        style: TextStyle(
                          color: AppColors.textPrimary(mode),
                          fontWeight: FontWeight.bold,
                          fontSize: buttonTextSize,
                        ),
                      ),
                    )
            else if (!(title.contains('Audio') ||
                title.contains('Notific'))) ...[
              widget.isTv
                  ? TvFocusableItem(
                      onTap: _goToNextPage,
                      borderRadius: 30,
                      child: Text(
                        'Omitir por ahora',
                        style: TextStyle(
                          color: AppColors.textSecondary(mode),
                          fontSize: buttonTextSize - 2,
                        ),
                      ),
                    )
                  : _FocusableButton(
                      onTap: _goToNextPage,
                      isPrimary: false,
                      mode: mode,
                      child: Text(
                        'Omitir por ahora',
                        style: TextStyle(
                          color: AppColors.textSecondary(mode),
                          fontSize: buttonTextSize - 2,
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye el selector de tema
  Widget _buildThemeSelector(AppThemeMode mode) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(mode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.themeBorder(mode)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: isDark ? Colors.white : Colors.orange.shade700,
            size: 28,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Modo Oscuro',
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                isDark ? 'Activado por defecto' : 'Apagado',
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Switch(
            value: !isDark,
            activeColor: AppColors.primaryBlueMid,
            onChanged: (v) => themeService.toggle(),
          ),
        ],
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
              border: Border.all(color: AppColors.themeBorder(mode), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlueMid.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
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
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Gestión de solicitud de permisos con soporte Mobile y TV

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

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
          'title': 'Acceso a Audio y Multimedia',
          'subtitle': 'Para buscar y reproducir todas tus canciones.',
          'icon': Ionicons.musical_note,
        });
        perms.add({
          'permission': Permission.notification,
          'title': 'Notificaciones',
          'subtitle':
              'Para controlar la reproducción desde fuera de la app y en la pantalla de bloqueo.',
          'icon': Ionicons.notifications,
        });
      } else {
        perms.add({
          'permission': Permission.storage,
          'title': 'Acceso a Almacenamiento',
          'subtitle': 'Para buscar y reproducir todas tus canciones.',
          'icon': Ionicons.folder_open,
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
  late PageController _pageController;
  int _currentPage = 0;
  List<Map<String, dynamic>> _permissionsToRequest = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  /// Solicita un permiso específico
  Future<void> _requestPermission(Permission permission) async {
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

  /// Avanza a la siguiente página de permisos
  void _goToNextPage() {
    if (_currentPage < _permissionsToRequest.length - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
  Widget build(BuildContext context) {
    final horizontalPadding = widget.isTv ? 100.0 : 24.0;
    final imageSize = widget.isTv ? 200.0 : 150.0;
    final titleSize = widget.isTv ? 32.0 : 24.0;
    final subtitleSize = widget.isTv ? 20.0 : 16.0;
    final buttonTextSize = widget.isTv ? 18.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.blue.shade900),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _permissionsToRequest.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (_permissionsToRequest.isEmpty) {
                  return const SizedBox.shrink();
                }
                final item = _permissionsToRequest[index];
                return _buildPermissionPage(
                  icon: item['icon'],
                  title: item['title'],
                  subtitle: item['subtitle'],
                  imageSize: imageSize,
                  horizontalPadding: horizontalPadding,
                  onPressed: () => _requestPermission(item['permission']),
                  titleSize: titleSize,
                  subtitleSize: subtitleSize,
                  buttonTextSize: buttonTextSize,
                );
              },
            ),
    );
  }

  /// Construye una página de solicitud de permiso
  Widget _buildPermissionPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required double imageSize,
    required double horizontalPadding,
    required VoidCallback onPressed,
    required double titleSize,
    required double subtitleSize,
    required double buttonTextSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/MG-I-T.png', width: imageSize),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: subtitleSize, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          widget.isTv
              ? TvFocusableItem(
                  onTap: onPressed,
                  borderRadius: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Conceder Permiso',
                        style: TextStyle(
                          fontSize: buttonTextSize,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _FocusableButton(
                  onTap: onPressed,
                  color: Colors.blue.shade900,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Conceder Permiso',
                        style: TextStyle(
                          fontSize: buttonTextSize,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 20),
          // Solo mostrar el botón de omitir si NO es audio ni notificación
          if (!(title.contains('Audio') || title.contains('Notific'))) ...[
            widget.isTv
                ? TvFocusableItem(
                    onTap: _goToNextPage,
                    borderRadius: 30,
                    child: Text(
                      'Omitir por ahora',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: buttonTextSize - 2,
                      ),
                    ),
                  )
                : _FocusableButton(
                    onTap: _goToNextPage,
                    color: Colors.transparent,
                    child: Text(
                      'Omitir por ahora',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: buttonTextSize - 2,
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Botón enfocable para uso en Mobile y TV
class _FocusableButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color color;

  const _FocusableButton({
    required this.onTap,
    required this.child,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        focusColor: Colors.white.withOpacity(0.1),
        hoverColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
          child: child,
        ),
      ),
    );
  }
}

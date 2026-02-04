// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de splash y detección de dispositivo

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mg_music/Mobile/mobile_main_screen.dart';
import 'package:mg_music/permissions_screen.dart';
import 'package:mg_music/TV/tv_main_screen.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/screens/update_dialog.dart';

/// Pantalla inicial de splash con animación y detección automática de dispositivo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isTv = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeAndNavigate();
  }

  /// Configura la animación de transición
  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  /// Inicializa la app y navega a la pantalla correcta
  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Detectar si es TV
    bool isTv = await _detectDeviceType();
    if (!mounted) return;

    // Verificar permisos
    final allGranted = await PermissionsScreen.checkAllPermissions(isTv);
    if (!mounted) return;

    if (!allGranted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PermissionsScreen(isTv: isTv)),
      );
      return;
    }

    // Navegar a pantalla principal
    _navigateToMainScreen(isTv);
  }

  /// Detecta si el dispositivo es TV o PC
  Future<bool> _detectDeviceType() async {
    if (Platform.isWindows || Platform.isLinux) return true;
    if (!Platform.isAndroid) return false;

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.systemFeatures.contains('android.software.leanback');
    } catch (_) {
      return false;
    }
  }

  /// Navega a la pantalla principal con tema correspondiente
  void _navigateToMainScreen(bool isTv) {
    _isTv = isTv;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => _buildMainApp(isTv)),
    );

    // Verificar actualizaciones después de navegar
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkForUpdates();
    });
  }

  /// Verifica si hay actualizaciones disponibles
  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateService.checkForUpdate();

    if (updateInfo['hasUpdate'] && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            UpdateDialog(versionData: updateInfo['data'], isTv: _isTv),
      );
    }
  }

  /// Construye la app principal con tema
  Widget _buildMainApp(bool isTv) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );

    final theme = isTv
        ? baseTheme.copyWith(
            navigationRailTheme: NavigationRailThemeData(
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.cyanAccent, width: 3),
              ),
              indicatorColor: Colors.transparent,
            ),
          )
        : baseTheme;

    return MaterialApp(
      theme: theme,
      home: isTv ? const TvMainScreen() : const MobileMainScreen(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/MG-I-T.png', width: 250),
              const SizedBox(height: 20),
              const Text(
                "Inspirada en Ado",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

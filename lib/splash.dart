// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de splash y detección de dispositivo

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/Mobile/mobile_main_screen.dart';
import 'package:mg_music/permissions_screen.dart';
import 'package:mg_music/TV/tv_main_screen.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/screens/update_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/animated_theme_switcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isTv = false;
  bool _isExiting = false;

  @override
  /// Inicializa el splash y arranca la navegación
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  /// Inicializa y navega a la pantalla adecuada
  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final isTv = await _detectDeviceType();
    if (!mounted) return;

    if (isTv) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    final allGranted = await PermissionsScreen.checkAllPermissions(isTv);
    if (!mounted) return;

    if (!allGranted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PermissionsScreen(isTv: isTv)),
      );
      return;
    }

    setState(() => _isExiting = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => _buildMainApp(isTv),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _checkForUpdates();
    });
  }

  /// Detecta si el dispositivo es TV o PC
  Future<bool> _detectDeviceType() async {
    if (Platform.isWindows || Platform.isLinux) return true;
    if (!Platform.isAndroid) return false;

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return deviceInfo.systemFeatures.contains('android.software.leanback') ||
          deviceInfo.systemFeatures.contains(
            'android.hardware.type.television',
          );
    } catch (_) {
      return false;
    }
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
    _isTv = isTv;

    return AnimatedThemeSwitcher(
      child: isTv ? const TvMainScreen() : const MobileMainScreen(),
    );
  }

  @override
  /// Construye la UI del splash
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      body: AnimatedOpacity(
        opacity: _isExiting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        child: Container(
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
          child: AnimationLimiter(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    duration: const Duration(milliseconds: 1000),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: Image.asset('assets/MG-I-T.png', width: 250),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 1000),
                      delay: const Duration(milliseconds: 200),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        Text(
                          "Inspirada en ",
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        ScaleAnimation(
                          child: Text(
                            "Ado",
                            style: TextStyle(
                              color: AppColors.primaryBlueMid,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

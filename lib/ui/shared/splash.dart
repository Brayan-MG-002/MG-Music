// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de splash: inicialización de la app, detección de dispositivo y verificación de actualizaciones.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/ui/mobile/mobile_main_screen.dart';
import 'package:mg_music/ui/shared/permissions_screen.dart';
import 'package:mg_music/ui/tv/tv_main_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/services/ui/animated_theme_switcher.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/ui/shared/screens/update_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceType { mobile, tv }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    bool navigated = false;
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && !navigated) {
        _forceNavigate();
      }
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final deviceType = await _detectDeviceType().timeout(
      const Duration(seconds: 3),
      onTimeout: () => DeviceType.mobile,
    );
    if (!mounted) return;

    final isTv = deviceType == DeviceType.tv;

    try {
      if (Platform.isAndroid) {
        if (isTv) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]).timeout(const Duration(seconds: 2));
        } else {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]).timeout(const Duration(seconds: 2));
        }
      }
    } catch (e) {}

    final allGranted = await PermissionsScreen.checkAllPermissions(isTv).timeout(
      const Duration(seconds: 4),
      onTimeout: () => false,
    );
    if (!mounted) return;

    if (!allGranted) {
      navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PermissionsScreen(isTv: isTv)),
      );
      return;
    }

    // Comprobar actualizaciones antes de entrar al Main
    try {
      final info = await UpdateService.checkForUpdate();
      if (info['hasUpdate']) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().millisecondsSinceEpoch;
        final snoozedUntil = prefs.getInt('update_snoozed_until') ?? 0;
        final snoozedCode = prefs.getInt('snoozed_version_code') ?? 0;
        final data = info['data'] as dynamic;
        final remoteCode = (data?.versionCode as int?) ?? 0;

        // Solo mostrar si no está pospuesto o es una versión distinta a la pospuesta
        if (now >= snoozedUntil || snoozedCode != remoteCode) {
          navigated = true;
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => UpdateScreen(
                  versionData: info['data'],
                  isTv: isTv,
                ),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {}

    setState(() => _isExiting = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            _buildMainApp(deviceType),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _forceNavigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MobileMainScreen(),
      ),
    );
  }

  Future<DeviceType> _detectDeviceType() async {
    if (Platform.isLinux) return DeviceType.tv;
    if (!Platform.isAndroid) return DeviceType.mobile;

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final isTv =
          deviceInfo.systemFeatures.contains('android.software.leanback') ||
          deviceInfo.systemFeatures.contains(
            'android.hardware.type.television',
          );
      return isTv ? DeviceType.tv : DeviceType.mobile;
    } catch (_) {
      return DeviceType.mobile;
    }
  }



  Widget _buildMainApp(DeviceType deviceType) {
    return AnimatedThemeSwitcher(
      child: switch (deviceType) {
        DeviceType.tv => const TvMainScreen(),
        DeviceType.mobile => const MobileMainScreen(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
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
                          child: Image.asset(
                            'assets/MG-I-T.png',
                            width: 250.r,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.music_note_rounded,
                              size: 140.r,
                              color: AppColors.primaryBlueMid,
                            ),
                          ),
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
                            fontSize: 18.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        ScaleAnimation(
                          child: Text(
                            "Ado",
                            style: TextStyle(
                              color: AppColors.primaryBlueMid,
                              fontSize: 22.sp,
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

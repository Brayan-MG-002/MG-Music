// Copyright © 2026 Brayan Medrano - MG Music
// Servicio para la gestión de la adaptabilidad de la UI (Responsividad) y el escalado dinámico de dimensiones según la resolución del dispositivo.

import 'package:flutter/material.dart';

class ResponsiveService {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double devicePixelRatio;
  static late double textScaleFactor;

  static const double baseWidth = 375.0;
  static const double baseHeight = 812.0;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
    
    // ignore: deprecated_member_use
    textScaleFactor = _mediaQueryData.textScaleFactor;
    
    _initialized = true;
  }

  static bool get isTablet => screenWidth > 600;

  static double w(double logicalWidth) {
    final scale = screenWidth / baseWidth;
    final dampenedScale = scale > 1 ? (1 + (scale - 1) * 0.6) : scale;
    return logicalWidth * dampenedScale.clamp(0.7, 1.15);
  }

  static double h(double logicalHeight) {
    final scale = screenHeight / baseHeight;
    final dampenedScale = scale > 1 ? (1 + (scale - 1) * 0.5) : scale;
    return logicalHeight * dampenedScale.clamp(0.7, 1.12);
  }

  static double sp(double fontSize) {
    final wScale = screenWidth / baseWidth;
    final hScale = screenHeight / baseHeight;
    
    final rawScale = (wScale * 0.6 + hScale * 0.4);
    final dampenedScale = rawScale > 1 ? (1 + (rawScale - 1) * 0.35) : rawScale;
    
    final finalScale = dampenedScale.clamp(0.70, 1.20);
    
    return fontSize * finalScale * textScaleFactor;
  }

  static double radius(double r) {
    final scale = screenWidth / baseWidth;
    final dampenedScale = scale > 1 ? (1 + (scale - 1) * 0.6) : scale;
    return r * dampenedScale.clamp(0.7, 1.18);
  }
}

extension ResponsiveExtension on num {
  double get w => ResponsiveService.w(toDouble());
  double get h => ResponsiveService.h(toDouble());
  double get sp => ResponsiveService.sp(toDouble());
  double get r => ResponsiveService.radius(toDouble());
}

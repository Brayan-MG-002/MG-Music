// Copyright © 2026 Brayan Medrano - MG Music
// Servicio para manejo de UI Responsiva y escalado DPI

import 'package:flutter/material.dart';

/// Servicio para calcular dimensiones adaptativas según el tamaño de pantalla y DPI.
/// Utiliza una resolución base (375x812) para proyectar dimensiones proporcionales.
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

  /// Inicializa los datos del dispositivo. Debe llamarse en el build de la pantalla principal.
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
    
    // ignore: deprecated_member_use
    textScaleFactor = _mediaQueryData.textScaleFactor;
    
    _initialized = true;
  }

  /// Indica si el dispositivo es una tablet (ancho > 600)
  static bool get isTablet => screenWidth > 600;

  /// Escala el ancho de forma proporcional.
  static double w(double logicalWidth) {
    final scale = screenWidth / baseWidth;
    // Crecimiento moderado (máximo 22%)
    final clampedScale = scale.clamp(0.8, 1.22);
    return logicalWidth * clampedScale;
  }

  /// Escala el alto de forma proporcional.
  static double h(double logicalHeight) {
    final scale = screenHeight / baseHeight;
    // Crecimiento vertical moderado (máximo 15%)
    final clampedScale = scale.clamp(0.8, 1.15);
    return logicalHeight * clampedScale;
  }

  /// Escala el tamaño de fuente considerando resolución y DPI.
  static double sp(double fontSize) {
    // Usar el promedio de escalas pero con peso en el ancho
    final wScale = screenWidth / baseWidth;
    final hScale = screenHeight / baseHeight;
    final avgScale = (wScale * 0.7 + hScale * 0.3).clamp(0.85, 1.2);
    
    return fontSize * avgScale * textScaleFactor;
  }

  /// Escala un radio de borde o valor circular.
  static double radius(double r) {
    final scale = screenWidth / baseWidth;
    return r * scale.clamp(0.8, 1.25);
  }
}

/// Extensiones para facilitar el uso: 10.w, 16.sp, etc.
extension ResponsiveExtension on num {
  double get w => ResponsiveService.w(toDouble());
  double get h => ResponsiveService.h(toDouble());
  double get sp => ResponsiveService.sp(toDouble());
  double get r => ResponsiveService.radius(toDouble());
}

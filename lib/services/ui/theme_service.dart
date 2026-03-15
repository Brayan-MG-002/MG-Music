// Copyright © 2026 Brayan Medrano - MG Music
// Servicio global de temas (claro / oscuro) — sin Provider externo, usa ChangeNotifier

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Enum de modo ────────────────────────────────────────────────────────────

enum AppThemeMode { dark, light }

// ─── Paleta de colores ────────────────────────────────────────────────────────

/// Todos los gradientes azul↔fondo (negro en oscuro, blanco en claro).
/// Los nombres indican la dirección del gradiente.
class AppGradients {
  AppGradients._();

  // Colores base
  static const _blue = Color(0xFF0D1B5E); // blue.shade900 ≈ #0D1B5E
  static const _blueMid = Color(0xFF1565C0); // blue.shade800

  // ── Tema Oscuro (azul → negro) ─────────────────────────────────────────────

  /// Centro → afuera (inicio azul, fin negro)
  static const LinearGradient darkCenterOut = LinearGradient(
    begin: Alignment.center,
    end: Alignment.bottomRight,
    colors: [_blue, Colors.black],
  );

  /// Afuera → centro (inicio negro, fin azul)
  static const LinearGradient darkOutCenter = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.center,
    colors: [Colors.black, _blue],
  );

  /// Arriba → abajo
  static const LinearGradient darkTopBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_blue, Colors.black],
  );

  /// Abajo → arriba
  static const LinearGradient darkBottomTop = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Colors.black, _blue],
  );

  /// Izquierda → derecha
  static const LinearGradient darkLeftRight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [_blue, Colors.black],
  );

  /// Derecha → izquierda
  static const LinearGradient darkRightLeft = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Colors.black, _blue],
  );

  /// Diagonal: esquina superior-izquierda → inferior-derecha
  static const LinearGradient darkTopLeftBottomRight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_blue, Colors.black],
  );

  /// Diagonal: esquina inferior-derecha → superior-izquierda
  static const LinearGradient darkBottomRightTopLeft = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [Colors.black, _blue],
  );

  // ── Tema Claro (azul → blanco) ─────────────────────────────────────────────

  /// Centro → afuera
  static const LinearGradient lightCenterOut = LinearGradient(
    begin: Alignment.center,
    end: Alignment.bottomRight,
    colors: [_blueMid, Colors.white],
  );

  /// Afuera → centro
  static const LinearGradient lightOutCenter = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.center,
    colors: [Colors.white, _blueMid],
  );

  /// Arriba → abajo
  static const LinearGradient lightTopBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_blueMid, Colors.white],
  );

  /// Abajo → arriba
  static const LinearGradient lightBottomTop = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Colors.white, _blueMid],
  );

  /// Izquierda → derecha
  static const LinearGradient lightLeftRight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [_blueMid, Colors.white],
  );

  /// Derecha → izquierda
  static const LinearGradient lightRightLeft = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Colors.white, _blueMid],
  );

  /// Diagonal: superior-izquierda → inferior-derecha
  static const LinearGradient lightTopLeftBottomRight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_blueMid, Colors.white],
  );

  /// Diagonal: inferior-derecha → superior-izquierda
  static const LinearGradient lightBottomRightTopLeft = LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [Colors.white, _blueMid],
  );

  // ── Selector dinámico ──────────────────────────────────────────────────────

  /// Devuelve el gradiente correcto según el modo y la dirección deseada.
  static LinearGradient of(AppThemeMode mode, GradientDirection dir) {
    if (mode == AppThemeMode.dark) {
      switch (dir) {
        case GradientDirection.centerOut:
          return darkCenterOut;
        case GradientDirection.outCenter:
          return darkOutCenter;
        case GradientDirection.topBottom:
          return darkTopBottom;
        case GradientDirection.bottomTop:
          return darkBottomTop;
        case GradientDirection.leftRight:
          return darkLeftRight;
        case GradientDirection.rightLeft:
          return darkRightLeft;
        case GradientDirection.topLeftBottomRight:
          return darkTopLeftBottomRight;
        case GradientDirection.bottomRightTopLeft:
          return darkBottomRightTopLeft;
      }
    } else {
      switch (dir) {
        case GradientDirection.centerOut:
          return lightCenterOut;
        case GradientDirection.outCenter:
          return lightOutCenter;
        case GradientDirection.topBottom:
          return lightTopBottom;
        case GradientDirection.bottomTop:
          return lightBottomTop;
        case GradientDirection.leftRight:
          return lightLeftRight;
        case GradientDirection.rightLeft:
          return lightRightLeft;
        case GradientDirection.topLeftBottomRight:
          return lightTopLeftBottomRight;
        case GradientDirection.bottomRightTopLeft:
          return lightBottomRightTopLeft;
      }
    }
  }
}

/// Enum de direcciones de gradiente disponibles
enum GradientDirection {
  centerOut,
  outCenter,
  topBottom,
  bottomTop,
  leftRight,
  rightLeft,
  topLeftBottomRight,
  bottomRightTopLeft,
}

// ─── Colores semánticos por tema ──────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Azul primario (igual en ambos temas)
  static const Color primaryBlue = Color(0xFF0D1B5E);
  static const Color primaryBlueMid = Color(0xFF1565C0);
  static const Color primaryBlueLight = Color(0xFF1E88E5);
  static const Color accentBlue = Colors.blue;

  /// Fondo principal según tema
  static Color background(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.black : const Color(0xFFCBD5E1);

  /// Color de texto principal
  static Color textPrimary(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.white : Colors.black87;

  /// Color de texto secundario / subtítulos
  static Color textSecondary(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.white70 : Colors.black54;

  /// Color de iconos
  static Color icon(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.white : Colors.black87;

  /// Color de superficies (cards, contenedores)
  static Color surface(AppThemeMode mode) => mode == AppThemeMode.dark
      ? Colors.white.withOpacity(0.05)
      : Colors.white.withOpacity(
          0.4,
        ); // Más opaco para temas claros sobre el fondo gris

  /// Color de borde (cards, etc.)
  static Color border(AppThemeMode mode) => mode == AppThemeMode.dark
      ? const Color(0xFF0D1B5E) // blue.shade900
      : const Color(0xFF1565C0); // blue.shade800

  /// Opacidad del contenedor de icon dentro de SettingItem
  static Color iconContainer(AppThemeMode mode) => mode == AppThemeMode.dark
      ? Colors.black.withOpacity(0.3)
      : Colors.blue.withOpacity(0.08);

  /// Color del ScaffoldBackground
  static Color scaffoldBg(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.black : const Color(0xFFCBD5E1);

  /// Bordes intensos genéricos (como en app bars, nav bars y el mini player)
  static Color themeBorder(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.blue.shade900 : Colors.blue.shade500;

  /// Glow especial de las canciones de Ado
  static Color adoGlow(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.blue.shade900 : Colors.blue.shade500;

  /// Color de barra / ecualizador visualizer
  static Color visualizerColor(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.blue.shade900 : Colors.blue.shade500;

  /// Degradado translucido del Header Home
  static List<Color> homeHeaderGlow(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [Colors.blue.shade900.withOpacity(0.6), Colors.black.withOpacity(0.5)]
      : [Colors.blue.shade500.withOpacity(0.7), Colors.white.withOpacity(0.7)];

  /// Degradado inverso translucido del Header Home
  static List<Color> homeHeaderGlowReverse(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [Colors.black.withOpacity(0.4), Colors.blue.shade900.withOpacity(0.6)]
      : [Colors.white.withOpacity(0.7), Colors.blue.shade500.withOpacity(0.7)];

  /// Degradado translucido de la tarjeta de canción
  static List<Color> songItemGradient(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [Colors.blue.shade900.withOpacity(0.6), Colors.black]
      : [Colors.blue.shade500.withOpacity(0.6), Colors.white.withOpacity(0.8)];

  /// Color de placeholder de las portadas sin imagen
  static Color imagePlaceholder(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.grey.shade800 : Colors.white70;

  /// Favorito FAB gradiente
  static List<Color> fabGradient(AppThemeMode mode) => mode == AppThemeMode.dark
      ? [
          Colors.black.withOpacity(0.5),
          const Color(0xFF0D47A1).withOpacity(0.8),
        ]
      : [Colors.white.withOpacity(0.5), Colors.blue.shade500.withOpacity(0.8)];

  /// Acento del FAB (bordes, iconos y sombras)
  static Color fabAccent(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.blueAccent : Colors.blue.shade700;

  /// Degradado de la barra lateral / top bar del TV
  static List<Color> sidebarGradient(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [Colors.black.withOpacity(0.9), Colors.blue.shade900.withOpacity(0.5)]
      : [Colors.white.withOpacity(0.9), Colors.blue.shade500.withOpacity(0.5)];
}

// ─── ThemeService (ChangeNotifier + Singleton) ────────────────────────────────

/// Servicio global de tema. Se registra como Provider en main.dart.
/// Usa `ChangeNotifier` para que todos los widgets que escuchen
/// se reconstruyan automáticamente.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _prefKey = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.dark;
  bool _initialized = false;

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;

  /// Carga la preferencia guardada. Llámalo en `main()` antes de `runApp`.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _mode = saved == 'light' ? AppThemeMode.light : AppThemeMode.dark;
    _initialized = true;
    notifyListeners();
  }

  /// Alterna entre oscuro y claro, persiste la elección.
  Future<void> toggle() async {
    _mode = _mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      _mode == AppThemeMode.light ? 'light' : 'dark',
    );
  }

  /// Establece el modo directamente.
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      mode == AppThemeMode.light ? 'light' : 'dark',
    );
  }

  /// `ThemeData` de Flutter según el modo (para MaterialApp).
  ThemeData get themeData {
    if (_mode == AppThemeMode.dark) {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryBlueMid,
          surface: Colors.black,
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFCBD5E1),
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryBlueMid,
          surface: const Color(0xFFCBD5E1),
        ),
      );
    }
  }
}

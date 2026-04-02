// Copyright © 2026 Brayan Medrano - MG Music
// Sistema central de tematización de la aplicación, definiendo paletas de colores, gradientes semánticos y lógica de cambio de tema (Claro/Oscuro/Sistema/Horario).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { dark, light }
enum AppThemeType { dark, light, system, timeBased }

class AppGradients {
  AppGradients._();

  static Color get _blue => AppColors.primaryBlue;
  static Color get _blueMid => AppColors.primaryBlueMid;

  static LinearGradient get darkCenterOut => LinearGradient(
    begin: Alignment.center,
    end: Alignment.bottomRight,
    colors: [_blue, Colors.black],
  );

  static LinearGradient get darkOutCenter => LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.center,
    colors: [Colors.black, _blue],
  );

  static LinearGradient get darkTopBottom => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_blue, Colors.black],
  );

  static LinearGradient get darkBottomTop => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Colors.black, _blue],
  );

  static LinearGradient get darkLeftRight => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [_blue, Colors.black],
  );

  static LinearGradient get darkRightLeft => LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Colors.black, _blue],
  );

  static LinearGradient get darkTopLeftBottomRight => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_blue, Colors.black],
  );

  static LinearGradient get darkBottomRightTopLeft => LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [Colors.black, _blue],
  );

  static LinearGradient get lightCenterOut => LinearGradient(
    begin: Alignment.center,
    end: Alignment.bottomRight,
    colors: [_blueMid, Colors.white],
  );

  static LinearGradient get lightOutCenter => LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.center,
    colors: [Colors.white, _blueMid],
  );

  static LinearGradient get lightTopBottom => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_blueMid, Colors.white],
  );

  static LinearGradient get lightBottomTop => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Colors.white, _blueMid],
  );

  static LinearGradient get lightLeftRight => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [_blueMid, Colors.white],
  );

  static LinearGradient get lightRightLeft => LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Colors.white, _blueMid],
  );

  static LinearGradient get lightTopLeftBottomRight => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_blueMid, Colors.white],
  );

  static LinearGradient get lightBottomRightTopLeft => LinearGradient(
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
    colors: [Colors.white, _blueMid],
  );

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

class AppColors {
  AppColors._();

  static Color? _dynamicAdoColor;
  static Color? _dynamicAdoSecondaryColor;

  static void setDynamicAdoColor(Color? color, [Color? secondary]) {
    _dynamicAdoColor = color;
    _dynamicAdoSecondaryColor = secondary;
  }

  static Color _darken(Color c, [int percent = 30]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(
      c.alpha,
      (c.red * f).round(),
      (c.green * f).round(),
      (c.blue * f).round(),
    );
  }

  static Color _lighten(Color c, [int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var p = percent / 100;
    return Color.fromARGB(
      c.alpha,
      c.red + ((255 - c.red) * p).round(),
      c.green + ((255 - c.green) * p).round(),
      c.blue + ((255 - c.blue) * p).round(),
    );
  }

  static Color get primaryBlue => _dynamicAdoColor != null ? _darken(_dynamicAdoColor!) : const Color(0xFF0D1B5E);
  static Color get primaryBlueMid => _dynamicAdoColor ?? const Color(0xFF1565C0);
  static Color get primaryBlueLight => _dynamicAdoSecondaryColor ?? (_dynamicAdoColor != null ? _lighten(_dynamicAdoColor!) : const Color(0xFF1E88E5));
  static Color get accentBlue => _dynamicAdoColor ?? Colors.blue;

  static const Color primaryBlueFixed = Color(0xFF1565C0);

  static Color background(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.black : const Color(0xFFCBD5E1);

  static Color textPrimary(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.white : Colors.black87;

  static Color textSecondary(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.white70 : Colors.black54;

  static Color icon(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.white : Colors.black87;

  static Color surface(AppThemeMode mode) => mode == AppThemeMode.dark
      ? Colors.white.withOpacity(0.05)
      : Colors.white.withOpacity(0.4);

  static Color border(AppThemeMode mode) => mode == AppThemeMode.dark
      ? primaryBlue
      : primaryBlueMid;

  static Color iconContainer(AppThemeMode mode) => mode == AppThemeMode.dark
      ? Colors.black.withOpacity(0.3)
      : Colors.blue.withOpacity(0.08);

  static Color scaffoldBg(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.black : const Color(0xFFCBD5E1);

  static Color themeBorder(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? (_dynamicAdoColor != null ? _darken(_dynamicAdoColor!) : Colors.blue.shade900) : (_dynamicAdoColor ?? Colors.blue.shade500);

  static Color adoGlow(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? (_dynamicAdoColor != null ? _darken(_dynamicAdoColor!) : Colors.blue.shade900) : (_dynamicAdoColor ?? Colors.blue.shade500);

  static Color visualizerColor(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? (_dynamicAdoColor != null ? _darken(_dynamicAdoColor!) : Colors.blue.shade900) : (_dynamicAdoColor ?? Colors.blue.shade500);

  static List<Color> homeHeaderGlow(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [themeBorder(mode).withOpacity(0.6), Colors.black.withOpacity(0.5)]
      : [themeBorder(mode).withOpacity(0.7), Colors.white.withOpacity(0.7)];

  static List<Color> homeHeaderGlowReverse(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [Colors.black.withOpacity(0.4), themeBorder(mode).withOpacity(0.6)]
      : [Colors.white.withOpacity(0.7), themeBorder(mode).withOpacity(0.7)];

  static List<Color> songItemGradient(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [themeBorder(mode).withOpacity(0.6), Colors.black]
      : [themeBorder(mode).withOpacity(0.6), Colors.white.withOpacity(0.8)];

  static Color imagePlaceholder(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? Colors.grey.shade800 : Colors.white70;

  static List<Color> fabGradient(AppThemeMode mode) => mode == AppThemeMode.dark
      ? [
          Colors.black.withOpacity(0.5),
          primaryBlueMid.withOpacity(0.8),
        ]
      : [Colors.white.withOpacity(0.5), primaryBlueMid.withOpacity(0.8)];

  static Color fabAccent(AppThemeMode mode) =>
      mode == AppThemeMode.dark ? accentBlue : primaryBlueMid;

  static List<Color> sidebarGradient(AppThemeMode mode) =>
      mode == AppThemeMode.dark
      ? [Colors.black.withOpacity(0.9), primaryBlue.withOpacity(0.5)]
      : [Colors.white.withOpacity(0.9), primaryBlueMid.withOpacity(0.5)];
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _prefTypeKey = 'app_theme_type';
  static const String _prefStartH = 'app_theme_start_h';
  static const String _prefStartM = 'app_theme_start_m';
  static const String _prefEndH = 'app_theme_end_h';
  static const String _prefEndM = 'app_theme_end_m';

  AppThemeType _type = AppThemeType.dark;
  AppThemeMode _computedMode = AppThemeMode.dark;
  
  int _startHour = 18;
  int _startMin = 30;
  int _endHour = 7;
  int _endMin = 0;

  bool _initialized = false;
  Timer? _timer;

  AppThemeMode get mode => _computedMode;
  AppThemeType get themeType => _type;
  bool get isDark => _computedMode == AppThemeMode.dark;
  
  int get startHour => _startHour;
  int get startMin => _startMin;
  int get endHour => _endHour;
  int get endMin => _endMin;

  Future<void> init() async {
    if (_initialized) return;
    await reloadFromPrefs();
    _initialized = true;
    _startTimer();
  }

  void setAdoColor(Color? color, [Color? secondary]) {
    AppColors.setDynamicAdoColor(color, secondary);
    notifyListeners();
  }

  Future<void> reloadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (prefs.containsKey('app_theme_mode') && !prefs.containsKey(_prefTypeKey)) {
      final old = prefs.getString('app_theme_mode');
      _type = old == 'light' ? AppThemeType.light : AppThemeType.dark;
    } else {
      final t = prefs.getString(_prefTypeKey) ?? 'dark';
      _type = AppThemeType.values.firstWhere(
        (e) => e.name == t,
        orElse: () => AppThemeType.dark,
      );
    }
    
    _startHour = prefs.getInt(_prefStartH) ?? 18;
    _startMin = prefs.getInt(_prefStartM) ?? 30;
    _endHour = prefs.getInt(_prefEndH) ?? 7;
    _endMin = prefs.getInt(_prefEndM) ?? 0;
    
    _computeMode();
  }

  void _computeMode() {
    AppThemeMode newMode;
    switch (_type) {
      case AppThemeType.dark:
        newMode = AppThemeMode.dark;
        break;
      case AppThemeType.light:
        newMode = AppThemeMode.light;
        break;
      case AppThemeType.system:
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        newMode = brightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light;
        break;
      case AppThemeType.timeBased:
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final startMinutes = _startHour * 60 + _startMin;
        final endMinutes = _endHour * 60 + _endMin;

        bool isNight = false;
        if (startMinutes < endMinutes) {
           isNight = currentMinutes >= startMinutes && currentMinutes < endMinutes;
        } else {
           isNight = currentMinutes >= startMinutes || currentMinutes < endMinutes;
        }
        newMode = isNight ? AppThemeMode.dark : AppThemeMode.light;
        break;
    }

    if (_computedMode != newMode) {
      _computedMode = newMode;
      notifyListeners();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_type == AppThemeType.timeBased || _type == AppThemeType.system) {
        _computeMode();
      }
    });
  }

  Future<void> toggle() async {
    final newType = _computedMode == AppThemeMode.dark ? AppThemeType.light : AppThemeType.dark;
    await setThemeType(newType);
  }

  Future<void> setThemeType(AppThemeType type) async {
    if (_type == type) return;
    _type = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTypeKey, type.name);
    _computeMode();
    notifyListeners();
  }
  
  Future<void> setTimeBasedHours({
    required int startH, required int startM,
    required int endH, required int endM,
  }) async {
    _startHour = startH;
    _startMin = startM;
    _endHour = endH;
    _endMin = endM;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefStartH, startH);
    await prefs.setInt(_prefStartM, startM);
    await prefs.setInt(_prefEndH, endH);
    await prefs.setInt(_prefEndM, endM);
    _computeMode();
    notifyListeners();
  }

  ThemeData get themeData {
    if (_computedMode == AppThemeMode.dark) {
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

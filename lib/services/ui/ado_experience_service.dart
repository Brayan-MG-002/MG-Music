// Copyright © 2026 Brayan Medrano - MG Music
// Servicio especializado en la gestión de la experiencia visual para canciones de Ado, incluyendo extracción de colores dinámicos y animaciones de fondo.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'dart:async';
import 'package:palette_generator/palette_generator.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdoExperienceService {
  static final AdoExperienceService _instance = AdoExperienceService._internal();
  factory AdoExperienceService() => _instance;
  AdoExperienceService._internal();

  bool _dynamicColorEnabled = false;
  bool _dedicatedPlayerEnabled = false;
  int _dynamicColorMode = 0; // 0: Fijo, 1: Latido, 2: Múltiple

  final dynamicColorEnabledNotifier = ValueNotifier<bool>(false);
  final dynamicColorModeNotifier = ValueNotifier<int>(0);

  Timer? _animationTimer;
  List<Color> _extractedColors = [];
  int _multiColorIndex = 0;
  double _animT = 0.0;
  int _animDir = 1;
  Color? _lastColor;
  Color? _nextColor;
  Color? _lastReportedColor;

  bool get dynamicColorEnabled => _dynamicColorEnabled;
  bool get dedicatedPlayerEnabled => _dedicatedPlayerEnabled;
  int get dynamicColorMode => _dynamicColorMode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dynamicColorEnabled = prefs.getBool('ado_dynamic_color') ?? false;
    _dedicatedPlayerEnabled = prefs.getBool('ado_dedicated_player') ?? false;
    _dynamicColorMode = prefs.getInt('ado_dynamic_color_mode') ?? 0;

    dynamicColorEnabledNotifier.value = _dynamicColorEnabled;
    dynamicColorModeNotifier.value = _dynamicColorMode;

    AudioPlayerManager().currentSongNotifier.addListener(_onSongChanged);
  }

  Future<void> setDynamicColorEnabled(bool val) async {
    _dynamicColorEnabled = val;
    dynamicColorEnabledNotifier.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ado_dynamic_color', val);
    _onSongChanged();
  }

  Future<void> setDedicatedPlayerEnabled(bool val) async {
    _dedicatedPlayerEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ado_dedicated_player', val);
  }

  Future<void> setDynamicColorMode(int val) async {
    _dynamicColorMode = val;
    dynamicColorModeNotifier.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ado_dynamic_color_mode', val);
    _startAnimationLoop();
  }

  void _stopAnimationAndReset() {
    _animationTimer?.cancel();
    if (_lastReportedColor == null) {
      ThemeService().setAdoColor(null);
      return;
    }
    
    double crossfadeT = 0.0;
    Color crossfadeStartColor = _lastReportedColor!;
    
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      crossfadeT += 0.1;
      if (crossfadeT >= 1.0) {
         _lastReportedColor = null;
         ThemeService().setAdoColor(null);
         timer.cancel();
         return;
      }
      final defaultThemeColor = ThemeService().mode == AppThemeMode.dark ? Colors.blue.shade900 : Colors.blue.shade500;
      final c = Color.lerp(crossfadeStartColor, defaultThemeColor, Curves.easeInOut.transform(crossfadeT));
      ThemeService().setAdoColor(c);
    });
  }

  Color _adjustColorForTheme(Color color) {
    final mode = ThemeService().mode;
    final hsl = HSLColor.fromColor(color);
    
    if (mode == AppThemeMode.dark) {
      // Necesita brillar sobre fondos oscuros
      if (hsl.lightness < 0.3) {
        return hsl.withLightness(0.5).toColor();
      } else if (hsl.lightness < 0.45) {
        return hsl.withLightness(0.55).toColor();
      }
    } else {
      // Necesita oscurecerse sobre fondos claros
      if (hsl.lightness > 0.8) {
        return hsl.withLightness(0.45).toColor();
      } else if (hsl.lightness > 0.6) {
        return hsl.withLightness(0.5).toColor();
      }
    }
    return color;
  }

  Future<void> _onSongChanged() async {
    if (!_dynamicColorEnabled) {
      _stopAnimationAndReset();
      return;
    }

    final LocalSong? song = AudioPlayerManager().currentSongNotifier.value;
    if (song == null || !AdoHandler.isAdo(song)) {
      _stopAnimationAndReset();
      return;
    }

    try {
      final OnAudioQuery audioQuery = OnAudioQuery();
      final Uint8List? artwork = await audioQuery.queryArtwork(
        song.id,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      );

      if (artwork != null && artwork.isNotEmpty) {
        final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
          MemoryImage(artwork),
        );
        
        final List<PaletteColor> validColors = palette.paletteColors.toList();
        if (validColors.isNotEmpty) {
           // Ordenar estrictamente por la cantidad de píxeles que ocupan (Dominancia real)
           validColors.sort((a, b) => b.population.compareTo(a.population));
           
           _extractedColors.clear();
           for (var pc in validColors) {
             _extractedColors.add(_adjustColorForTheme(pc.color));
           }
           
           // Remover duplicados manteniendo el orden
           _extractedColors = _extractedColors.toSet().toList();

           if (_extractedColors.isNotEmpty) {
             _startAnimationLoop();
           } else {
             _stopAnimationAndReset();
           }
        } else {
          _stopAnimationAndReset();
        }
      } else {
        _stopAnimationAndReset();
      }
    } catch (e) {
      _stopAnimationAndReset();
    }
  }

  void _startAnimationLoop() {
    _animationTimer?.cancel();
    if (_extractedColors.isEmpty) {
      _stopAnimationAndReset();
      return;
    }

    if (_dynamicColorMode == 2) {
      _extractedColors = _extractedColors.take(3).toList();
    }

    bool inCrossfade = _lastReportedColor != null;
    double crossfadeT = 0.0;
    Color crossfadeStartColor = _lastReportedColor ?? Colors.transparent;
    Color crossfadeStartSecondary = _lastReportedSecondaryColor ?? Colors.transparent;

    _animT = 0.0;
    _animDir = 1;
    _multiColorIndex = 0;
    if (_extractedColors.length > 1) {
       _lastColor = _extractedColors[0];
       _nextColor = _extractedColors[1];
    }

    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (inCrossfade) {
            crossfadeT += 0.1;
            if (crossfadeT >= 1.0) {
                crossfadeT = 1.0;
                inCrossfade = false;
            }
        }

        Color targetColor;
        Color targetSecondary;

        final defaultThemeColor = ThemeService().mode == AppThemeMode.dark ? Colors.blue.shade900 : Colors.blue.shade500;

        if (_dynamicColorMode == 0 || (_extractedColors.length == 1 && _dynamicColorMode == 2)) {
            // Fijo
            targetColor = _extractedColors.first;
            targetSecondary = _extractedColors.length > 1 ? _extractedColors[1] : _lighten(targetColor);
            if (!inCrossfade) timer.cancel();
        } else if (_dynamicColorMode == 1) {
            // Latido
            _animT += 0.02 * _animDir;
            if (_animT >= 1.0) {
              _animT = 1.0;
              _animDir = -1;
            } else if (_animT <= 0.0) {
              _animT = 0.0;
              _animDir = 1;
            }
            final curveT = Curves.easeInOut.transform(_animT);
            targetColor = Color.lerp(_extractedColors.first, defaultThemeColor, curveT) ?? _extractedColors.first;
            
            final secondaryBase = _extractedColors.length > 1 ? _extractedColors[1] : _lighten(_extractedColors.first);
            targetSecondary = Color.lerp(secondaryBase, defaultThemeColor.withOpacity(0.5), curveT) ?? secondaryBase;
        } else {
            // Múltiple
            _animT += 0.005;
            if (_animT >= 1.0) {
              _animT = 0.0;
              _multiColorIndex = (_multiColorIndex + 1) % _extractedColors.length;
              _lastColor = _extractedColors[_multiColorIndex];
              _nextColor = _extractedColors[(_multiColorIndex + 1) % _extractedColors.length];
            }
            final curveT = Curves.easeInOut.transform(_animT);
            targetColor = Color.lerp(_lastColor, _nextColor, curveT) ?? _lastColor!;
            
            // Secundario es el color siguiente en la lista para un degradado dinámico
            final nextIdx = (_multiColorIndex + 1) % _extractedColors.length;
            final nextNextIdx = (_multiColorIndex + 2) % _extractedColors.length;
            targetSecondary = Color.lerp(_extractedColors[nextIdx], _extractedColors[nextNextIdx], curveT) ?? _extractedColors[nextIdx];
        }

        if (inCrossfade) {
            final c = Color.lerp(crossfadeStartColor, targetColor, Curves.easeInOut.transform(crossfadeT));
            final s = Color.lerp(crossfadeStartSecondary, targetSecondary, Curves.easeInOut.transform(crossfadeT));
            _lastReportedColor = c;
            _lastReportedSecondaryColor = s;
            ThemeService().setAdoColor(c, s);
        } else {
            _lastReportedColor = targetColor;
            _lastReportedSecondaryColor = targetSecondary;
            ThemeService().setAdoColor(targetColor, targetSecondary);
        }
    });
  }

  Color _lighten(Color c, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color? _lastReportedSecondaryColor;
}

// Copyright © 2026 Brayan Medrano - MG Music
// Punto de entrada de la aplicación y gestión del disclaimer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/ui/shared/splash.dart';
import 'package:mg_music/services/errors/error_service.dart';

import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mg_music/services/audio/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización con timeouts para evitar cuelgues
  try {
    await ThemeService().init().timeout(const Duration(seconds: 3));
    await ErrorService().init().timeout(const Duration(seconds: 3));
 
    final audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(AudioPlayerManager().player),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.mgstudios.mgmusic.audio',
        androidNotificationChannelName: 'MG Music',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'drawable/ic_stat_music',
        notificationColor: Colors.black,
      ),
    ).timeout(const Duration(seconds: 5));
 
    AudioPlayerManager().setAudioHandler(audioHandler);
  } catch (e) {
    debugPrint('⚠️ Error o timeout durante inicialización: $e');
  }

  runApp(
    ChangeNotifierProvider<ThemeService>.value(
      value: ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  /// Construye la app principal y aplica el tema
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      navigatorKey: GlobalModalService.navigatorKey,
      title: 'MG Music',
      theme: themeService.themeData,
      home: const AppEntryGate(child: SplashScreen()),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  final Widget child;
  const AppEntryGate({super.key, required this.child});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _ready = false;

  @override
  /// Inicializa el estado y prepara la aplicación
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Inicializa la app y verifica el disclaimer
  Future<void> _initializeApp() async {
    // Timeout de seguridad global para el gate
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_ready) {
        debugPrint('⏱️ AppEntryGate safety timeout disparado');
        setState(() => _ready = true);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      final disclaimerShown = prefs.getBool('fan_disclaimer_shown') ?? false;

      if (!disclaimerShown) {
        if (mounted) {
          await prefs.remove('ado_playlist_welcome_shown_v1');
          await _showFanDisclaimer();
          await prefs.setBool('fan_disclaimer_shown', true);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error en AppEntryGate: $e');
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  /// Muestra el modal de aviso de fan con cuenta regresiva
  Future<void> _showFanDisclaimer() async {
    int countdown = 10;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final mode = Provider.of<ThemeService>(dialogCtx).mode;
        return StatefulBuilder(
          builder: (context, setState) {
            if (countdown > 0) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && countdown > 0) {
                  setState(() => countdown--);
                }
              });
            }

            return WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                backgroundColor: AppColors.background(mode),
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.themeBorder(mode),
                    width: 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final bool isSmall = width < 360;
                    
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Ionicons.warning_outline,
                              color: AppColors.primaryBlueMid,
                              size: isSmall ? 30 : 40,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'AVISO IMPORTANTE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary(mode),
                                fontSize: isSmall ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'MG Music es una aplicación creada por un fan.\n\n'
                              'NO es una aplicación oficial ni está afiliada '
                              'a la artista Ado ni a su equipo.\n\n'
                              'La app no almacena ni distribuye música.\n'
                              'Solo reproduce archivos locales del usuario.\n\n'
                              'Algunas funciones reaccionan de forma especial '
                              'cuando se detectan canciones de Ado.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary(mode),
                                fontSize: isSmall ? 13 : 15,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: countdown > 0
                                  ? Text(
                                      'Por favor lee. Botón activo en $countdown s',
                                      key: const ValueKey('timer'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.primaryBlueMid,
                                        fontSize: 13,
                                      ),
                                    )
                                  : OutlinedButton(
                                      key: const ValueKey('button'),
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppColors.primaryBlueMid,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        backgroundColor: AppColors.primaryBlueMid
                                            .withOpacity(0.1),
                                      ),
                                      child: Text(
                                        'Continuar a la App',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(mode),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  /// Construye la UI de entrada o el contenido de la app
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    return widget.child;
  }
}

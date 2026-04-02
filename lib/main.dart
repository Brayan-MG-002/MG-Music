// Copyright © 2026 Brayan Medrano - MG Music
// Punto de entrada de la aplicación, configuración de servicios globales y gestión del disclaimer inicial.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mg_music/services/audio/audio_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mg_music/services/logic/notification_service.dart';
import 'package:mg_music/services/ui/ado_experience_service.dart';
import 'package:mg_music/ui/shared/splash.dart';
import 'package:mg_music/services/errors/error_service.dart';

/// Variable global para el modo beta
const bool isBeta = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager().registerPeriodicTask(
    'check_updates_task',
    'checkUpdates',
    frequency: const Duration(hours: 6),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  try {
    await ThemeService().init().timeout(const Duration(seconds: 3));
    await ErrorService().init().timeout(const Duration(seconds: 3));

    await AudioPlayerManager().init().timeout(const Duration(seconds: 3));

    await AudioService.init(
      builder: () => MyAudioHandler(AudioPlayerManager().player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mgstudios.mgmusic.audio',
        androidNotificationChannelName: 'MG Music',
        // androidStopForegroundOnPause: false ya mantiene el foreground
        // service vivo aunque la app esté en pausa o cerrada de recientes.
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'drawable/ic_stat_music',
        androidNotificationChannelDescription:
            'Reproducción de música MG Music',
        preloadArtwork: true,
      ),
    ).timeout(const Duration(seconds: 5));


    await AdoExperienceService().init();
  } catch (e) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>.value(value: ThemeService()),
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      navigatorKey: GlobalModalService.navigatorKey,
      title: 'MG Music',
      debugShowCheckedModeBanner: false,
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
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    Future.delayed(Duration(seconds: isBeta ? 40 : 20), () {
      if (mounted && !_ready) {
        setState(() => _ready = true);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
      );

      if (!isBeta) {
        await prefs.remove('beta_warning_shown_v1');
      }

      final disclaimerShown = prefs.getBool('fan_disclaimer_shown') ?? false;
      if (!disclaimerShown) {
        if (mounted) {
          await prefs.remove('ado_playlist_welcome_shown_v1');
          await _showFanDisclaimer();
          await prefs.setBool('fan_disclaimer_shown', true);
        }
      }

      if (isBeta) {
        final betaWarningShown =
            prefs.getBool('beta_warning_shown_v1') ?? false;
        if (!betaWarningShown) {
          if (mounted) {
            await _showBetaWarning();
            await prefs.setBool('beta_warning_shown_v1', true);
          }
        }
      }
    } catch (e) {}

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  Future<void> _showFanDisclaimer() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const _FanDisclaimerDialog(),
    );
  }

  Future<void> _showBetaWarning() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const _BetaWarningDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    return widget.child;
  }
}

/// Widget interno para el diálogo de descargo de responsabilidad con temporizador gestionado
class _FanDisclaimerDialog extends StatefulWidget {
  const _FanDisclaimerDialog();

  @override
  State<_FanDisclaimerDialog> createState() => _FanDisclaimerDialogState();
}

class _FanDisclaimerDialogState extends State<_FanDisclaimerDialog> {
  int _countdown = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _timer?.cancel();
            Navigator.of(context).pop();
          }
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = Provider.of<ThemeService>(context).mode;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: AppColors.background(mode),
        insetPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: AppColors.themeBorder(mode), width: 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Ionicons.warning_outline,
                      color: AppColors.primaryBlueMid,
                      size: 40.0,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'AVISO IMPORTANTE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary(mode),
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16.0),
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
                        fontSize: 15.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _countdown > 5
                          ? Text(
                              'Por favor lee. Botón activo en ${_countdown - 5} s',
                              key: const ValueKey('timer'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryBlueMid,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  key: const ValueKey('button'),
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.primaryBlueMid,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0,
                                      vertical: 14.0,
                                    ),
                                    backgroundColor: AppColors.primaryBlueMid
                                        .withOpacity(0.1),
                                  ),
                                  child: Text(
                                    'Continuar a la App',
                                    style: TextStyle(
                                      color: AppColors.textPrimary(mode),
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Auto-continuar en $_countdown s',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(
                                      mode,
                                    ).withOpacity(0.6),
                                    fontSize: 11.0,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BetaWarningDialog extends StatelessWidget {
  const _BetaWarningDialog();

  @override
  Widget build(BuildContext context) {
    final mode = Provider.of<ThemeService>(context).mode;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: AppColors.background(mode),
        insetPadding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(color: AppColors.themeBorder(mode), width: 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Ionicons.flask_outline,
                      color: AppColors.primaryBlueMid,
                      size: 40.0,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'MODO BETA ACTIVO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary(mode),
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Estás utilizando una versión de prueba de MG Music.\n\n'
                      'Esta versión puede contener errores visuales o de funcionamiento. '
                      'Tu ayuda es fundamental para mejorar la aplicación.\n\n'
                      'Si encuentras algún problema, por favor repórtalo en la sección '
                      'de "Ajustes" mediante el botón de Soporte WhatsApp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary(mode),
                        fontSize: 15.0,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primaryBlueMid,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 14.0,
                            ),
                            backgroundColor: AppColors.primaryBlueMid
                                .withOpacity(0.1),
                          ),
                          child: Text(
                            'Continuar a la App',
                            style: TextStyle(
                              color: AppColors.textPrimary(mode),
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Botón habilitado',
                          style: TextStyle(
                            color: AppColors.textSecondary(
                              mode,
                            ).withOpacity(0.6),
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Copyright © 2026 Brayan Medrano - MG Music
// Punto de entrada de la aplicación y gestión del disclaimer

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/splash.dart';

/// Inicializa la aplicación y configura el audio background
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mgstudios.mgmusic.audio',
    androidNotificationChannelName: 'MG Music',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_stat_music',
  );

  runApp(const MyApp());
}

/// Aplicación principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MG Music',
      debugShowCheckedModeBanner: false,
      home: const AppEntryGate(child: SplashScreen()),
    );
  }
}

/// Puerta de entrada que muestra el disclaimer de fan antes de cargar la app
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

  /// Inicializa la app verificando disclaimer y actualizaciones
  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final disclaimerShown = prefs.getBool('fan_disclaimer_shown') ?? false;

    if (!disclaimerShown) {
      if (mounted) {
        await _showFanDisclaimer();
        await prefs.setBool('fan_disclaimer_shown', true);
      }
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  /// Muestra el modal de aviso de fan durante 10 segundos
  Future<void> _showFanDisclaimer() async {
    int countdown = 10;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (countdown > 0 && mounted) {
                setState(() => countdown--);
              } else if (mounted) {
                Navigator.of(context).pop();
              }
            });

            return WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                backgroundColor: Colors.black,
                insetPadding: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'AVISO IMPORTANTE',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'MG Music es una aplicación creada por un fan.\n\n'
                          'NO es una aplicación oficial ni está afiliada '
                          'a la artista Ado ni a su equipo.\n\n'
                          'La app no almacena ni distribuye música.\n'
                          'Solo reproduce archivos locales del usuario.\n\n'
                          'Algunas funciones reaccionan de forma especial '
                          'cuando se detectan canciones de Ado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          countdown > 0
                              ? 'Continuando en $countdown s'
                              : 'Continuando...',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

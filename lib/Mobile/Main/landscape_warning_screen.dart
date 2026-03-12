import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class LandscapeWarningScreen extends StatelessWidget {
  const LandscapeWarningScreen({super.key});

  @override
  /// Construye una pantalla de aviso para orientación horizontal
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.phone_portrait_outline,
                size: 80,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 30),
              const Text(
                'Rotación No Soportada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'La interfaz actual no está adaptada para pantallas horizontales. Esta característica se agregará en una futura actualización.\n\nPor favor, gira tu dispositivo a modo vertical para continuar usando la aplicación de manera óptima.',
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

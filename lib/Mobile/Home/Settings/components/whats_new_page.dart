import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  /// Construye la página de novedades de la versión
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      appBar: AppBar(
        backgroundColor: AppColors.background(mode),
        title: Text(
          'Novedades de la Versión',
          style: TextStyle(color: AppColors.textPrimary(mode)),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary(mode)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(
            child: Icon(
              Ionicons.sparkles,
              color: AppColors.primaryBlueMid,
              size: 64,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              'Versión 1.1.0',
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              '"Actualización Visual"',
              style: TextStyle(
                color: AppColors.primaryBlueMid,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildFeatureSection(
            mode: mode,
            title: 'Interfaz Visual y Animaciones',
            icon: Ionicons.color_palette_outline,
            items: [
              'Rediseño completo de la UI.',
              'Se agregaron nuevas animaciones en toda la aplicación.',
              'Agregado de un nuevo Tema Claro.',
              'Rediseño de la interfaz de favoritos y playlists.',
              'Se añadió un gestor de ventanas emergentes y alertas más bonitas.',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Reproducción y Audio',
            icon: Ionicons.musical_notes_outline,
            items: [
              'Se mejoró el sistema interno de audio.',
              'Siguiente canción y repeat junto con el aleatorio integrados.',
              'Botón nuevo en pistas para scrollear automáticamente a la canción que esté sonando.',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Favoritos',
            icon: Ionicons.heart_outline,
            items: [
              'Posibilidad de marcar una canción como principal en favoritos, protegiéndola de ser desmarcada por accidente.',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Experiencia Temática',
            icon: Ionicons.rose_outline,
            items: [
              'Nueva animación en el corazón al agregar a favoritos una pista de Ado.',
              'Sistema de detección de pistas de Ado mejorado para habilitar o deshabilitar sus funciones exclusivas.',
              'Amplificador sencillo que aumenta ligeramente el volumen para las pistas de Ado (desactivable y ajustable en los ajustes).',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Sistema y Ajustes',
            icon: Ionicons.settings_outline,
            items: [
              'Experiencia temática de la app enfocada en Ado transferida a la sección de configuración.',
              'Se agregó un sistema básico de reporte de errores.',
              'Botón en ajustes para visualizar el código en GitHub (solo lectura, no para distribución).',
              'Se reorganizó el código interno para que sea más limpio y fácil de entender (disponible para ver en GitHub).',
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '¡Gracias por usar MG Music!',
              style: TextStyle(
                color: AppColors.textSecondary(mode),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Construye una sección de características con bullets
  Widget _buildFeatureSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required AppThemeMode mode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlueMid.withOpacity(0.15),
            AppColors.background(mode).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.themeBorder(mode).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueMid.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryBlueMid, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(mode),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, right: 10.0),
                    child: Icon(
                      Ionicons.ellipse,
                      size: 6,
                      color: AppColors.textSecondary(mode).withOpacity(0.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppColors.textSecondary(mode),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

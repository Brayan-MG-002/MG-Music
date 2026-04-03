import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Container(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const SizedBox(height: 20),
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
              'MG Music v1.2.1 Hotfix',
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              'Hotfix',
              style: TextStyle(
                color: AppColors.primaryBlueMid,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sección: El Por Qué de esta Versión
          _buildFeatureSection(
            mode: mode,
            title: '¿Por qué "Nueva Etapa"?',
            icon: Ionicons.rocket_outline,
            items: [
              'Esta versión representa lo que MG Music debió ser desde el inicio. Tras múltiples mejoras y evolución interna, la app cuenta ahora con una base sólida y definida.',
              'A partir de aquí, el enfoque cambia: las futuras actualizaciones se centrarán en expandir la experiencia y agregar nuevas funciones, no en completar lo que faltaba.',
            ],
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildSectionDivider(mode, 'NOVEDADES DE LA VERSIÓN'),
          ),
          const SizedBox(height: 15),

          _buildFeatureSection(
            mode: mode,
            title: 'Correcciones (Hotfix 1.2.1)',
            icon: Ionicons.construct_outline,
            items: [
              'Corrección crítica: Se solucionó el error que congelaba la interfaz y la pantalla de inicio al tener los modos de color "Latido" o "Múltiple" activos.',
              'Optimización: El menú de selección de artistas ahora carga progresivamente y genera caché, eliminando el lag en bibliotecas gigantes.',
              'Nuevo filtro: Se agregó la opción de ordenar tus canciones por fecha de antigüedad ("Por Fecha (Antiguas)").',
            ],
          ),

          _buildFeatureSection(
            mode: mode,
            title: 'Interfaz y Navegación',
            icon: Ionicons.color_palette_outline,
            items: [
              'Mejoras en la responsividad: Adaptación inteligente a cualquier tamaño de pantalla.',
              'Nuevo sistema de temas: Modos claro, oscuro, sistema o cambio automático por horario.',
              'Búsqueda optimizada: Botón de buscar ahora en el botón flotante (lupa) de la lista de pistas.',
              'Acceso rápido: La lupa permite ir a la canción actual (1 toque) o buscar (2 toques).',
              'Selección múltiple: Toca dos veces rápido cualquier pista para activar el modo de selección múltiple.',
              'Acciones en lote: Elimina archivos del dispositivo, añade a favoritos o gestiona tus playlists de forma rápida con la selección múltiple.',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Reproducción de Audio',
            icon: Ionicons.musical_notes_outline,
            items: [
              'Edición de metadatos: Modifica título, artista y carátula individualmente desde el menú de cada canción.',
              'Gestión de archivos: Opción para eliminar pistas físicamente del almacenamiento desde el dispositivo.',
              'Escaneo inteligente: Selección de carpetas específicas o escaneo automático de todo el almacenamiento.',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Experiencia Temática',
            icon: Ionicons.sparkles_outline,
            items: [
              'Inspiración: MG Music nació para potenciar la experiencia de escuchar a Ado, nuestra mayor inspiración.',
              'Player especial: Diseño y efectos visuales exclusivos para sus canciones.',
              'Colores dinámicos: Toda la app reacciona a la paleta de colores de la carátula actual.',
              'Personalización temática: Control total para activar o desactivar la estética Ado.',
            ],
          ),
          _buildFeatureSection(
            mode: mode,
            title: 'Sistema y Respaldo',
            icon: Ionicons.settings_outline,
            items: [
              'Copias de seguridad: Exporta e importa tus listas y favoritos de forma segura.',
              'Actualizaciones internas: Notificación e instalación autónoma de nuevas versiones.',
              'Modo Beta activo: Sistema de reporte de errores optimizado para esta fase.',
            ],
          ),

          const SizedBox(height: 25),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tu apoyo es lo que hace posible que esta gran etapa comience. ¡Gracias por acompañar el desarrollo de MG Music! 💙',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(AppThemeMode mode, String label) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.primaryBlueMid.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryBlueMid.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.primaryBlueMid.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required AppThemeMode mode,
  }) {
    return RepaintBoundary(
      child: Container(
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
      ),
    );
  }
}

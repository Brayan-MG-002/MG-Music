import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/Mobile/Home/Settings/components/link_dialog.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  /// Construye la pantalla “Acerca de”
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      appBar: AppBar(
        backgroundColor: AppColors.background(mode),
        title: Text(
          'Acerca de',
          style: TextStyle(color: AppColors.textPrimary(mode)),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary(mode)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(child: Image.asset('assets/MG-I-T.png', width: 100)),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'MG Music',
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildSection(
            title: 'Inspiración',
            icon: Ionicons.heart,
            content:
                'Hola, soy Brayan Medrano. Este proyecto es un hobby personal que hice en mis ratos libres, inspirado en mi amor por Ado y su música.\n\nLa idea surgió como una forma de disfrutar su música con algunos detalles especiales que pensé sería cool tener. Decidí compartirlo contigo porque creí que podría gustarte también.',
            mode: mode,
          ),
          _buildSection(
            title: 'Aviso Legal',
            icon: Ionicons.warning_outline,
            content:
                'MG Music es un proyecto personal de un fan, hecho de forma independiente.\n\nNo tengo relación oficial con Ado ni con su equipo. Esta app respeta todos los derechos de autor y simplemente te ayuda a disfrutar la música local en tu dispositivo.\n\nTodos los nombres, imágenes y referencias relacionadas con Ado pertenecen a sus respectivos dueños. Solo los utilizo con admiración y respeto.',
            mode: mode,
          ),
          _buildSection(
            title: 'Sobre el Desarrollo',
            icon: Ionicons.code_slash_outline,
            content:
                'Yo solo (Brayan Medrano) desarrollo y mantengo esta app en mis tiempos libres. Es un proyecto que hago porque me apasiona.\n\nNo espero nada a cambio, solo espero que la disfrutes. Si encuentras bugs o tienes ideas, apreciaré tu feedback, pero entiende que actualizaciones pueden tardar por mi tiempo limitado.\n\nNo hay publicidad obligatoria ni cobros. Hice esta app para compartir algo que me gusta, nada más.',
            mode: mode,
            child: _buildGithubButton(context, mode),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'MG Music V1.1.0',
              style: TextStyle(color: AppColors.textSecondary(mode)),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una sección con título, icono y contenido
  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    required AppThemeMode mode,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlueMid.withOpacity(0.25),
            AppColors.background(mode).withOpacity(0.85),
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
              Icon(icon, color: AppColors.primaryBlueMid, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (child != null) ...[const SizedBox(height: 15), child],
        ],
      ),
    );
  }

  /// Botón que abre el repositorio en GitHub usando LinkDialog
  Widget _buildGithubButton(BuildContext context, AppThemeMode mode) {
    return InkWell(
      onTap: () {
        LinkDialog.show(
          context: context,
          title: 'Abrir GitHub',
          icon: Ionicons.logo_github,
          content:
              'Serás redirigido al repositorio de GitHub. Este código está subido por transparencia y no es de uso libre ni para distribución.',
          url: 'https://github.com/Brayan-MG-002/MG-Music',
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.background(mode).withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.themeBorder(mode).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.logo_github,
              color: AppColors.textPrimary(mode),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Código Fuente (GitHub)',
                    style: TextStyle(
                      color: AppColors.textPrimary(mode),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Para transparencia. No distribuir.',
                    style: TextStyle(
                      color: AppColors.textSecondary(mode),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Ionicons.open_outline,
              color: AppColors.primaryBlueMid,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

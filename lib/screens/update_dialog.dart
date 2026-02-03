// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo de actualización disponible

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mg_music/models/version_model.dart';

/// Diálogo que muestra información de actualización disponible
class UpdateDialog extends StatelessWidget {
  final VersionModel versionData;
  final bool isTv;

  const UpdateDialog({super.key, required this.versionData, this.isTv = false});

  /// Abre la URL en el navegador
  Future<void> _launchURL() async {
    try {
      final url = versionData.websiteUrl;
      if (kDebugMode) print('Intentando abrir URL: $url');

      final uri = Uri.parse(url);

      // Intentar con diferentes modos de lanzamiento
      try {
        // Primero intenta con inAppBrowserView (navegador incorporado)
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (kDebugMode) print('URL lanzada con inAppBrowserView');
      } catch (e) {
        if (kDebugMode) print('Error con inAppBrowserView: $e');
        try {
          // Si falla, intenta con externalApplication (navegador externo)
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (kDebugMode) print('URL lanzada con externalApplication');
        } catch (e2) {
          if (kDebugMode) print('Error con externalApplication: $e2');
          try {
            // Si todo falla, intenta con platformDefault
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            if (kDebugMode) print('URL lanzada con platformDefault');
          } catch (e3) {
            if (kDebugMode) print('Error con platformDefault: $e3');
            // Último intento: sin modo específico
            await launchUrl(uri);
            if (kDebugMode) print('URL lanzada sin modo específico');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error abriendo URL: $e');
    }
  }

  /// Obtiene el color según la importancia
  Color _getImportanceColor() {
    switch (versionData.importance) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  /// Obtiene el ícono según la importancia
  IconData _getImportanceIcon() {
    switch (versionData.importance) {
      case 'critical':
        return Icons.error_outline;
      case 'high':
        return Icons.warning_amber;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.update;
    }
  }

  /// Obtiene el nombre en texto según la importancia
  String _getImportanceName() {
    switch (versionData.importance) {
      case 'critical':
        return 'Alta';
      case 'high':
        return 'Media-Alta';
      case 'medium':
        return 'Media';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final importanceColor = _getImportanceColor();
    final importanceIcon = _getImportanceIcon();

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1E1E1E),
          ),
          constraints: BoxConstraints(maxWidth: isTv ? 800 : 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isTv ? 32.0 : 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        importanceIcon,
                        color: importanceColor,
                        size: isTv ? 32 : 24,
                      ),
                      SizedBox(width: isTv ? 16 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nueva versión',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: isTv ? 24 : null,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v${versionData.version} · ${_getImportanceName()}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: importanceColor,
                                    fontSize: isTv ? 16 : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTv ? 28 : 20),
                  Text(
                    versionData.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isTv ? 20 : null,
                    ),
                  ),
                  SizedBox(height: isTv ? 20 : 16),
                  if (versionData.changelog.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(isTv ? 16 : 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        versionData.changelog,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[300],
                          height: 1.5,
                          fontSize: isTv ? 16 : null,
                        ),
                      ),
                    ),
                  if (versionData.changelog.isNotEmpty)
                    SizedBox(height: isTv ? 28 : 20),
                  SizedBox(height: isTv ? 16 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTv ? 16 : 12,
                            ),
                          ),
                          child: Text(
                            'Ahora no',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: isTv ? 16 : null,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTv ? 16 : 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _launchURL();
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: importanceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTv ? 16 : 12,
                            ),
                          ),
                          child: Text(
                            'Actualizar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isTv ? 16 : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

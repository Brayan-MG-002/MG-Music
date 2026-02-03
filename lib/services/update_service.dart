// Copyright © 2026 Brayan Medrano - MG Music
// Servicio de verificación de actualizaciones

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mg_music/models/version_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio que gestiona verificación de actualizaciones de la app
class UpdateService {
  static const String _remoteVersionUrl =
      'https://mg-special.web.app/Body/MG-Music/version.json';

  /// Verifica si hay conexión a internet
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 5));
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return true;
    }
  }

  /// Obtiene información de versión del servidor remoto
  static Future<VersionModel?> getRemoteVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse(_remoteVersionUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return VersionModel.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la versión local de la aplicación
  static Future<String> getLocalVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  /// Compara dos versiones semánticas (major.minor.patch)
  /// Retorna: -1 si local < remote, 0 si iguales, 1 si local > remote
  static int compareVersions(String localVersion, String remoteVersion) {
    final localParts = localVersion.split('.').map(int.parse).toList();
    final remoteParts = remoteVersion.split('.').map(int.parse).toList();

    while (localParts.length < remoteParts.length) {
      localParts.add(0);
    }
    while (remoteParts.length < localParts.length) {
      remoteParts.add(0);
    }

    for (int i = 0; i < localParts.length; i++) {
      if (localParts[i] < remoteParts[i]) return -1;
      if (localParts[i] > remoteParts[i]) return 1;
    }
    return 0;
  }

  /// Verifica si hay actualización disponible
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        return {
          'hasUpdate': false,
          'error': 'Sin conexión a internet',
          'data': null,
        };
      }

      final remoteVersion = await getRemoteVersion();
      if (remoteVersion == null) {
        return {
          'hasUpdate': false,
          'error': 'No se pudo obtener información',
          'data': null,
        };
      }

      final localVersion = await getLocalVersion();
      final comparison = compareVersions(localVersion, remoteVersion.version);

      if (comparison < 0) {
        return {'hasUpdate': true, 'error': null, 'data': remoteVersion};
      }

      return {'hasUpdate': false, 'error': null, 'data': remoteVersion};
    } catch (e) {
      return {'hasUpdate': false, 'error': 'Error: $e', 'data': null};
    }
  }
}

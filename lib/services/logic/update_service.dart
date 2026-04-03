// Copyright © 2026 Brayan Medrano - MG Music
// Servicio de verificación de actualizaciones

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mg_music/services/models/version_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona verificación de actualizaciones de la app
class UpdateService {
  static const String _remoteVersionUrl =
      'https://mg-special.web.app/Body/MG-Music/version.json';

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

  static Future<VersionModel?> getRemoteVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse(_remoteVersionUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response('timeout', 408),
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return VersionModel.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getLocalVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.2.0';
    }
  }

  static Future<int> getLocalVersionCode() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return int.tryParse(packageInfo.buildNumber) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static int compareVersions(String localVersion, String remoteVersion) {
    int parsePart(String part) {
      final match = RegExp(r'^\d+').firstMatch(part);
      return match != null ? int.parse(match.group(0)!) : 0;
    }

    final localParts = localVersion.split('.').map(parsePart).toList();
    final remoteParts = remoteVersion.split('.').map(parsePart).toList();

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

  static Future<Map<String, dynamic>> checkForUpdate({
    bool isTv = false,
  }) async {
    try {
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        return {
          'hasUpdate': false,
          'isBeta': false,
          'error': 'Sin conexión a internet',
          'data': null,
        };
      }

      final remoteVersion = await getRemoteVersion();
      if (remoteVersion == null) {
        return {
          'hasUpdate': false,
          'isBeta': false,
          'error': 'No se pudo obtener información',
          'data': null,
        };
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final localVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      VersionModel? patchData;
      bool isBetaUpdate = false;

      final int stableRemote = remoteVersion.versionCode;
      final int betaRemote = remoteVersion.betaVersionCode ?? 0;

      if (!isTv && betaRemote > localVersionCode && betaRemote > stableRemote) {
        final prefs = await SharedPreferences.getInstance();
        final ignoredBeta = prefs.getInt('ignored_beta_version_code') ?? 0;

        if (betaRemote > ignoredBeta) {
          isBetaUpdate = true;
          patchData = VersionModel(
            version: remoteVersion.betaVersion ?? remoteVersion.version,
            versionCode: betaRemote,
            title: remoteVersion.betaTitle ?? 'Nueva Beta Disponible',
            changelog: remoteVersion.betaChangelog ?? '',
            websiteUrl:
                remoteVersion.betaWebsiteUrl ?? remoteVersion.websiteUrl,
            apkUrl: remoteVersion.betaApkUrl ?? remoteVersion.apkUrl,
            importance: remoteVersion.betaImportance ?? 'low',
            forceUpdate: false,
          );
        }
      }

      if (patchData == null && stableRemote > localVersionCode) {
        isBetaUpdate = false;
        patchData = remoteVersion;
      }

      if (patchData != null) {
        return {
          'hasUpdate': true,
          'isBeta': isBetaUpdate,
          'error': null,
          'data': patchData,
        };
      }

      return {
        'hasUpdate': false,
        'isBeta': false,
        'error': null,
        'data': remoteVersion,
      };
    } catch (e) {
      return {
        'hasUpdate': false,
        'isBeta': false,
        'error': 'Error: $e',
        'data': null,
      };
    }
  }
}

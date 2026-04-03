// Copyright © 2026 Brayan Medrano - MG Music
// Servicio para descarga de actualizaciones APK

import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class UpdateDownloadResult {
  final bool success;
  final String? message;
  final String? filePath;

  UpdateDownloadResult({required this.success, this.message, this.filePath});
}

class UpdateDownloadService {
  static http.Client? _activeClient;
  static String? _activeFilePath;

  static void cancelDownload() {
    try {
      _activeClient?.close();
      _activeClient = null;
    } catch (_) {}
  }

  static String apkPath(String version) =>
      '/storage/emulated/0/Download/MG Music/MG-Music-v$version.apk';

  static Future<bool> isDownloaded(String version) async {
    final file = File(apkPath(version));
    return await file.exists();
  }

  static Future<void> deleteApk(String version) async {
    final file = File(apkPath(version));
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {}
  }

  static Future<UpdateDownloadResult> downloadApk({
    required String url,
    required String version,
    required Function(double progress, double totalMB, double downloadedMB)
    onProgress,
  }) async {
    cancelDownload();
    _activeClient = http.Client();
    _activeFilePath = apkPath(version);

    try {
      final String downloadDir = '/storage/emulated/0/Download/MG Music';
      final file = File(_activeFilePath!);

      final dir = Directory(downloadDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await _activeClient!
          .send(request)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        return UpdateDownloadResult(
          success: false,
          message: 'Error del servidor: ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      DateTime lastUpdate = DateTime.now();

      final IOSink sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds > 400 ||
              downloadedBytes == contentLength) {
            lastUpdate = now;

            final progress = downloadedBytes / contentLength;
            final totalMB = contentLength / (1024 * 1024);
            final downloadedMB = downloadedBytes / (1024 * 1024);

            onProgress(progress, totalMB, downloadedMB);
          }
        }
      }

      await sink.flush();
      await sink.close();

      return UpdateDownloadResult(
        success: true,
        message: 'Descarga completada',
        filePath: _activeFilePath,
      );
    } on http.ClientException catch (_) {
      return UpdateDownloadResult(
        success: false,
        message: 'Descarga cancelada',
      );
    } on TimeoutException catch (_) {
      return UpdateDownloadResult(
        success: false,
        message: 'Tiempo de espera agotado. Verifica tu conexión.',
      );
    } on SocketException catch (_) {
      return UpdateDownloadResult(
        success: false,
        message: 'Sin conexión a internet.',
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('closed') || msg.contains('Connection closed')) {
        return UpdateDownloadResult(
          success: false,
          message: 'Descarga cancelada',
        );
      }
      return UpdateDownloadResult(
        success: false,
        message: 'Error de descarga: $e',
      );
    } finally {
      cancelDownload();
    }
  }
}

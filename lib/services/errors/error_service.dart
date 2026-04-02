// Copyright © 2026 Brayan Medrano - MG Music
// Servicio centralizado de errores con reporte vía WhatsApp

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Servicio para capturar, gestionar y mostrar errores en toda la aplicación
class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  String _deviceModel = 'Desconocido';
  String _osVersion = 'Desconocido';
  String _appVersion = 'Desconocido';

  /// Inicializa el servicio cargando info del sistema
  Future<void> init() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        _osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = iosInfo.utsname.machine;
        _osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      // Errores silenciosos en init para no bloquear la app
    }
  }

  /// Muestra un modal de error de reproducción con opción de reporte
  Future<void> handleAudioError({
    required Object error,
    LocalSong? song,
  }) async {
    // Filtrar errores de interrupción (normales al saltar canciones rápido)
    final errorStr = error.toString().toLowerCase();
    final errorCode = _extractErrorCode(error);
    
    if (errorCode.contains('abort') || 
        errorStr.contains('abort') || 
        errorStr.contains('interrupted')) {
      return;
    }

    String userTitle = 'Error de Reproducción';
    String userMessage = 'Ha ocurrido un error al intentar reproducir la canción.';

    // Detección de errores de archivo no encontrado (FileNotFound o Source Error code 0)
    final isFileNotFound = errorCode == 'PLAT-file_not_found' || 
                          errorCode == 'PLAT-0' ||
                          errorStr.contains('filenotfound') || 
                          errorStr.contains('enoent') ||
                          errorStr.contains('source error');

    if (isFileNotFound) {
      await _showMissingFileModal(song: song);
      return;
    }

    // Detección de otros errores conocidos para mensajes amigables
    if (error is PlatformException) {
      if (error.code == 'codec_not_supported' || error.message?.contains('codec') == true) {
        userMessage = 'El formato o códec de este archivo no es compatible con tu dispositivo.';
      } else if (error.code == '0' || error.message?.contains('Source error') == true) {
        userMessage = 'Error de lectura del archivo. Es posible que esté dañado o bloqueado.';
      }
    } else if (error.toString().contains('Failed to load') || error.toString().contains('404')) {
      userMessage = 'No se pudo cargar el archivo. Verifica tu conexión o si el archivo sigue existiendo.';
    } else if (error.toString().contains('Permission denied')) {
      userMessage = 'Permiso de acceso denegado. Asegúrate de que la app tenga permisos de archivos.';
    }

    final context = GlobalModalService.navigatorKey.currentContext;
    if (context == null) return;

    await GlobalModalService.show(
      title: userTitle,
      icon: Ionicons.musical_note,
      primaryColor: Colors.redAccent.shade700,
      message: '$userMessage\n\nSi el problema persiste, puedes reportarlo para ayudarnos a mejorar.\n\nCódigo técnico: $errorCode',
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.grey.shade700,
        ),
        ModalActionButton(
          label: 'Reportar',
          onPressed: () async {
            Navigator.of(context).pop();
            await _showReportConfirmation(
              errorCode: errorCode,
              errorDescription: error.toString(),
              song: song,
            );
          },
          color: Colors.green.shade700,
        ),
      ],
    );
  }

  /// Muestra un error genérico en la aplicación
  Future<void> handleGenericError({
    required String title,
    required Object error,
  }) async {
    String errorCode = _extractErrorCode(error);
    
    await GlobalModalService.show(
      title: title,
      icon: Ionicons.alert_circle_outline,
      primaryColor: Colors.orangeAccent.shade700,
      message: 'Ha ocurrido un problema inesperado.\n\nCódigo: $errorCode\nDetalle: ${error.toString()}',
      actions: [
        ModalActionButton(
          label: 'Entendido',
          onPressed: () => Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop(),
          color: Colors.grey.shade700,
        ),
      ],
    );
  }

  /// Extrae el código de error de forma dinámica
  String _extractErrorCode(Object error) {
    if (error is PlatformException) {
      return 'PLAT-${error.code}';
    }
    
    final errorStr = error.toString();
    if (errorStr.contains('PlayerInterruptedException')) return 'PLAY-INTERRUPT';
    if (errorStr.contains('FileNotFoundException') || errorStr.contains('ENOENT')) return 'FILE-NOT-FOUND';
    
    if (errorStr.contains('PlayerException')) {
      try {
        final dynamic playerError = error;
        return 'PLAY-${playerError.code}';
      } catch (_) {
        return 'PLAY-GENERIC';
      }
    }

    // Si es un error de just_audio u otro tipo con .code (usando dynamic por flexibilidad)
    try {
      return (error as dynamic).code.toString();
    } catch (_) {
      // Si no tiene código, devolvemos el tipo de error
      final type = error.runtimeType.toString();
      return type == 'String' ? 'RAW-MSG' : 'TYPE-$type';
    }
  }

  /// Muestra un modal especial para archivos que no existen
  Future<void> _showMissingFileModal({LocalSong? song}) async {
    final context = GlobalModalService.navigatorKey.currentContext;
    if (context == null) return;

    await GlobalModalService.show(
      title: 'Archivo no encontrado',
      icon: Ionicons.alert_outline,
      primaryColor: Colors.orangeAccent.shade400,
      message: 'Parece que el archivo "${song?.title ?? 'desconocido'}" ya no existe en tu dispositivo.\n\n'
          '¿Fue movido, renombrado o eliminado recientemente?',
      actions: [
        ModalActionButton(
          label: 'Entendido',
          onPressed: () => Navigator.of(context).pop(),
          color: Colors.grey.shade700,
        ),
      ],
    );
  }

  /// Solicita confirmación y permite agregar información extra
  Future<void> _showReportConfirmation({
    required String errorCode,
    required String errorDescription,
    LocalSong? song,
  }) async {
    final TextEditingController extraInfoController = TextEditingController();

    await GlobalModalService.show(
      title: 'Reportar al Desarrollador',
      icon: Ionicons.logo_whatsapp,
      primaryColor: Colors.green.shade700,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Se abrirá WhatsApp con el reporte técnico.\n\n'
            '¿Qué estabas haciendo cuando pasó? (Opcional):',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: extraInfoController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ej: Pasó al conectar audífonos, al cambiar de canción...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            '⚠️ El reporte incluye info del dispositivo y del archivo.',
            style: TextStyle(fontSize: 12, color: Colors.orangeAccent, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop(),
          color: Colors.grey.shade700,
        ),
        ModalActionButton(
          label: 'Reportar',
          onPressed: () async {
            final extraInfo = extraInfoController.text.trim();
            Navigator.of(GlobalModalService.navigatorKey.currentContext!).pop();
            await _sendErrorViaWhatsApp(
              errorCode: errorCode,
              errorDescription: errorDescription,
              song: song,
              extraInfo: extraInfo.isEmpty ? null : extraInfo,
            );
          },
          color: Colors.green.shade700,
        ),
      ],
    );
  }

  /// Construye el mensaje y abre WhatsApp
  Future<void> _sendErrorViaWhatsApp({
    required String errorCode,
    required String errorDescription,
    LocalSong? song,
    String? extraInfo,
  }) async {
    String songInfo = 'N/A';
    if (song != null) {
      final ext = song.path.split('.').last.toUpperCase();
      songInfo = '\n'
          '🎵 Canción: ${song.title}\n'
          '👤 Artista: ${song.artist}\n'
          '📁 Ruta: ${song.path}\n'
          '📄 Extensión: $ext';
    }

    final extraInfoStr = extraInfo != null 
        ? '\n💬 COMENTARIO USER: $extraInfo\n─────────────────────────' 
        : '';

    final message = '🚨 Reporte de Error — MG Music\n'
        '─────────────────────────\n'
        '📌 CÓDIGO: $errorCode\n'
        '📱 DISPOSITIVO: $_deviceModel\n'
        '🤖 SISTEMA: $_osVersion\n'
        '📦 APP VER: $_appVersion\n'
        '─────────────────────────$extraInfoStr\n'
        '📝 DETALLES:\n'
        'Error: $errorDescription\n'
        '─────────────────────────\n'
        '🎧 CONTEXTO MUSICAL:$songInfo\n'
        '─────────────────────────\n'
        'Enviado desde el sistema de reporte automatizado.';

    final url = Uri.parse(
      'https://wa.me/573168060939?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

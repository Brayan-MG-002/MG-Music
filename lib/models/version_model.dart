// Copyright © 2026 Brayan Medrano - MG Music
// Modelo para información de versiones y actualizaciones

/// Representa la información de versión obtenida del servidor remoto
class VersionModel {
  final String version;
  final int versionCode;
  final String title;
  final String changelog;
  final String websiteUrl;
  final String importance;
  final bool forceUpdate;

  VersionModel({
    required this.version,
    required this.versionCode,
    required this.title,
    required this.changelog,
    required this.websiteUrl,
    required this.importance,
    required this.forceUpdate,
  });

  /// Convierte JSON a objeto VersionModel
  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      version: json['version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      title: json['title'] ?? 'Actualización disponible',
      changelog: json['changelog'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      importance: json['importance'] ?? 'low',
      forceUpdate: json['force_update'] ?? false,
    );
  }

  /// Convierte objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'version_code': versionCode,
      'title': title,
      'changelog': changelog,
      'website_url': websiteUrl,
      'importance': importance,
      'force_update': forceUpdate,
    };
  }
}

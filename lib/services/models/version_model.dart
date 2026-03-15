// Copyright © 2026 Brayan Medrano - MG Music
// Modelo para información de versiones y actualizaciones

/// Representa la información de versión obtenida del servidor
class VersionModel {
  final String version;
  final int versionCode;
  final String title;
  final String changelog;
  final String websiteUrl;
  final String importance;
  final bool forceUpdate;

  // Campos para versión Beta
  final String? betaVersion;
  final int? betaVersionCode;
  final String? betaTitle;
  final String? betaChangelog;
  final String? betaWebsiteUrl;
  final String? betaImportance;

  VersionModel({
    required this.version,
    required this.versionCode,
    required this.title,
    required this.changelog,
    required this.websiteUrl,
    required this.importance,
    required this.forceUpdate,
    this.betaVersion,
    this.betaVersionCode,
    this.betaTitle,
    this.betaChangelog,
    this.betaWebsiteUrl,
    this.betaImportance,
  });

  /// Crea la instancia desde JSON
  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      version: json['version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      title: json['title'] ?? 'Actualización disponible',
      changelog: json['changelog'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      importance: json['importance'] ?? 'low',
      forceUpdate: json['force_update'] ?? false,
      // Beta fields
      betaVersion: json['beta_version'],
      betaVersionCode: json['beta_version_code'],
      betaTitle: json['beta_title'],
      betaChangelog: json['beta_changelog'],
      betaWebsiteUrl: json['beta_website_url'],
      betaImportance: json['beta_importance'],
    );
  }

  /// Convierte la instancia a JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'version_code': versionCode,
      'title': title,
      'changelog': changelog,
      'website_url': websiteUrl,
      'importance': importance,
      'force_update': forceUpdate,
      'beta_version': betaVersion,
      'beta_version_code': betaVersionCode,
      'beta_title': betaTitle,
      'beta_changelog': betaChangelog,
      'beta_website_url': betaWebsiteUrl,
      'beta_importance': betaImportance,
    };
  }
}

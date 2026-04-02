// Copyright © 2026 Brayan Medrano - MG Music
// Modelo para las notificaciones remotas de noti.json

class NotiRemoteAction {
  final String type;
  final String label;

  const NotiRemoteAction({required this.type, required this.label});

  factory NotiRemoteAction.fromJson(Map<String, dynamic> json) {
    return NotiRemoteAction(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'action_type': type,
        'label': label,
      };
}

class NotiRemoteItem {
  final String id;
  final String title;
  final String short;
  final String content;
  final String type;
  final String? icon;
  final String? iconUrl;
  final String? imageUrl;
  final String? version;
  final bool? isBeta;
  final DateTime timestamp;
  final DateTime expiry;
  final String? priority;
  final List<NotiRemoteAction> actions;

  NotiRemoteItem({
    required this.id,
    required this.title,
    required this.short,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.expiry,
    this.icon,
    this.iconUrl,
    this.imageUrl,
    this.version,
    this.isBeta,
    this.priority,
    this.actions = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiry);

  factory NotiRemoteItem.fromJson(Map<String, dynamic> json) {
    final actionsRaw = json['actions'] as List<dynamic>?;
    final singleAction = json['action'];

    List<NotiRemoteAction> parsedActions = [];
    if (actionsRaw != null) {
      parsedActions = actionsRaw
          .map((e) => NotiRemoteAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (singleAction != null) {
      parsedActions = [
        NotiRemoteAction.fromJson(singleAction as Map<String, dynamic>)
      ];
    }

    return NotiRemoteItem(
      id: json['id'] as String,
      title: json['title'] as String,
      short: json['short'] as String? ?? '',
      content: json['content'] as String,
      type: json['type'] as String? ?? 'info',
      icon: json['icon'] as String?,
      iconUrl: json['icon_url'] as String?,
      imageUrl: json['image_url'] as String? ?? json['banner_url'] as String?,
      version: json['version'] as String?,
      isBeta: json['is_beta'] as bool?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiry: DateTime.parse(json['expires_at'] as String),
      priority: json['priority'] as String?,
      actions: parsedActions,
    );
  }
}


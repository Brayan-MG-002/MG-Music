import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/services/models/noti_model.dart';
import 'package:workmanager/workmanager.dart';

/// Tipos de notificación
enum NotificationType { version, beta, notice }

/// Modelo para un ítem de notificación
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        type: NotificationType.values[json['type']],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
        data: json['data'] as Map<String, dynamic>?,
      );
}

/// Servicio que gestiona las notificaciones y actualizaciones en segundo plano
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  List<NotificationItem> _notifications = [];
  bool _initialized = false;

  final StreamController<Map<String, dynamic>> _actionController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onActionTriggered => _actionController.stream;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            triggerAction(data);
          } catch (_) {}
        }
      },
    );

    await _loadNotifications();
    _initialized = true;
    notifyListeners();
  }

  void triggerAction(Map<String, dynamic> actionData) {
    _actionController.add(actionData);
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('app_notifications') ?? [];
    _notifications = data
        .map((e) => NotificationItem.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('app_notifications', data);
  }

  Future<void> addNotification(NotificationItem item) async {
    final existingIndex = _notifications.indexWhere((n) => n.id == item.id);

    if (existingIndex != -1) {
      final existing = _notifications[existingIndex];
      if (existing.title == item.title && existing.message == item.message) return;

      _notifications[existingIndex] = item.copyWith(isRead: false);
    } else {
      _notifications.insert(0, item);
    }

    await _saveNotifications();
    notifyListeners();

    await _showSystemNotification(item);
  }

  Future<void> _showSystemNotification(NotificationItem item) async {
    const androidDetails = AndroidNotificationDetails(
      'app_updates',
      'Actualizaciones',
      channelDescription: 'Notificaciones sobre nuevas versiones y betas',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final payload = item.data != null ? jsonEncode(item.data) : null;

    await _localNotifications.show(
      item.id.hashCode,
      item.title,
      item.message,
      details,
      payload: payload,
    );
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      if (_notifications[index].type == NotificationType.notice) {
        await _persistReadIdLocally(id);
      }
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        if (_notifications[i].type == NotificationType.notice) {
          await _persistReadIdLocally(_notifications[i].id);
        }
      }
    }
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  static const String _remoteNotiUrl =
      'https://mg-special.web.app/Body/MG-Music/noti.json';

  Future<void> checkForUpdates() async {
    final updateResult = await UpdateService.checkForUpdate();
    if (updateResult['hasUpdate']) {
    }

    await checkForRemoteNotifications();
  }

  Future<void> checkForRemoteNotifications() async {
    try {
      final hasInternet = await UpdateService.hasInternetConnection();
      if (!hasInternet) return;

      final response = await http
          .get(Uri.parse(_remoteNotiUrl))
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response('timeout', 408),
          );

      if (response.statusCode != 200) return;

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawList = jsonData['notifications'] as List<dynamic>? ?? [];

      final items = rawList
          .map((e) => NotiRemoteItem.fromJson(e as Map<String, dynamic>))
          .where((item) => !item.isExpired)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notifications') ?? [];

      for (final item in items) {
        await addNotification(NotificationItem(
          id: item.id,
          title: item.title,
          message: item.content,
          type: NotificationType.notice,
          timestamp: item.timestamp,
          isRead: readIds.contains(item.id),
          data: {
            'short': item.short,
            'noti_type': item.type,
            if (item.icon != null) 'icon': item.icon,
            if (item.iconUrl != null) 'icon_url': item.iconUrl,
            if (item.imageUrl != null) 'image_url': item.imageUrl,
            if (item.version != null) 'version': item.version,
            if (item.isBeta != null) 'is_beta': item.isBeta,
            if (item.priority != null) 'priority': item.priority,
            'actions': item.actions.map((a) => a.toJson()).toList(),
          },
        ));
      }

      final activeIds = items.map((i) => i.id).toSet();
      final cleanedReadIds = readIds.where((id) => activeIds.contains(id)).toList();
      await prefs.setStringList('read_notifications', cleanedReadIds);
    } catch (_) {}
  }

  Future<void> _persistReadIdLocally(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList('read_notifications', readIds);
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final hasInternet = await UpdateService.hasInternetConnection();
    if (!hasInternet) return Future.value(true);

    final prefs = await SharedPreferences.getInstance();
    
    final updateResult = await UpdateService.checkForUpdate();
    if (updateResult['hasUpdate']) {
    }

    try {
      final response = await http.get(Uri.parse(NotificationService._remoteNotiUrl))
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => http.Response('timeout', 408),
          );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> rawList = jsonData['notifications'] as List<dynamic>? ?? [];
        
        final existingNotifsStr = prefs.getStringList('app_notifications') ?? [];
        final readIds = prefs.getStringList('read_notifications') ?? [];

        for (final nData in rawList) {
          final item = NotiRemoteItem.fromJson(nData as Map<String, dynamic>);
          if (item.isExpired) continue;
          
          if (!existingNotifsStr.any((e) => e.contains(item.id))) {
             final newItem = NotificationItem(
              id: item.id,
              title: item.title,
              message: item.content,
              type: NotificationType.notice,
              timestamp: item.timestamp,
              isRead: readIds.contains(item.id),
              data: {
                'short': item.short,
                'noti_type': item.type,
                if (item.icon != null) 'icon': item.icon,
                if (item.iconUrl != null) 'icon_url': item.iconUrl,
                if (item.imageUrl != null) 'image_url': item.imageUrl,
                if (item.version != null) 'version': item.version,
                if (item.isBeta != null) 'is_beta': item.isBeta,
                if (item.priority != null) 'priority': item.priority,
                'actions': item.actions.map((a) => a.toJson()).toList(),
              },
            );
            existingNotifsStr.add(jsonEncode(newItem.toJson()));
            await prefs.setStringList('app_notifications', existingNotifsStr);
            await _showSilentSystemNotification(newItem);
          }
        }
      }
    } catch (_) {}

    return Future.value(true);
  });
}

Future<void> _showSilentSystemNotification(NotificationItem item) async {
  final localNotifs = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifs.initialize(const InitializationSettings(android: androidInit));

  const androidDetails = AndroidNotificationDetails(
    'app_updates',
    'Actualizaciones',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  await localNotifs.show(
    item.id.hashCode,
    item.title,
    item.message,
    const NotificationDetails(android: androidDetails),
    payload: item.data != null ? jsonEncode(item.data) : null,
  );
}

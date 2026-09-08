import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static Future<void> showVpnNotification({
    required String title,
    required String body,
    bool isConnected = true,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'vpn_connection_channel',
      'VPN Connection Status',
      channelDescription: 'Notifications for VPN connection status updates',
      importance: Importance.max,
      priority: Priority.high,
      usesChronometer: isConnected,
      ongoing: isConnected,
      autoCancel: !isConnected,
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    try {
      await _notificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }
}

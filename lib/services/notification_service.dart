import 'dart:async';
import 'package:flutter/material.dart'; // Required for Color
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Set this to the currently active chat's ID so we can suppress redundant notifications
  static String? currentActiveChatId;

  static Future<void> initialize() async {
    // 1. Request Permission (alert, badge, sound)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[Notifications] Permission status: ${settings.authorizationStatus}');

    // 2. Create the Android notification channel FIRST before initializing the plugin.
    // This is crucial for Android 8+ — without an explicit channel, notifications are silent.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_messages',           // id
      'Chat Messages',           // name
      description: 'Notifications for new chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Register the channel with the Android system
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Setup Local Notifications plugin (uses named `settings` param in v21)
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notifications] Notification tapped: ${details.payload}');
      },
    );

    // 4. Request Android 13+ notification permission explicitly
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 5. Save/refresh FCM token in Firestore whenever we get one
    _fcm.getToken().then((token) {
      if (token != null) {
        debugPrint('[Notifications] Got FCM token.');
        FirestoreService.updateFcmToken(token);
      } else {
        debugPrint('[Notifications] FCM token is null — device may not support push.');
      }
    });

    _fcm.onTokenRefresh.listen((token) {
      debugPrint('[Notifications] FCM token refreshed.');
      FirestoreService.updateFcmToken(token);
    });

    // 6. Handle messages that arrive while the app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[Notifications] Foreground message received. chatId=${message.data['chatId']}');

      final chatId = message.data['chatId'];

      // Suppress notification if user is already looking at the active chat
      if (chatId != null && chatId == currentActiveChatId) {
        debugPrint('[Notifications] Suppressed — user is in the active chat.');
        return;
      }

      final title = message.notification?.title ?? message.data['title'] ?? 'New Message';
      final body  = message.notification?.body  ?? message.data['body']  ?? '';

      _showLocalNotification(title: title, body: body, chatId: chatId);
    });

    // 7. Handle tap on a notification that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[Notifications] App opened via notification tap.');
    });
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? chatId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF00E5FF),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // Use a stable ID derived from chatId so notifications for the same chat
    // update in place instead of stacking up.
    final int notifId = chatId != null ? chatId.hashCode.abs() % 2147483647 : DateTime.now().millisecond;

    await _localNotifications.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: chatId,
    );
  }

  static void stopListening() {
    // Placeholder for any future cleanup
  }
}

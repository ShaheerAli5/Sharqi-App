import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'SelfServiceChannel',
    'Self Service Notifications',
    importance: Importance.high,
    enableLights: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and store in device id / token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await StorageService.addValue(StorageService.keyDeviceId, token);
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      StorageService.addValue(StorageService.keyDeviceId, newToken);
    });

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(initSettings);

    // Create Android channel
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Handle background messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    String title = notification?.title ?? data['title'] ?? 'Self Service';
    String body = notification?.body ?? data['message'] ?? '';

    if (body.isNotEmpty) {
      _localNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}

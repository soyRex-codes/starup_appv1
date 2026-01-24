import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:foundervers/features/notifications/device_service.dart';
import 'package:foundervers/main.dart';
import 'package:foundervers/features/notifications/notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle Push Notifications via Firebase Cloud Messaging (FCM)
class PushNotificationService {
  // Singleton instance
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final DeviceService _deviceService = DeviceService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Setup Local Notifications (for foreground alerts)
      await _setupLocalNotifications();

      // 3. Get and Save Token
      await _saveToken();

      // 4. Listen for Token Refreshes
      _fcm.onTokenRefresh.listen(_onTokenRefresh);

      // 5. Check if app was launched from a terminated state by tapping a notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from notification: ${initialMessage.data}');
        // Delay navigation until the app is fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleMessageOpenedApp(initialMessage);
        });
      }

      // 6. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 7. Handle Background Message Taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 7. Subscribe to Broadcast Topic
      // For iOS, wait a bit to ensure APNs token is fully registered with Firebase
      if (!kIsWeb && Platform.isIOS) {
        debugPrint('Waiting for APNs token to register with Firebase...');
        await Future.delayed(const Duration(seconds: 3));
      }
      await _fcm.subscribeToTopic('all_users');
      debugPrint('Subscribed to topic: all_users');

      _initialized = true;
    }
  }

  /// Setup local notifications for foreground display
  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap - navigate to notifications page
        debugPrint('Local notification tapped: ${details.payload}');
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      },
    );

    // Create high importance channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              description:
                  'This channel is used for important notifications.', // description
              importance: Importance.max,
            ),
          );
    }
  }

  /// Save the FCM token to Supabase via DeviceService
  Future<void> _saveToken() async {
    try {
      // On iOS, we must wait for the APNs token to be generated before getting the FCM token
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('Waiting for APNs token...');
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _fcm.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('Waiting for APNs token (retry 2)...');
            await Future.delayed(const Duration(seconds: 2));
            apnsToken = await _fcm.getAPNSToken();
          }
        }
        if (apnsToken == null) {
          debugPrint('APNs token not available after retries. Push notifications may not work.');
          return;
        }
        debugPrint('APNs Token: $apnsToken');
      }



      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await _deviceService.registerToken(
            userId: user.id,
            token: token,
            platform: kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('FCM Token Refreshed: $newToken');
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _deviceService.registerToken(
        userId: user.id,
        token: newToken,
        platform: kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
      );
    }
  }

  /// Handle incoming foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground Message: ${message.notification?.title}');

    final notification = message.notification;
    // final android = message.notification?.android;

    // Show local notification
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap when app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened from background: ${message.data}');
    
    // Navigate to notifications page
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }
}

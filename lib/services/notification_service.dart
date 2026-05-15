import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    // FCM setup
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Request permission
    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus ==
        AuthorizationStatus.authorized) {
      // Get FCM token and save to Firestore
      await _saveFcmToken();

      // Listen to token refresh
      _messaging.onTokenRefresh.listen(_updateFcmToken);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? 'SupportClient',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  Future<void> _saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  Future<void> _updateFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'main_channel',
      'SupportClient',
      channelDescription: 'Main notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showNewReplyNotification({
    required String ticketTitle,
    required String senderName,
    required String message,
  }) async {
    await showLocalNotification(
      title: '$senderName replied to your ticket',
      body: '"$ticketTitle" — $message',
    );
  }

  Future<void> showStatusChangedNotification({
    required String ticketTitle,
    required String newStatus,
  }) async {
    final statusLabel = {
      'new':         'New',
      'in_progress': 'In Progress',
      'resolved':    'Resolved',
      'closed':      'Closed',
    }[newStatus] ?? newStatus;

    await showLocalNotification(
      title: 'Status updated',
      body: '"$ticketTitle" is now $statusLabel',
    );
  }

  Future<void> showTicketAssignedNotification({
    required String ticketTitle,
    required String agentName,
  }) async {
    await showLocalNotification(
      title: 'Ticket assigned',
      body: '"$ticketTitle" assigned to $agentName',
    );
  }
}
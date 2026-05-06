import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
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
  }

  Future<void> showNewReplyNotification({
    required String ticketTitle,
    required String senderName,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'replies_channel',
      'Réponses tickets',
      channelDescription: 'Notifications pour les nouvelles réponses',
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
      '$senderName a répondu à votre ticket',
      '"$ticketTitle" — $message',
      details,
    );
  }

  Future<void> showStatusChangedNotification({
    required String ticketTitle,
    required String newStatus,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'status_channel',
      'Changements de statut',
      channelDescription: 'Notifications pour les changements de statut',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final statusLabel = {
      'new': 'Nouveau',
      'in_progress': 'En cours',
      'resolved': 'Résolu',
      'closed': 'Fermé',
    }[newStatus] ?? newStatus;

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Statut mis à jour',
      '"$ticketTitle" est maintenant $statusLabel',
      details,
    );
  }

  Future<void> showTicketAssignedNotification({
    required String ticketTitle,
    required String agentName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'assigned_channel',
      'Tickets affectés',
      channelDescription: 'Notifications pour les tickets affectés',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Ticket pris en charge',
      '"$ticketTitle" a été assigné à $agentName',
      details,
    );
  }
}
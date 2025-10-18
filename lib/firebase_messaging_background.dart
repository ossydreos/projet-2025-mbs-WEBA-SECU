import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final FlutterLocalNotificationsPlugin local =
      FlutterLocalNotificationsPlugin();

  const InitializationSettings initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await local.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'uber_style_channel_v3',
    'Notifications Uber Style',
    description: 'Notifications répétitives pour nouvelles réservations',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('uber_classic_retro'),
  );
  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final String clientName = message.data['clientName'] ?? 'Client';
  final String reservationId = message.data['reservationId'] ??
      DateTime.now().millisecondsSinceEpoch.toString();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'uber_style_channel_v3',
    'Notifications Uber Style',
    channelDescription:
        'Notifications répétitives pour nouvelles réservations',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('uber_classic_retro'),
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    presentBadge: true,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await local.show(
    reservationId.hashCode,
    'Nouvelle réservation',
    'Nouvelle demande de $clientName',
    details,
  );
}




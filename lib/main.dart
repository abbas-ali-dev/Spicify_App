import 'dart:async';
import 'dart:io';

import 'package:Spicify/provider_book/reader_provider.dart';
import 'package:Spicify/screens/age_verification_screen.dart';
import 'package:Spicify/screens/audio_manager/AudioHandler.dart';
import 'package:Spicify/screens/audio_player_screen.dart';
import 'package:Spicify/screens/auth/login_screen.dart';
import 'package:Spicify/screens/auth_provider.dart';
import 'package:Spicify/screens/local_provider.dart';
import 'package:Spicify/screens/on_boarding_screen.dart';
import 'package:Spicify/screens/screen_protection.dart';
import 'package:Spicify/screens/series_screen.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../gen_l10n/app_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/book_directory.dart';
import 'model/book_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// FCM Background Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isIOS) {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        await setupFlutterNotifications();
        showFlutterNotification(message);
      }
    } catch (e) {
      print('Firebase already initialized: $e');
      await logAppError(
          message: e.toString(),
          location: "firebaseMessagingBackgroundHandler");
    }
  } else {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: FirebaseOptions(
          apiKey: 'AIzaSyA858R3v-dVGdAghDuVd2A6iC1xTOGFqnQ',
          appId: '1:463798466947:android:453341b33472ba4fa41eb6',
          messagingSenderId: '463798466947',
          projectId: 'spicify-eb1a8',
          storageBucket: 'spicify-eb1a8.firebasestorage.app',
        ));
        await setupFlutterNotifications();
        showFlutterNotification(message);
      }
    } catch (e) {
      print('Firebase already initialized: $e');
      await logAppError(
          message: e.toString(),
          location: "firebaseMessagingBackgroundHandler");
    }
  }
}

// Notification Channel (Android)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

// Flutter Local Notifications Plugin
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> setupFlutterNotifications() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Android Initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS Initialization
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // Create Android Notification Channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: android.smallIcon,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

late final AudioPlayerHandler audioHandler;
void main() async {
  debugDisableShadows = true;
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
        options: FirebaseOptions(
      apiKey: 'AIzaSyA858R3v-dVGdAghDuVd2A6iC1xTOGFqnQ',
      appId: '1:463798466947:android:453341b33472ba4fa41eb6',
      messagingSenderId: '463798466947',
      projectId: 'spicify-eb1a8',
      storageBucket: 'spicify-eb1a8.firebasestorage.app',
    ));
  }

  // Set FCM Background Handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Notifications
  await setupFlutterNotifications();

  // Request Permissions (iOS)
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // Set true for silent notifications
    );
  }

  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  final prefs = await SharedPreferences.getInstance();
  // In main() function:
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(AudioPlayer()),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.spicify.audio', // Match manifest
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: false, // Keep notification persistent
      androidStopForegroundOnPause: true, // Keep notification when paused
      androidNotificationIcon: 'mipmap/ic_launcher',
      preloadArtwork: true,
      // Add these for media controls:
      notificationColor: Colors.black,
    ),
  );

  await testFirestore();

  //Add delay of 3 seconds
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => localeProvider),
        Provider<SharedPreferences>.value(value: prefs),
      ],
      child: RepaintBoundary(child: SpicifyApp()),
    ),
  );
}

class SpicifyApp extends StatefulWidget {
  const SpicifyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyApp();
  }
}

class _MyApp extends State<SpicifyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final locale = Provider.of<LocaleProvider>(context).locale;

    return MaterialApp(
      title: 'Spicify',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('nl'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
      theme: ThemeData(primaryColor: Colors.black),
      home: AgeVerificationScreen(),
      // home: SeriesScreen(seriesId: 'YzwY6sKEuMms1laOBXOZ'),
    );
  }

  //SeriesScreen(
//             seriesId: 'YzwY6sKEuMms1laOBXOZ') //
}

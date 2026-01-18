import 'dart:io';

import 'package:Spicify/screens/favourites_screen.dart';
import 'package:Spicify/screens/home_screen.dart';
import 'package:Spicify/screens/subscriber_club_screen.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import 'explore_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _token;
  bool _notificationsEnabled = false;
  final List<Widget> _screens = [
    HomeScreen(),
    ExploreScreen(),
    FavouritesScreen(),
    SubscriberClubScreen(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initFCM();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initFCM() async {
    // Get FCM Token
    print("Token.......");
    if (Platform.isIOS) {
      _token = await FirebaseMessaging.instance.getAPNSToken();
    } else {
      _token = await FirebaseMessaging.instance.getToken();
    }

    print("FCM Token: $_token");

    await FirebaseFirestore.instance
        .collection('deviceTokens')
        .doc(_token.toString())
        .set({'token': _token.toString()});

    // Check Notification Settings (iOS)
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    setState(() {
      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    });

    // Foreground Messages
    FirebaseMessaging.onMessage.listen(showFlutterNotification);

    // When App is Opened from Terminated State
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleNotification(message);
    });

    // When App is in Background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification);
  }

  void _handleNotification(RemoteMessage message) {
    // Handle navigation based on message
    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (_) => NotificationScreen(message)),
    // );
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Request Permission (iOS)
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.requestPermission();
        setState(() {
          _notificationsEnabled =
              settings.authorizationStatus == AuthorizationStatus.authorized;
        });
      } else {
        // Android doesn't need runtime permission
        setState(() => _notificationsEnabled = true);
      }
    } else {
      // Can't programmatically disable on iOS, just update UI
      setState(() => _notificationsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Scaffold(
        body: _screens[_selectedIndex],
        backgroundColor: Colors.black,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0.0,
          backgroundColor: Colors.black,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: _selectedIndex == 0
                  ? Image.asset('asset/image/Home-fill.png',
                      width: 24, height: 24, color: AppColors.white)
                  : Image.asset('asset/image/Home.png',
                      width: 24, height: 24, color: AppColors.white),
              label: l10n.homeTab,
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 1
                  ? Image.asset('asset/image/Search-fill.png',
                      width: 24, height: 24, color: AppColors.white)
                  : Image.asset('asset/image/Search.png',
                      width: 24, height: 24, color: AppColors.white),
              label: l10n.searchTab,
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 2
                  ? Image.asset('asset/image/heart.png',
                      width: 24, height: 24, color: AppColors.white)
                  : Icon(CupertinoIcons.heart),
              label: l10n.favoritesTab,
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 3
                  ? Image.asset('asset/image/community(1).png',
                      width: 24, height: 24, color: AppColors.white)
                  : Image.asset('asset/image/community.png',
                      width: 24, height: 24, color: AppColors.white),
              label: l10n.clubTab,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NavigationHelper {
  static void pushReplacementWithTransition({
    required BuildContext context,
    required Widget targetPage,
    Duration duration = const Duration(milliseconds: 600),
    Duration reverseDuration = Duration.zero,
  }) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => targetPage,
        transitionDuration: duration,
        reverseTransitionDuration: reverseDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  static void pushWithTransition({
    required BuildContext context,
    required Widget targetPage,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = Duration.zero,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => targetPage,
        transitionDuration: duration,
        reverseTransitionDuration: reverseDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}

Widget starRating(bool filled) {
  return Container(
    width: 24,
    height: 24,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(),
    child: filled
        ? Image.asset("asset/image/u_fire.png")
        : Image.asset("asset/image/u_fire.png"),
  );
}

Future<void> logAppError({
  required String message,
  required String location,
  String? stack,
}) async {
  try {
    final errorData = {
      'message': message,
      'location': location,
      'stack': stack ?? '',
      'userAgent': _getUserAgent(),
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('app_errors').add(errorData);
    debugPrint('Error logged to Firestore');
  } catch (e) {
    debugPrint('Failed to log error: $e');
  }
}

/// Returns a userAgent-like string based on platform
String _getUserAgent() {
  if (kIsWeb) {
    return 'Flutter Web';
  } else if (Platform.isAndroid) {
    return 'Android Device';
  } else if (Platform.isIOS) {
    return 'iOS Device';
  } else if (Platform.isMacOS) {
    return 'macOS';
  } else if (Platform.isWindows) {
    return 'Windows';
  } else if (Platform.isLinux) {
    return 'Linux';
  } else {
    return 'Unknown Platform';
  }
}

String cleanSummary(String text) {
  return text
      .replaceAll(RegExp(r'\s+'),
          ' ') // replaces multiple spaces/newlines with a single space
      .replaceAll('\r', '')
      .trim(); // removes leading/trailing spaces
}

bool hasActiveSubscription(Map<String, dynamic>? user) {
  if (user == null || user['subscription'] == null) return false;

  final subscription = user['subscription'] as Map<String, dynamic>;
  final status = subscription['status']?.toString().toLowerCase() ?? '';

  // Parse Firestore timestamp or string date
  DateTime? endDate;
  final endValue = subscription['endDate'];

  if (endValue != null) {
    if (endValue is Timestamp) {
      endDate = endValue.toDate();
    } else if (endValue is String) {
      endDate = DateTime.tryParse(endValue);
    }
  }

  final now = DateTime.now();

  return ((status == 'active' || status == 'cancelling') &&
      endDate != null &&
      endDate.isAfter(now));
}

Future<void> testFirestore() async {
  final doc = await FirebaseFirestore.instance
      .collection('series')
      .doc('YzwY6sKEuMms1laOBXOZ')
      .get();

  print('Document exists: ${doc.exists}');
  print('Document data: ${doc.data()}');
}

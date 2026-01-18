import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'auth/login_screen.dart';
import 'main_bottom_navigation_screens.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  bool? isVerified;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool verified = prefs.getBool('age_verified') ?? false;

    if (!verified) {
      Future.delayed(Duration.zero, _showAgeDialog);
    } else {
      setState(() {
        isVerified = true;
      });
    }
  }

  void _showAgeDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: RepaintBoundary(child: const Text("Content Warning: 18+")),
        content: const Text(
            "Due to the nature of its content, access to this section is restricted to individuals aged 18 or above"),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: RepaintBoundary(child: const Text("No")),
            onPressed: () {
              if (Platform.isIOS) {
                exit(0); // iOS allows exit in some cases like age restriction
              } else {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const BlackScreen()));
              }
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: RepaintBoundary(child: const Text("Yes")),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('age_verified', true);
              setState(() {
                isVerified = true;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isVerified == true) {
      return MainScreen(); // ✅ Your Login screen here
    } else if (isVerified == false) {
      return const SizedBox(); // just wait until dialog is handled
    } else {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }
  }
}

class BlackScreen extends StatelessWidget {
  const BlackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: RepaintBoundary(
          child: Text(
            "Access Denied",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}

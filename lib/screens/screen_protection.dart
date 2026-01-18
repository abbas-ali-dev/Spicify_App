import 'package:flutter/services.dart';

class ScreenProtection {
  static const MethodChannel _channel = MethodChannel('screen_protection');

  static Future<void> enableProtection() async {
    await _channel.invokeMethod('enableProtection');
  }

  static Future<void> disableProtection() async {
    await _channel.invokeMethod('disableProtection');
  }
}

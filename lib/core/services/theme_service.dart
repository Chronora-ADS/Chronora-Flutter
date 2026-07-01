import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'theme_mode';
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier(ThemeMode.dark);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    notifier.value = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  static Future<void> toggle() async {
    final goingLight = notifier.value == ThemeMode.dark;
    notifier.value = goingLight ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, goingLight ? 'light' : 'dark');
  }

  static bool get isDark => notifier.value == ThemeMode.dark;
}

// lib/app_routes.dart
import 'package:flutter/material.dart';
import 'package:chronora_flutter/login_screen.dart';
import 'package:chronora_flutter/register_screen.dart';
import 'package:chronora_flutter/home_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    signup: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
  };
}
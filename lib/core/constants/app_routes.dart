import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/request_creation.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String serviceCreation = '/service-creation';
  static const String requestCreation = '/request-creation';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      accountCreation: (context) => const AccountCreationPage(),
      main: (context) => const MainPage(),
      requestCreation: (context) => const RequestCreationPage(), // Adicionar depois
      // serviceCreation: (context) => const ServiceCreationPage(), // Adicionar depois
    };
  }
}
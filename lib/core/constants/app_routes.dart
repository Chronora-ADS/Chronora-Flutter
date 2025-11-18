import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/profile_page.dart';
import 'package:chronora/widgets/perfil_edit.dart';
import 'package:chronora/widgets/perfil_delet.dart';
import 'package:chronora/core/models/user_model.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String serviceCreation = '/service-creation';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileDelete = '/profile/delete';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      accountCreation: (context) => const AccountCreationPage(),
      main: (context) => const MainPage(),
      profile: (context) => const ProfilePage(),
      profileEdit: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final user = args?['user'] as User?;
        final onProfileUpdated = args?['onProfileUpdated'] as VoidCallback?;
        if (user == null) return const LoginPage();
        return PerfilEdit(user: user, onProfileUpdated: onProfileUpdated ?? () {});
      },
      profileDelete: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final user = args?['user'] as User?;
        final onAccountDeleted = args?['onAccountDeleted'] as VoidCallback?;
        if (user == null) return const LoginPage();
        return PerfilDelet(user: user, onAccountDeleted: onAccountDeleted ?? () {});
      },
      // serviceCreation: (context) => const ServiceCreationPage(), // Adicionar depois
    };
  }
}
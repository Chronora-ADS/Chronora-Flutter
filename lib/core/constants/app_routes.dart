import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/profile_page.dart';
import 'package:chronora/widgets/perfil_edit.dart';
import 'package:chronora/widgets/perfil_delet.dart';
import 'package:chronora/core/models/user_model.dart';
// import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
// import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String profile = '/profile';

  // static const String buyChronos = '/buy-chronos';
  // static const String sellChronos = '/sell-chronos';
  // static const String serviceCreation = '/service-creation';


  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      accountCreation: (context) => const AccountCreationPage(),
      main: (context) => const MainPage(),

      // serviceCreation: (context) => const ServiceCreationPage(),
      // buyChronos: (context) => const BuyChronosPage(),
      // sellChronos: (context) => const SellChronosPage(),

    };
  }
}

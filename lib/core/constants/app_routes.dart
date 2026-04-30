import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/notification/notification_page.dart';
import 'package:chronora/pages/profile_page.dart';
import 'package:chronora/pages/requests/my_requests.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_creation.dart';
import 'package:chronora/pages/requests/request_accepted_view.dart';
import 'package:chronora/pages/requests/request_view.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_edit.dart';
import 'package:chronora/pages/requests/request_view.dart';
import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String requestCreation = '/request-creation';
  static const String requestView = '/request-view';
  static const String requestAcceptedView = '/request-accepted-view';
  static const String requestEditing = '/request-editing';
  static const String myRequests = '/my-orders';
  static const String buyChronos = '/buy-chronos';
  static const String sellChronos = '/sell-chronos';
  static const String notification = '/notification';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    if (routeName.startsWith('$requestView/')) {
      final id = int.tryParse(routeName.split('/').last);
      return MaterialPageRoute(
        builder: (context) => RequestView(serviceId: id),
        settings: settings,
      );
    }

    if (routeName.startsWith('$requestEditing/')) {
      final id = int.tryParse(routeName.split('/').last);
      return MaterialPageRoute(
        builder: (context) => RequestEditingPage(serviceId: id),
        settings: settings,
      );
    }

    switch (routeName) {
      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
      case accountCreation:
        return MaterialPageRoute(
          builder: (context) => const AccountCreationPage(),
          settings: settings,
        );
      case main:
        return MaterialPageRoute(
          builder: (context) => const MainPage(),
          settings: settings,
        );
      case buyChronos:
        return MaterialPageRoute(
          builder: (context) => const BuyChronosPage(),
          settings: settings,
        );
      case sellChronos:
        return MaterialPageRoute(
          builder: (context) => const SellChronosPage(),
          settings: settings,
        );
      case requestCreation:
        return MaterialPageRoute(
          builder: (context) => const RequestCreationPage(),
          settings: settings,
        );
      case notification:
        return MaterialPageRoute(
          builder: (context) => const NotificationPage(),
          settings: settings,
        );
      case requestAcceptedView:
        return MaterialPageRoute(
          builder: (context) => const RequestAcceptedView(),
          settings: settings,
        );
      default:
        // Rota padrão: volta para a main
        return MaterialPageRoute(
          builder: (context) => const MainPage(),
          settings: settings,
        );
    }
  }
}

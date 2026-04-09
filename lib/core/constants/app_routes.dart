import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/profile_page.dart';
import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
import 'package:chronora/pages/notification/notification_page.dart';
import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_creation.dart';
import 'package:chronora/pages/requests/request_view.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_edit.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String requestCreation = '/request-creation';
  static const String requestView = '/request-view';
  static const String requestEditing = '/request-editing';
  static const String myRequests = '/my-orders';
  static const String buyChronos = '/buy-chronos';
  static const String sellChronos = '/sell-chronos';
  static const String notification = '/notification';

  // Remove o mapa de rotas e usa apenas onGenerateRoute
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';
    
    // Rota para visualizar serviço: /request-view/2
    if (routeName.startsWith('/request-view/')) {
      final idString = routeName.split('/').last;
      final int? id = int.tryParse(idString);
      return MaterialPageRoute(
        builder: (context) => RequestView(serviceId: id),
        settings: settings,
      );
    }
    
    // Rota para visualizar serviço sem ID (fallback)
    if (routeName == '/request-view') {
      return MaterialPageRoute(
        builder: (context) => const MainPage(),
        settings: settings,
      );
    }
    
    // Rota para editar serviço: /request-editing/2
    if (routeName.startsWith('/request-editing/')) {
      final idString = routeName.split('/').last;
      final int? id = int.tryParse(idString);
      return MaterialPageRoute(
        builder: (context) => RequestEditingPage(serviceId: id),
        settings: settings,
      );
    }
    
    // Rota para editar serviço sem ID (fallback)
    if (routeName == '/request-editing') {
      return MaterialPageRoute(
        builder: (context) => const MainPage(),
        settings: settings,
      );
    }
    
    // Rotas normais
    switch (routeName) {
      case login:
        return MaterialPageRoute(builder: (context) => const LoginPage());
      case accountCreation:
        return MaterialPageRoute(builder: (context) => const AccountCreationPage());
      case main:
        return MaterialPageRoute(builder: (context) => const MainPage());
      case buyChronos:
        return MaterialPageRoute(builder: (context) => const BuyChronosPage());
      case sellChronos:
        return MaterialPageRoute(builder: (context) => const SellChronosPage());
      case requestCreation:
        return MaterialPageRoute(builder: (context) => const RequestCreationPage());
      case notification:
        return MaterialPageRoute(builder: (context) => const NotificationPage());
      default:
        // Rota padrão: volta para a main
        return MaterialPageRoute(builder: (context) => const MainPage());
    }
  }
}
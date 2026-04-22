import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/forgot_password_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
import 'package:chronora/pages/notification/notification_page.dart';
import 'package:chronora/pages/placeholder/coming_soon_page.dart';
import 'package:chronora/pages/profile_page.dart';
import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_creation.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_edit.dart';
import 'package:chronora/pages/requests/request_view.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String requestCreation = '/request-creation';
  static const String requestView = '/request-view';
  static const String requestEditing = '/request-editing';
  static const String buyChronos = '/buy-chronos';
  static const String sellChronos = '/sell-chronos';
  static const String forgotPassword = '/forgot-password';
  static const String myOrders = '/my-orders';
  static const String notifications = '/notification';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static String requestViewWithId(int id) => '$requestView/$id';
  static String requestEditingWithId(int id) => '$requestEditing/$id';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      accountCreation: (context) => const AccountCreationPage(),
      main: (context) => const MainPage(),
      buyChronos: (context) => const BuyChronosPage(),
      sellChronos: (context) => const SellChronosPage(),
      forgotPassword: (context) => const ForgotPasswordPage(),
      requestCreation: (context) => const RequestCreationPage(),
      requestView: (context) => const RequestView(),
      requestEditing: (context) => const RequestEditingPage(),
      notifications: (context) => const NotificationPage(),
      profile: (context) => const ProfilePage(),
      myOrders: (context) => const ComingSoonPage(
            title: 'Meus pedidos',
            description:
                'Esta tela ainda esta em construcao, mas a rota ja esta registrada para nao quebrar a navegacao.',
          ),
      settings: (context) => const ComingSoonPage(
            title: 'Configuracoes',
            description:
                'As configuracoes ainda nao foram implementadas nesta versao do app.',
          ),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    if (routeName.startsWith('$requestView/')) {
      final serviceId = _extractTrailingId(routeName, requestView);
      return MaterialPageRoute(
        builder: (context) => RequestView(serviceId: serviceId),
        settings: settings,
      );
    }

    if (routeName.startsWith('$requestEditing/')) {
      final serviceId = _extractTrailingId(routeName, requestEditing);
      return MaterialPageRoute(
        builder: (context) => RequestEditingPage(serviceId: serviceId),
        settings: settings,
      );
    }

    return null;
  }

  static int? _extractTrailingId(String routeName, String routePrefix) {
    final segments = routeName.split('/');
    if (segments.length < 3 || segments[1] != routePrefix.substring(1)) {
      return null;
    }
    return int.tryParse(segments.last);
  }
}

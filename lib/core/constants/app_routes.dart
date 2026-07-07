import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/forgot_password_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/auth/reset_password_page.dart';
import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
import 'package:chronora/pages/chronos/extrato_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/moderator/moderator_panel_page.dart';
import 'package:chronora/pages/notification/notification_page.dart';
import 'package:chronora/pages/settings/settings_page.dart';
import 'package:chronora/pages/profile_page.dart';
import 'package:chronora/pages/requests/my_requests.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_creation.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_edit.dart';
import 'package:chronora/pages/requests/order_in_progress_page.dart';
import 'package:chronora/pages/requests/request_accepted_view.dart';
import 'package:chronora/pages/requests/request_view.dart';
import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:chronora/widgets/auth_guard.dart';
import 'package:chronora/widgets/pending_service_cancellation_obligations.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountCreation = '/account-creation';
  static const String main = '/main';
  static const String requestCreation = '/request-creation';
  static const String requestView = '/request-view';
  static const String requestAcceptedView = '/request-accepted-view';
  static const String requestEditing = '/request-editing';
  static const String buyChronos = '/buy-chronos';
  static const String sellChronos = '/sell-chronos';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String myOrders = '/my-orders';
  static const String notifications = '/notification';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String orderInProgress = '/order-in-progress';
  static const String moderatorPanel = '/moderator-panel';
  static const String chronosExtrato = '/chronos-extrato';

  static String requestViewWithId(int id) => '$requestView/$id';
  static String requestEditingWithId(int id) => '$requestEditing/$id';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      accountCreation: (context) => const AccountCreationPage(),
      main: (context) => _protected(const MainPage()),
      buyChronos: (context) => _protected(
            const PendingActionGate(
              actionLabel: 'comprar Chronos',
              child: BuyChronosPage(),
            ),
          ),
      sellChronos: (context) => _protected(const SellChronosPage()),
      forgotPassword: (context) => const ForgotPasswordPage(),
      resetPassword: (context) => const ResetPasswordPage(),
      requestCreation: (context) => _protected(
            const PendingActionGate(
              actionLabel: 'criar pedido',
              child: RequestCreationPage(),
            ),
          ),
      requestView: (context) => _protected(const RequestView()),
      requestAcceptedView: (context) => _protected(const RequestAcceptedView()),
      requestEditing: (context) => _protected(const RequestEditingPage()),
      notifications: (context) => _protected(const NotificationPage()),
      profile: (context) => _protected(const ProfilePage()),
      myOrders: (context) => _protected(const MeusPedidosPage()),
      orderInProgress: (context) => _protected(const OrderInProgressPage()),
      moderatorPanel: (context) => _protected(const ModeratorPanelPage()),
      settings: (context) => _protected(const SettingsPage()),
      chronosExtrato: (context) => _protected(const ExtratoPage()),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    if (routeName.startsWith('$requestView/')) {
      final serviceId = _extractTrailingId(routeName, requestView);
      return MaterialPageRoute(
        builder: (context) => _protected(RequestView(serviceId: serviceId)),
        settings: settings,
      );
    }

    if (routeName.startsWith('$requestEditing/')) {
      final serviceId = _extractTrailingId(routeName, requestEditing);
      return MaterialPageRoute(
        builder: (context) =>
            _protected(RequestEditingPage(serviceId: serviceId)),
        settings: settings,
      );
    }

    if (routeName.startsWith(resetPassword)) {
      return MaterialPageRoute(
        builder: (context) => const ResetPasswordPage(),
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

  static Widget _protected(Widget child) {
    return AuthGuard(child: child);
  }
}

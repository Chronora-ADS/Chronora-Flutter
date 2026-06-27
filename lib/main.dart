import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_service.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/client_log_service.dart';
import 'core/services/global_notification_service.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/main_page.dart';
import 'widgets/pending_service_cancellation_obligations.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ClientLogService.initializeGlobalHandlers();

      Uri? initialUri;
      if (!kIsWeb) {
        try {
          initialUri = await AppLinks().getInitialLink();
        } catch (_) {}
      }

      runApp(ChronoraFlutter(initialUri: initialUri));
    },
    (error, stackTrace) async {
      await ClientLogService.logError(
        error: error,
        stackTrace: stackTrace,
        source: 'run_zoned_guarded',
      );
    },
  );
}

class ChronoraFlutter extends StatefulWidget {
  final Uri? initialUri;

  const ChronoraFlutter({super.key, this.initialUri});

  @override
  State<ChronoraFlutter> createState() => _ChronoraFlutterState();
}

class _ChronoraFlutterState extends State<ChronoraFlutter> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _linkSubscription = AppLinks().uriLinkStream.listen(_handleIncomingLink);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handleIncomingLink(Uri uri) {
    if (!_isPasswordRecoveryUrl(uri)) return;

    final token = ResetPasswordPage.extractAccessToken(uri);
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(accessToken: token),
      ),
      (route) => false,
    );
  }

  bool _isPasswordRecoveryUrl(Uri uri) {
    final location = uri.toString();
    return location.contains('reset-password') ||
        location.contains('type=recovery') ||
        location.contains('access_token=');
  }

  @override
  Widget build(BuildContext context) {
    // Na web, Uri.base contém o hash com access_token; no mobile vem do AppLinks
    final Uri? effectiveUri =
        widget.initialUri ?? (kIsWeb ? Uri.base : null);
    final isRecovery =
        effectiveUri != null && _isPasswordRecoveryUrl(effectiveUri);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Chronora',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0B0C0C),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.branco),
          trackColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      home: isRecovery
          ? ResetPasswordPage(
              accessToken: ResetPasswordPage.extractAccessToken(effectiveUri),
            )
          : const _AuthGate(),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _resolveSession();
  }

  Future<bool> _resolveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (!rememberMe) {
      await AuthSessionService.clearSession();
      return false;
    }

    final token = await AuthSessionService.getValidAccessToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthSessionService.clearSession();
      }
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        if (isLoggedIn) {
          GlobalNotificationService.instance.start(_navigatorKey);
          return const PendingServiceCancellationOverlay(
            child: MainPage(),
          );
        }
        GlobalNotificationService.instance.stop();
        return const LoginPage();
      },
    );
  }
}

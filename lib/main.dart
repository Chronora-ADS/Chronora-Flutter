import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api/api_service.dart';
import 'core/constants/app_routes.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/client_log_service.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/main_page.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ClientLogService.initializeGlobalHandlers();
      runApp(const ChronoraFlutter());
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

class ChronoraFlutter extends StatelessWidget {
  final Uri? initialUri;

  const ChronoraFlutter({super.key, this.initialUri});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronora',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0B0C0C),
      ),
      home: _isPasswordRecoveryUrl(initialUri ?? Uri.base)
          ? ResetPasswordPage(
              accessToken:
                  ResetPasswordPage.extractAccessToken(initialUri ?? Uri.base),
            )
          : const _AuthGate(),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }

  bool _isPasswordRecoveryUrl(Uri uri) {
    final location = uri.toString();
    return location.contains('/reset-password') ||
        location.contains('type=recovery') ||
        location.contains('access_token=');
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
        if (isLoggedIn) return const MainPage();
        return const LoginPage();
      },
    );
  }
}

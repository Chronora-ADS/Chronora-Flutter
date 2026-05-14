import 'package:flutter/material.dart';

import '../core/services/auth_session_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late Future<bool> _hasValidSessionFuture;

  @override
  void initState() {
    super.initState();
    _hasValidSessionFuture = _hasValidSession();
  }

  Future<bool> _hasValidSession() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null || token.isEmpty) {
      await AuthSessionService.clearSession();
      return false;
    }

    return true;
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasValidSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return widget.child;
        }

        _redirectToLogin();
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/services/auth_service.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          final appRouter = AppRouter(authService);
          
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Chronora',
            routerConfig: appRouter.router,
            theme: ThemeData(
              primarySwatch: Colors.amber,
              scaffoldBackgroundColor: const Color(0xFF0B0C0C),
              fontFamily: 'Roboto',
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'core/constants/app_routes.dart';

void main() {
  runApp(const ChronoraFlutter());
}

class ChronoraFlutter extends StatelessWidget {
  const ChronoraFlutter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronora',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0B0C0C),
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute, // Apenas isso, sem routes
      debugShowCheckedModeBanner: false,
    );
  }
}
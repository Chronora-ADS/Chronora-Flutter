// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Suas telas e cores
import 'package:chronora_flutter/login_screen.dart';
import 'package:chronora_flutter/app_colors.dart';
import 'package:chronora_flutter/home_screen.dart';
import 'package:chronora_flutter/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 Inicialize com as credenciais do SEU projeto no Supabase
  await Supabase.initialize(
    url: 'https://ggmujtkhkvlujdynkbkm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnbXVqdGtoa3ZsdWpkeW5rYmttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2OTQ1MDQsImV4cCI6MjA3NzI3MDUwNH0.wchwPiPBUIh0qB94lPXxeXMnUzdDu6fMOwrnry-ffZE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronora',
      theme: ThemeData(
        primaryColor: AppColors.primaryLightYellow,
        scaffoldBackgroundColor: AppColors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDarkerYellow,
          foregroundColor: AppColors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(AppColors.primaryLightYellow.value, const <int, Color>{
            50: Color(0xFFFFF8E1),
            100: Color(0xFFFFECB3),
            200: Color(0xFFFFE082),
            300: Color(0xFFFFD54F),
            400: Color(0xFFFFCA28),
            500: AppColors.primaryLightYellow,
            600: Color(0xFFFFB300),
            700: Color(0xFFFFA000),
            800: Color(0xFFFF8F00),
            900: Color(0xFFFF6F00),
          }),
        ).copyWith(secondary: AppColors.blue),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'features/auth/pages/login_page.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Chronora',
            theme: ThemeData(
                primarySwatch: Colors.amber,
                fontFamily: 'Roboto',
                scaffoldBackgroundColor: const Color(0xFF0B0C0C),
            ),
            home: const LoginPage(),
            debugShowCheckedModeBanner: false,
        );
    }
}
import 'package:flutter/material.dart';
import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/auth/my_request.dart' as my_request_page;
import 'package:chronora/pages/auth/view_requests.dart' as view_requests_page;

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
      routes: {
        // Rotas principais
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.accountCreation: (context) => const AccountCreationPage(),
        AppRoutes.main: (context) => const MainPage(),
        
        // Rotas do menu lateral - REMOVENDO O CONST
        '/my-orders': (context) => my_request_page.MeusPedidos(),
        
        // Rota para visualizar pedido
        '/view-request': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          
          return view_requests_page.VerPedido(
            pedido: args?['pedido'] ?? {},
            ehProprietario: args?['ehProprietario'] ?? false,
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
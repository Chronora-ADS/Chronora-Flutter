import 'package:flutter/material.dart';
import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/auth/my_request.dart';
import 'package:chronora/pages/auth/view_requests.dart';

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
        
        // Rotas do menu lateral que EXISTEM
        '/my-orders': (context) => const MeusPedidos(),
        
        // Rotas do menu lateral que NÃO EXISTEM ainda (com placeholders)
        '/notifications': (context) => _buildPlaceholderPage('Notificações'),
        '/profile': (context) => _buildPlaceholderPage('Perfil'),
        '/settings': (context) => _buildPlaceholderPage('Configurações'),
        '/buy-chronos': (context) => _buildPlaceholderPage('Comprar Chronos'),
        '/sell-chronos': (context) => _buildPlaceholderPage('Vender Chronos'),
        
        // Rota para visualizar pedido
        '/view-request': (context) => const VerPedido(
          pedido: {},
          ehProprietario: false,
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
  
  // Método para criar páginas placeholder para rotas que ainda não existem
  static Widget _buildPlaceholderPage(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: Text(
          '$title - Página em desenvolvimento',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
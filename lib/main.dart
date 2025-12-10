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
        
        // Rota para visualizar pedido - COM VALIDAÇÃO SEGURA
        '/view-request': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          
          // VALIDAÇÃO SEGURA - SEM POSSIBILIDADE DE CRASH
          if (args == null || args is! Map<String, dynamic>) {
            return Scaffold(
              appBar: AppBar(title: const Text('Erro')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Pedido não encontrado', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Tente novamente mais tarde', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final pedido = args['pedido'];
          final ehProprietario = args['ehProprietario'] ?? false;
          
          return view_requests_page.VerPedido(
            pedido: pedido is Map<String, dynamic> ? pedido : {},
            ehProprietario: ehProprietario is bool ? ehProprietario : false,
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
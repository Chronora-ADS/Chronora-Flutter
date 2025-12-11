import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/app_routes.dart';
import '../services/auth_service.dart';

import 'package:chronora/pages/auth/login_page.dart';
import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:chronora/pages/sell_chronos/pix_sell_page.dart';
import 'package:chronora/pages/sell_chronos/sell_success_page.dart';
import 'package:chronora/pages/buy_chronos/buy_success_page.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_creation.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_edit.dart';
import 'package:chronora/core/models/main_page_requests_model.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.login,
    routes: [
      // ROTAS PÚBLICAS (acesso sem login)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountCreation,
        name: 'account-creation',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AccountCreationPage(),
        ),
      ),

      // ROTAS PROTEGIDAS (requerem login)
      GoRoute(
        path: AppRoutes.main,
        name: 'main',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const MainPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.buyChronos,
        name: 'buy-chronos',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BuyChronosPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.sellChronos,
        name: 'sell-chronos',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SellChronosPage(),
        ),
      ),
      GoRoute(
        path: '/pix-sell',
        name: 'pix-sell',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            key: state.pageKey,
            child: PixSellPage(
              chronosAmount: extra['chronosAmount'] ?? 0,
              totalAmount: (extra['totalAmount'] ?? 0.0).toDouble(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/sell-success',
        name: 'sell-success',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            key: state.pageKey,
            child: SellSuccessPage(
              chronosAmount: extra['chronosAmount'] ?? 0,
              totalAmount: (extra['totalAmount'] ?? 0.0).toDouble(),
              pixKey: extra['pixKey']?.toString() ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/buy-success',
        name: 'buy-success',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            key: state.pageKey,
            child: BuySuccessPage(
              chronosAmount: extra['chronosAmount'] ?? 0,
              totalAmount: (extra['totalAmount'] ?? 0.0).toDouble(),
              paymentMethod: extra['paymentMethod']?.toString() ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.requestCreation,
        name: 'request-creation',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RequestCreationPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.requestEditing,
        name: 'request-editing',
        pageBuilder: (context, state) {
          Service? service;
          
          // Extrai o Service do state.extra
          final extra = state.extra;
          if (extra is Service) {
            service = extra;
          } else if (extra is Map<String, dynamic>) {
            // Tenta extrair de um Map
            final serviceFromMap = extra['service'];
            if (serviceFromMap is Service) {
              service = serviceFromMap;
            }
          }
          
          return MaterialPage(
            key: state.pageKey,
            child: RequestEditingPage(service: service),
          );
        },
      ),
    ],
    
    // REDIRECIONAMENTO - LÓGICA DE SEGURANÇA
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isAuthenticated = authService.isAuthenticated;
      
      final publicRoutes = [AppRoutes.login, AppRoutes.accountCreation];
      final isPublicRoute = publicRoutes.contains(state.location);
      
      // 1. USUÁRIO NÃO AUTENTICADO tentando acessar rota privada
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }
      
      // 2. USUÁRIO AUTENTICADO tentando acessar rota de autenticação
      if (isAuthenticated && isPublicRoute) {
        return AppRoutes.main;
      }
      
      // 3. Permanece na rota atual
      return null;
    },
    
    // Atualizar quando o estado de autenticação mudar
    refreshListenable: authService,
    
    // Tratamento de erros
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Página não encontrada',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.main),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
  );
}
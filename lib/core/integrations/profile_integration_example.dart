// Exemplo de integração da tela de perfil no seu aplicativo

import 'package:flutter/material.dart';
import '../../pages/profile_page.dart';
import '../../core/constants/app_routes.dart';

/// Adicione este método no seu menu/navigation
/// para acessar a tela de perfil

class ProfileIntegrationExample {
  
  /// Navegar para página de perfil
  static void navigateToProfilePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  /// Abrir modal de edição de perfil
  static void openEditProfileModal(BuildContext context, user) {
    Navigator.pushNamed(
      context,
      AppRoutes.profileEdit,
      arguments: {
        'user': user,
        'onProfileUpdated': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  /// Abrir modal de deletar conta
  static void openDeleteAccountModal(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.profileDelete,
      arguments: {
        'onAccountDeleted': () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      },
    );
  }

  /// Exemplo de menu com opções de perfil
  static Widget exampleMenuButton(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          onTap: () => navigateToProfilePage(context),
          child: const Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 8),
              Text('Meu Perfil'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            // Implementar carregamento do usuário
            // openEditProfileModal(context, user);
          },
          child: const Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Editar Perfil'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => openDeleteAccountModal(context),
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Deletar Conta', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}

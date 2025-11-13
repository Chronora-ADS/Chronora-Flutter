// Exemplo de integração da tela de perfil no seu aplicativo

import 'package:flutter/material.dart';
import '../../pages/profile_page.dart';
import '../../widgets/perfil_edit.dart';
import '../../widgets/perfil_delet.dart';

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
    showDialog(
      context: context,
      builder: (context) => ProfileEditModal(
        user: user,
        onProfileUpdated: () {
          // Recarregar dados após atualização
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Abrir modal de deletar conta
  static void openDeleteAccountModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProfileDeleteModal(
        onAccountDeleted: () {
          // Redirecionar para login após deletar conta
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        },
      ),
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

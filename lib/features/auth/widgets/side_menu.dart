import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Container(
        color: AppColors.branco,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header do Menu
            Container(
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.amareloClaro,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Página inicial',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                  ),
                ],
              ),
            ),

            // Seção principal do menu
            _buildMenuSection(
              title: 'Crie um pedido',
              children: [
                _buildMenuItem(
                  icon: Icons.add_circle_outline,
                  title: 'Meus pedidos',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Navegar para meus pedidos
                  },
                ),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Carteira',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Navegar para carteira
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: 'Notificações',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Navegar para notificações
                  },
                ),
              ],
            ),

            const Divider(height: 1, color: AppColors.preto),

            // Seção de perfil
            _buildMenuSection(
              title: 'Perfil',
              children: [
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'Configurações',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    // Navegar para configurações
                  },
                ),
                _buildMenuItem(
                  icon: Icons.exit_to_app,
                  title: 'Log out',
                  onTap: () {
                    Navigator.pop(context); // Fecha o drawer
                    _logout(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.preto,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.preto,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
    );
  }

  void _logout(BuildContext context) {
    // Implementar lógica de logout
    // Limpar token, etc.
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}

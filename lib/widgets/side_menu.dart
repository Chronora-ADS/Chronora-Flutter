import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../widgets/header.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.6,
      child: Container(
        color: AppColors.preto, // Mudei para preto para combinar com os ícones brancos
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header do Menu
            const Header(),

            // Seção principal do menu
            _buildMenuSection(
              title: '',
              children: [
                _buildMenuItem(
                  icon: 'assets/img/HomeWhite.png',
                  title: 'Página Inicial',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, AppRoutes.main);
                  },
                ),
                _buildMenuItem(
                  icon: 'assets/img/PlusWhite.png',
                  title: 'Crie um pedido',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/service-creation');
                  },
                ),
                _buildMenuItem(
                  icon: 'assets/img/SuitcaseWhite.png',
                  title: 'Meus pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/my-orders');
                  },
                ),
                _buildMenuItem(
                  icon: 'assets/img/CoinWhite.png',
                  title: 'Carteira',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/wallet');
                  },
                ),
                _buildMenuItem(
                  icon: 'assets/img/NotificationsWhite.png',
                  title: 'Notificações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ],
            ),

            const Divider(height: 1, color: AppColors.branco),

            // Seção de perfil
            _buildMenuSection(
              title: 'Perfil',
              children: [
                _buildMenuItem(
                  icon: 'assets/img/UserIconWhite.png',
                  title: 'Perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                _buildMenuItem(
                  icon: 'assets/img/SettingsWhite.png',
                  title: 'Configurações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildMenuItem(
                  icon: 'assets/img/Logout.png',
                  title: 'Log out',
                  onTap: () {
                    Navigator.pop(context);
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
        if (title.isNotEmpty) // Só mostra o título se não for vazio
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.branco,
              ),
            ),
          ),
        ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Image.asset(
        icon,
        width: 24,
        height: 24,
        // Removido o color - imagens PNG não suportam
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.branco,
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
import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onClose;

  const SideMenu({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      width: screenSize.width * 0.6,
      color: AppColors.amareloUmPoucoEscuro,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Seção principal do menu
                _buildMenuSection(
                  title: '',
                  children: [
                    _buildMenuItem(
                      iconPath: 'assets/img/HomeWhite.png',
                      title: 'Página Inicial',
                      onTap: () {
                        onClose();
                        Navigator.pushNamed(context, '/main');
                      },
                    ),
                    _buildMenuItem(
                      iconPath: 'assets/img/PlusWhite.png',
                      title: 'Crie um pedido',
                      onTap: () {
                        onClose();
                        Navigator.pushNamed(context, '/service-creation');
                      },
                    ),
                    _buildMenuItem(
                      iconPath: 'assets/img/SuitcaseWhite.png',
                      title: 'Meus pedidos',
                      onTap: () {
                        onClose();
                        Navigator.pushNamed(context, '/my-orders');
                      },
                    ),
                    _buildMenuItem(
                      iconPath: 'assets/img/CoinWhite.png',
                      title: 'Carteira',
                      onTap: () {
                        onClose();
                        // fazer modal
                      },
                    ),
                    _buildMenuItem(
                      iconPath: 'assets/img/NotificationWhite.png',
                      title: 'Notificações',
                      onTap: () {
                        onClose();
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                  ],
                ),

                const Divider(height: 1, color: AppColors.branco),

                // Seção de perfil
                _buildMenuSection(
                  title: '',
                  children: [
                    _buildMenuItem(
                      iconPath: 'assets/img/UserWhite.png',
                      title: 'Perfil',
                      onTap: () {
                        onClose();
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    _buildMenuItem(
                      iconPath: 'assets/img/SettingsWhite.png',
                      title: 'Configurações',
                      onTap: () {
                        onClose();
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    _buildMenuItem(
                      iconPath: 'assets/img/Logout.png',
                      title: 'Log out',
                      onTap: () {
                        onClose();
                        _logout(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        if (title.isNotEmpty)
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
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        child: Image.asset(
          iconPath,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.branco,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minLeadingWidth: 0,
    );
  }

  void _logout(BuildContext context) {
    // Implementar lógica de logout
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}

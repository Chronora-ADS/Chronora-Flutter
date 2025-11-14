import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.amareloUmPoucoEscuro,
      child: Column(
        children: [
          // Conteúdo principal do menu - ocupa o espaço disponível
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Seção principal do menu
                _buildMenuSection(
                  title: '',
                  children: [
                    _buildMenuItem(
                      icon: 'assets/img/HomeWhite.png',
                      title: 'Página Inicial',
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.main);
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/PlusWhite.png',
                      title: 'Crie um pedido',
                      onTap: () {
                        Navigator.pushNamed(context, '/service-creation');
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/SuitcaseWhite.png',
                      title: 'Meus pedidos',
                      onTap: () {
                        Navigator.pushNamed(context, '/my-orders');
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/CoinWhite.png',
                      title: 'Carteira',
                      onTap: () {
                        Navigator.pushNamed(context, '/wallet');
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/NotificationsWhite.png',
                      title: 'Notificações',
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Seção de perfil - SEMPRE no final
          Column(
            children: [
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.branco,
              ),
              _buildMenuSection(
                title: '',
                children: [
                  _buildMenuItem(
                    icon: 'assets/img/UserIconWhite.png',
                    title: 'Perfil',
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  _buildMenuItem(
                    icon: 'assets/img/SettingsWhite.png',
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  
                  // Item Log out personalizado - Ícone e texto centralizados
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          _logout(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Centraliza ícone e texto
                            children: [
                              Image.asset(
                                'assets/img/Logout.png',
                                width: 24,
                                height: 24,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12), // Espaço entre ícone e texto
                              const Text(
                                'Log out',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                fontSize: 20,
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
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          color: AppColors.branco,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 0,
    );
  }

  void _logout(BuildContext context) {
    // Implementar lógica de logout
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}
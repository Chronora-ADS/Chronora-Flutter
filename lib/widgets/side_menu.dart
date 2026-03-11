import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth_service.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onWalletPressed;

  const SideMenu({super.key, required this.onWalletPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.amareloUmPoucoEscuro,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuSection(
                  title: '',
                  children: [
                    _buildMenuItem(
                      icon: 'assets/img/HomeWhite.png',
                      title: 'Página Inicial',
                      onTap: () {
                        context.go(AppRoutes.main);
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/PlusWhite.png',
                      title: 'Crie um pedido',
                      onTap: () {
                        context.push(AppRoutes.requestCreation);
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/SuitcaseWhite.png',
                      title: 'Meus pedidos',
                      onTap: () {
                        // Navega para main page que mostra os pedidos
                        context.go(AppRoutes.main);
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/CoinWhite.png',
                      title: 'Carteira',
                      onTap: onWalletPressed,
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/NotificationsWhite.png',
                      title: 'Notificações',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notificações em desenvolvimento')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perfil em desenvolvimento')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: 'assets/img/SettingsWhite.png',
                    title: 'Configurações',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configurações em desenvolvimento')),
                      );
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/img/Logout.png',
                                width: 24,
                                height: 24,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
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

  Future<void> _logout(BuildContext context) async {
    try {
      // Usa o AuthService para fazer o logout corretamente
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      // Remove apenas o token de autenticação, mantendo o e-mail salvo
      final prefs = await SharedPreferences.getInstance();
      
      // Log antes do logout
      final emailSalvo = prefs.getString('remembered_email');
      print('🔍 E-mail salvo antes do logout: "$emailSalvo"');
      print('🔍 Chaves antes do logout: ${prefs.getKeys()}');
      
      // Remove apenas o token, mantém o e-mail salvo
      await prefs.remove('auth_token');
      
      // Log após logout
      print('🗑️ Logout realizado: token removido, e-mail mantido');
      print('🔍 Chaves após logout: ${prefs.getKeys()}');
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
    }
    
    // Usa GoRouter para navegar para o login
    if (context.mounted) {
      final router = GoRouter.of(context);
      router.go(AppRoutes.login);
    }
  }
}

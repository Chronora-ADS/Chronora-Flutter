import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/services/auth_session_service.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback onWalletPressed;
  final String userName;
  final double userRating;
  final String? userPhotoUrl;

  const SideMenu({
    super.key,
    required this.onWalletPressed,
    this.userName = 'Usuario',
    this.userRating = 0.0,
    this.userPhotoUrl,
  });

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
                _buildUserHeader(),
                _buildMenuSection(
                  title: '',
                  children: [
                    _buildMenuItem(
                      icon: 'assets/img/HomeWhite.png',
                      title: 'Pagina Inicial',
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.main);
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/PlusWhite.png',
                      title: 'Crie um pedido',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.requestCreation,
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/SuitcaseWhite.png',
                      title: 'Meus pedidos',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.myOrders);
                      },
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/CoinWhite.png',
                      title: 'Carteira',
                      onTap: onWalletPressed,
                    ),
                    _buildMenuItem(
                      icon: 'assets/img/NotificationsWhite.png',
                      title: 'Notificacoes',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.notifications);
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
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  ),
                  _buildMenuItem(
                    icon: 'assets/img/SettingsWhite.png',
                    title: 'Configuracoes',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                            horizontal: 8,
                            vertical: 8,
                          ),
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

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            backgroundImage: (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                ? NetworkImage(userPhotoUrl!)
                : null,
            child: (userPhotoUrl == null || userPhotoUrl!.isEmpty)
                ? const Icon(Icons.person, size: 30, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: AppColors.branco),
                    const SizedBox(width: 4),
                    Text(
                      userRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Sua avaliacao',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.branco,
                          fontSize: 12,
                        ),
                      ),
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
    final token = await AuthSessionService.getValidAccessToken();

    if (token != null) {
      try {
        await ApiService.post('/auth/logout', {}, token: token);
      } catch (_) {
        // Mesmo se o logout remoto falhar, limpamos o token localmente.
      }
    }

    await AuthSessionService.clearSession();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}

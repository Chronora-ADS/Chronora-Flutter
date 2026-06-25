import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/services/auth_session_service.dart';
import 'pending_service_cancellation_obligations.dart';

class SideMenu extends StatefulWidget {
  final VoidCallback onWalletPressed;
  final String? userName;
  final double? userRating;
  final String? userPhotoUrl;

  const SideMenu({
    super.key,
    required this.onWalletPressed,
    this.userName,
    this.userRating,
    this.userPhotoUrl,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String _loadedUserName = 'Usuário';
  double _loadedUserRating = 0.0;
  String? _loadedUserPhotoUrl;
  bool _isModerator = false;

  String get _displayUserName {
    final name = widget.userName?.trim();
    return name != null && name.isNotEmpty ? name : _loadedUserName;
  }

  double get _displayUserRating => widget.userRating ?? _loadedUserRating;

  String? get _displayUserPhotoUrl {
    final photo = widget.userPhotoUrl?.trim();
    return photo != null && photo.isNotEmpty ? photo : _loadedUserPhotoUrl;
  }

  static const _kName = 'side_menu_user_name';
  static const _kRating = 'side_menu_user_rating';
  static const _kPhoto = 'side_menu_user_photo';
  static const _kIsMod = 'side_menu_is_moderator';

  @override
  void initState() {
    super.initState();
    _loadCached();
    _fetchUserData();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_kName);
    final rating = prefs.getDouble(_kRating);
    final photo = prefs.getString(_kPhoto);
    final isMod = prefs.getBool(_kIsMod) ?? false;
    if (!mounted) return;
    setState(() {
      if (name != null && name.isNotEmpty) _loadedUserName = name;
      if (rating != null) _loadedUserRating = rating;
      _loadedUserPhotoUrl = photo;
      _isModerator = isMod;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) return;

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic> || !mounted) return;

      final ratingRaw =
          decoded['rating'] ?? decoded['userRating'] ?? decoded['avaliacao'];
      final photo = decoded['profileImageUrl'] ??
          decoded['profileImage'] ??
          decoded['photoUrl'];

      final roles = decoded['roles'];
      final isMod = roles is List && roles.contains('ROLE_MODERATOR');

      final name = (decoded['name'] ?? 'Usuário').toString().trim();
      final resolvedName = name.isEmpty ? 'Usuário' : name;
      double resolvedRating = 0.0;
      if (ratingRaw is num) {
        resolvedRating = ratingRaw.toDouble();
      } else if (ratingRaw is String) {
        resolvedRating = double.tryParse(ratingRaw) ?? 0.0;
      }
      final resolvedPhoto = photo?.toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kName, resolvedName);
      await prefs.setDouble(_kRating, resolvedRating);
      if (resolvedPhoto != null) {
        await prefs.setString(_kPhoto, resolvedPhoto);
      } else {
        await prefs.remove(_kPhoto);
      }
      await prefs.setBool(_kIsMod, isMod);

      if (!mounted) return;
      setState(() {
        _loadedUserName = resolvedName;
        _loadedUserRating = resolvedRating;
        _loadedUserPhotoUrl = resolvedPhoto;
        _isModerator = isMod;
      });
    } catch (_) {
      // Mantem os dados de fallback sem quebrar o menu.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.amareloUmPoucoEscuro,
      child: SafeArea(
        top: true,
        bottom: false,
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
                        title: 'Página Inicial',
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.main,
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: 'assets/img/PlusWhite.png',
                        title: 'Crie um pedido',
                        onTap: () async {
                          final canContinue =
                              await PendingServiceCancellationObligations
                                  .ensureCanContinue(
                            context,
                            actionLabel: 'criar pedido',
                          );
                          if (!canContinue || !context.mounted) {
                            return;
                          }

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
                        onTap: widget.onWalletPressed,
                      ),
                      _buildMenuItem(
                        icon: 'assets/img/NotificationsWhite.png',
                        title: 'Notificações',
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
                    if (_isModerator)
                      _buildMenuItem(
                        icon: 'assets/img/SettingsWhite.png',
                        title: 'Painel',
                        onTap: () {
                          Navigator.pushNamed(
                              context, AppRoutes.moderatorPanel);
                        },
                      ),
                    _buildMenuItem(
                      icon: 'assets/img/SettingsWhite.png',
                      title: 'Configurações',
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
      ),
    );
  }

  Widget _buildUserHeader() {
    final photoUrl = _displayUserPhotoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? const Icon(Icons.person, size: 30, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayUserName,
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
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: AppColors.branco,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayUserRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Sua avaliação',
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
      ),
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

    // Limpar preferência "lembrar de mim"
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}

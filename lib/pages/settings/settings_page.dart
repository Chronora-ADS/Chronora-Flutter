import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/theme_service.dart';
import '../../widgets/animated_side_menu_overlay.dart';
import '../../widgets/backgrounds/background_default_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/wallet_modal.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  void _toggleDrawer() => setState(() => _isDrawerOpen = !_isDrawerOpen);
  void _openWallet() => setState(() {
        _isDrawerOpen = false;
        _isWalletOpen = true;
      });
  void _closeWallet() => setState(() => _isWalletOpen = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSideMenuOverlay(
            isOpen: _isDrawerOpen,
            onClose: _toggleDrawer,
            onWalletPressed: _openWallet,
            top: 0,
          ),
          if (_isWalletOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WalletModal(onClose: _closeWallet),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Aparência'),
        const SizedBox(height: 8),
        _buildAppearanceCard(),
        const SizedBox(height: 20),
        _buildSectionTitle('Sobre'),
        const SizedBox(height: 8),
        _buildAboutCard(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.amareloUmPoucoEscuro,
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.notifier,
        builder: (context, themeMode, _) {
          final isDark = themeMode == ThemeMode.dark;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tema escuro',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.preto,
              ),
            ),
            subtitle: Text(
              isDark ? 'Ativado' : 'Desativado',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.cinza,
              ),
            ),
            value: isDark,
            activeThumbColor: AppColors.amareloUmPoucoEscuro,
            onChanged: (_) => ThemeService.toggle(),
          );
        },
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildAboutItem(
            title: 'Versão',
            trailing: const Text(
              '1.0.0',
              style: TextStyle(color: AppColors.cinza, fontSize: 14),
            ),
          ),
          _buildDivider(),
          _buildAboutItem(
            title: 'Política de Privacidade',
            onTap: () => _showTextDialog(
              'Política de Privacidade',
              'O Chronora coleta dados pessoais exclusivamente para o funcionamento da plataforma, '
                  'como nome, e-mail e informações de pedidos. Esses dados não são compartilhados '
                  'com terceiros sem consentimento. O usuário pode solicitar a exclusão de sua conta '
                  'e dados a qualquer momento pelo aplicativo.',
            ),
          ),
          _buildDivider(),
          _buildAboutItem(
            title: 'Termos de Uso',
            onTap: () => _showTextDialog(
              'Termos de Uso',
              'Ao utilizar o Chronora, você concorda em usar a plataforma de forma responsável e '
                  'dentro da lei. É proibido criar pedidos fraudulentos, usar o sistema para fins '
                  'ilegais ou prejudicar outros usuários. O Chronora reserva o direito de suspender '
                  'contas que violem estas regras.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem({
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.preto,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.cinza)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Color(0xFFEEEEEE),
    );
  }

  void _showTextDialog(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28, color: AppColors.preto),
                ),
              ],
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.preto,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/constants/app_routes.dart';
import '../core/constants/app_colors.dart';
import '../widgets/header.dart';

class SideMenu extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Drawer(
			width: MediaQuery.of(context).size.width * 0.6,
			child: Container(
				color: AppColors.branco,
				child: ListView(
					padding: EdgeInsets.zero,
					children: [
						// Header do Menu
						Header(),

						// Seção principal do menu
						_buildMenuSection(
							title: '',
							children: [
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/HomeWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Página Inicial',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para meus pedidos
									},
								),
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/PlusWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Crie um pedido',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para carteira
									},
								),
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/SuitcaseWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Meus pedidos',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para notificações
									},
								),
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/CoinWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Carteira',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para notificações
									},
								),
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/NotificationsWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Notificações',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para notificações
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
									icon: Image.asset(
										'assets/img/UserIconWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Perfil',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para configurações
									},
								),
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/SettingsWhite.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
									title: 'Configurações',
									onTap: () {
										Navigator.pop(context); // Fecha o drawer
										// Navegar para configurações
									},
								),
								_buildMenuItem(
									icon: Image.asset(
										'assets/img/Logout.png', // Substitua pelo caminho correto
										width: 24,
										height: 24,
										color: AppColors.branco,
									),
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
							color: AppColors.branco,
						),
					),
				),
				...children,
			],
		);
	}

	Widget _buildMenuItem({
		required Widget icon, // <-- Alterado de IconData para Widget
		required String title,
		required VoidCallback onTap,
	}) {
		return ListTile(
			leading: icon, // <-- O widget de ícone é passado diretamente
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
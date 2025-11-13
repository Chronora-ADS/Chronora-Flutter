import 'dart:convert';
import 'package:chronora/core/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../widgets/backgrounds/background_default_widget.dart';
import '../widgets/header.dart';
import '../widgets/service_card.dart';
import '../widgets/filters_modal.dart';
import '../widgets/side_menu.dart';

class MainPage extends StatefulWidget {
	const MainPage({super.key});

	@override
	State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
	final TextEditingController _searchController = TextEditingController();
	
	List<Service> services = [];
	bool isLoading = true;
	String errorMessage = '';
	int coinCount = 123; // Movido para state para poder atualizar

	// Variáveis de estado para os filtros
	double tempoValue = 5.0;
	String avaliacaoValue = "0";
	String ordenacaoValue = "0";

	@override
	void initState() {
		super.initState();
		_fetchServices();
		_loadCoinCount(); // Carregar contagem de moedas se necessário
	}

	Future<void> _fetchServices() async {
		try {
		final String? token = await _getToken();

		if (token == null) {
			setState(() {
			isLoading = false;
			errorMessage = "Você precisa estar logado para visualizar os serviços.";
			});
			return;
		}

		final response = await ApiService.get('/service/get/all', token: token);

		if (response.statusCode == 200) {
			final List<dynamic> data = json.decode(response.body);
			setState(() {
			services = data.map((item) => Service.fromJson(item)).toList();
			isLoading = false;
			});
		} else {
			setState(() {
			isLoading = false;
			errorMessage = "Erro ao carregar os serviços.";
			});
		}
		} catch (error) {
		setState(() {
			isLoading = false;
			errorMessage = "Falha ao carregar os serviços.";
		});
		}
	}

	Future<void> _loadCoinCount() async {
		// Aqui você pode carregar a contagem real de moedas do usuário
		// Por enquanto mantemos o valor estático
	}

	Future<String?> _getToken() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getString('auth_token');
	}

	void _showFiltersModal() {
		showModalBottomSheet(
		context: context,
		isScrollControlled: true,
		backgroundColor: Colors.transparent,
		builder: (context) => FiltersModal(
			onApplyFilters: _fetchServices,
			initialTempoValue: tempoValue,
			initialAvaliacaoValue: avaliacaoValue,
			initialOrdenacaoValue: ordenacaoValue,
		),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF0B0C0C),
			appBar: Header(
				coinCount: coinCount,
			),
			drawer: const SideMenu(),
			body: Builder(
				builder: (BuildContext context) {
					return BackgroundDefaultWidget(
						child: LayoutBuilder(
							builder: (context, constraints) {
								return SingleChildScrollView(
								padding: const EdgeInsets.all(16),
									child: ConstrainedBox(
										constraints: BoxConstraints(
										minHeight: constraints.maxHeight,
										),
										child: Column(
											children: [
												// Search Bar
												Container(
													margin: const EdgeInsets.only(bottom: 16),
													child: TextField(
														controller: _searchController,
														decoration: InputDecoration(
															hintText: 'Pintura de parede, aula de inglês...',
															hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
															filled: true,
															fillColor: AppColors.branco,
															border: OutlineInputBorder(
																borderRadius: BorderRadius.circular(20),
																borderSide: BorderSide.none,
															),
															contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
															prefixIcon: const Icon(Icons.search, color: AppColors.textoPlaceholder),
														),
													),
												),

												// Make Request Section SEM container com fundo
												Column(
													children: [
														const Text(
															'As horas acumuladas no seu banco representam oportunidades reais de ação.',
															style: TextStyle(
																color: AppColors.branco,
																fontSize: 16,
															),
															textAlign: TextAlign.center,
														),
														const SizedBox(height: 16),
														
														// Botão com logo Plus
														ElevatedButton(
															onPressed: () {
																Navigator.pushNamed(context, '/service-creation');
															},
															style: ElevatedButton.styleFrom(
																backgroundColor: AppColors.branco,
																foregroundColor: AppColors.preto,
																padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
															),
															child: Row(
																mainAxisSize: MainAxisSize.min,
																children: [
																	const Text(
																		'Crie um pedido',
																		style: TextStyle(
																		fontSize: 16,
																		fontWeight: FontWeight.bold,
																		),
																	),
																	const SizedBox(width: 8),
																	Image.asset(
																		'assets/img/Plus.png',
																		width: 20,
																		height: 20,
																	),
																],
															),
														),
														const SizedBox(height: 8),
															const Text(
															'ou realize o de alguém',
															style: TextStyle(
																color: AppColors.branco,
																fontSize: 14,
															),
														),
													],
												),

												// Duas linhas brancas abaixo da seção
												const SizedBox(height: 24),
												Container(
													width: double.infinity,
													height: 1,
													color: AppColors.branco.withOpacity(0.3),
												),
												const SizedBox(height: 8),
												Container(
													width: double.infinity,
													height: 1,
													color: AppColors.branco.withOpacity(0.3),
												),
												const SizedBox(height: 24),

												// Filtros Button - CENTRALIZADO e do mesmo tamanho
												SizedBox(
													width: double.infinity,
													child: ElevatedButton.icon(
														onPressed: _showFiltersModal,
														style: ElevatedButton.styleFrom(
															backgroundColor: AppColors.branco,
															foregroundColor: AppColors.preto,
															padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
															shape: RoundedRectangleBorder(
																borderRadius: BorderRadius.circular(12),
															),
														),
														icon: const Icon(Icons.filter_list, size: 20),
														label: const Text(
														'Filtros',
														style: TextStyle(
															fontSize: 16,
															fontWeight: FontWeight.bold,
														),
														),
													),
												),

												const SizedBox(height: 24),

												// Services List
												Expanded(
												child: _buildServicesList(),
												),
											],
										),
									),
								);
							},
						),
					);
				},
			),
		);
	}

	Widget _buildServicesList() {
		if (isLoading) {
			return const Padding(
				padding: EdgeInsets.symmetric(vertical: 40),
				child: Center(
					child: CircularProgressIndicator(
						valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
					),
				),
			);
		}

		if (errorMessage.isNotEmpty) {
			return Padding(
				padding: const EdgeInsets.symmetric(vertical: 40),
				child: Center(
					child: Text(
						errorMessage,
						style: const TextStyle(
							color: AppColors.branco,
							fontSize: 16,
						),
						textAlign: TextAlign.center,
					),
				),
			);
		}

		if (services.isEmpty) {
			return const Padding(
				padding: EdgeInsets.symmetric(vertical: 40),
				child: Center(
					child: Text(
						'Nenhum serviço encontrado.',
						style: TextStyle(
							color: AppColors.branco,
							fontSize: 16,
						),
					),
				),
			);
		}

		return ListView.builder(
			shrinkWrap: true,
			physics: const NeverScrollableScrollPhysics(),
			itemCount: services.length,
			itemBuilder: (context, index) {
				return Container(
					margin: const EdgeInsets.only(bottom: 16),
					child: ServiceCard(service: services[index]),
				);
			},
		);
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}
}
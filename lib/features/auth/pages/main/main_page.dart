import 'package:flutter/material.dart';
import 'main_page_controller.dart';
import 'main_page_style.dart';
import '../../shared/widgets/background_default_widget.dart';
import '../auth/widgets/service_card.dart';
import '../auth/widgets/filters_modal.dart';
import '../auth/widgets/side_menu.dart';

class MainPage extends StatefulWidget {
	const MainPage({super.key});

	@override
	State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
	final controller = MainPageController();

	@override
	void initState() {
		super.initState();
		controller.carregarServicos().then((_) => setState(() {}));
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
		backgroundColor: MainPageStyle.fundo,
		appBar: AppBar(
			backgroundColor: MainPageStyle.appBarFundo,
			title: const Text('Chronora', style: MainPageStyle.tituloAppBar),
			centerTitle: true,
			leading: IconButton(
				icon: const Icon(Icons.menu, color: AppColors.preto),
				onPressed: () => Scaffold.of(context).openDrawer(),
			),
		),
		drawer: const SideMenu(),
		body: BackgroundWidget(
			child: SingleChildScrollView(
			padding: const EdgeInsets.all(16),
			child: Column(
				children: [
					TextField(decoration: MainPageStyle.searchDecoration()),
					const SizedBox(height: 16),
					_buildSectionCard(),
					const SizedBox(height: 24),
					ElevatedButton.icon(
						onPressed: _abrirFiltros,
						icon: const Icon(Icons.filter_list),
						label: const Text('Filtros'),
					),
					const SizedBox(height: 24),
					_buildListaServicos(),
				],
			),
			),
		),
		);
	}

	Widget _buildSectionCard() {
		return Container(
		width: double.infinity,
		padding: const EdgeInsets.all(20),
		decoration: MainPageStyle.cardSection,
		child: Column(
			children: [
				const Text(
					'As horas acumuladas no seu banco representam oportunidades reais de ação.',
					style: MainPageStyle.textoSection,
					textAlign: TextAlign.center,
				),
				const SizedBox(height: 16),
				ElevatedButton(
					onPressed: () => Navigator.pushNamed(context, '/service-creation'),
					child: const Text('Crie um pedido'),
				),
			],
		),
		);
	}

	Widget _buildListaServicos() {
		if (controller.isLoading) return const CircularProgressIndicator();
		if (controller.errorMessage.isNotEmpty) return Text(controller.errorMessage);
		if (controller.services.isEmpty) return const Text('Nenhum serviço encontrado.');
		return Column(
		children: controller.services
			.map((s) => ServiceCard(service: s))
			.toList(),
		);
	}

	void _abrirFiltros() {
		showModalBottomSheet(
			context: context,
			builder: (_) => FiltersModal(
				onApplyFilters: () async {
				await controller.carregarServicos();
				setState(() {});
				},
			),
		);
	}
}
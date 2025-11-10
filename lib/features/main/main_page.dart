import 'dart:convert';
import 'package:chronora/core/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/background_default_widget.dart';
import '../auth/widgets/service_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<String> categorias = [
    "Pintura",
    "Mecânica",
    "Engenharia",
    "Elétrica"
  ];
  double tempoValue = 5.0;
  String avaliacaoValue = "0";
  String ordenacaoValue = "0";
  String categoriaValue = "";
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  List<Service> services = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final String? token = await _getToken();

      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage =
              "Você precisa estar logado para visualizar os serviços.";
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersModal(),
    );
  }

  Widget _buildFiltersModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.preto,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prazo
                  _buildFilterSection(
                    'Prazo',
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        border:
                            Border.all(color: AppColors.amareloUmPoucoEscuro),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: '30/10/2025',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tipo de serviço
                  _buildFilterSection(
                    'Tipo de serviço',
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.amareloUmPoucoEscuro),
                              backgroundColor:
                                  AppColors.amareloClaro.withOpacity(0.1),
                            ),
                            child: const Text('À distância'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.amareloUmPoucoEscuro),
                            ),
                            child: const Text('Presencial'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avaliação
                  _buildFilterSection(
                    'Avaliação de usuário',
                    DropdownButtonFormField<String>(
                      value: avaliacaoValue,
                      items: const [
                        DropdownMenuItem(
                            value: "0", child: Text("0 - 1 estrelas")),
                        DropdownMenuItem(
                            value: "1", child: Text("1 - 2 estrelas")),
                        DropdownMenuItem(
                            value: "2", child: Text("2 - 3 estrelas")),
                        DropdownMenuItem(
                            value: "3", child: Text("3 - 4 estrelas")),
                        DropdownMenuItem(
                            value: "4", child: Text("4 - 5 estrelas")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          avaliacaoValue = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tempo
                  _buildFilterSection(
                    'Tempo',
                    Column(
                      children: [
                        Slider(
                          value: tempoValue,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          onChanged: (value) {
                            setState(() {
                              tempoValue = value;
                            });
                          },
                          activeColor: AppColors.amareloClaro,
                        ),
                        Text(
                          tempoValue == 5
                              ? "0-5 horas"
                              : "${tempoValue.toInt() - 5}-${tempoValue.toInt()} horas",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Categorias
                  _buildFilterSection(
                    'Categorias',
                    TextField(
                      controller: _categoriaController,
                      decoration: InputDecoration(
                        hintText: 'Digite ou escolha',
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ordenação
                  _buildFilterSection(
                    'Ordenação',
                    DropdownButtonFormField<String>(
                      value: ordenacaoValue,
                      items: const [
                        DropdownMenuItem(
                            value: "0", child: Text("Mais recentes")),
                        DropdownMenuItem(
                            value: "1", child: Text("Mais antigos")),
                        DropdownMenuItem(
                            value: "2", child: Text("Melhores avaliados")),
                        DropdownMenuItem(
                            value: "3", child: Text("Maior tempo")),
                        DropdownMenuItem(
                            value: "4", child: Text("Menor tempo")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ordenacaoValue = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botão aplicar filtros
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchServices(); // Re-carrega serviços com filtros
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Aplicar Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      appBar: AppBar(
        backgroundColor: AppColors.amareloClaro,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.preto),
          onPressed: () {
            // Abrir drawer do menu
            Scaffold.of(context).openDrawer();
          },
        ),
        title: SizedBox(
          height: 40,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textoPlaceholder),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/service-creation');
            },
            icon: Image.asset('assets/img/Plus.png', width: 24),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // Navegar para carteira
                },
                icon: Image.asset('assets/img/Coin.png', width: 24),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.branco,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '123',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Make Request Section
              _buildMakeRequestSection(),

              const SizedBox(height: 24),

              // Filtros Button
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showFiltersModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.branco,
                      foregroundColor: AppColors.preto,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtros'),
                  ),
                  const SizedBox(width: 8),
                  if (_showFilters) ...[
                    Chip(
                      label: const Text('Prazo: 30/10/2025'),
                      onDeleted: () {},
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('À distância'),
                      onDeleted: () {},
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Services List
              _buildServicesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.amareloClaro,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/img/LogoBackgroundYellow.png',
                  width: 60,
                  height: 60,
                ),
                const Text(
                  'Chronora',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.business_center),
            title: const Text('Meus Serviços'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () {
              // Implementar logout
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMakeRequestSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amareloClaro.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amareloClaro),
      ),
      child: Column(
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
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/service-creation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.branco,
              foregroundColor: AppColors.preto,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Crie um pedido'),
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
    );
  }

  Widget _buildServicesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: AppColors.branco),
        ),
      );
    }

    if (services.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum serviço encontrado.',
          style: TextStyle(color: AppColors.branco),
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
}

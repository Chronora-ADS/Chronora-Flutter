import 'dart:convert';

import 'package:chronora/core/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/background_widget.dart';
import '../widgets/service_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<String> categorias = ["Pintura", "Mecânica", "Engenharia", "Elétrica"];
  double tempoValue = 5.0;
  String avaliacaoValue = "0";
  String ordenacaoValue = "0";
  String categoriaValue = "";
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  
  List<Service> services = [];
  bool isLoading = true;
  String errorMessage = '';

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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Column(
        children: [
          // Header Fixo
          _buildHeader(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Make Request Section
                  _buildMakeRequestSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Filters
                  _buildFiltersSection(),
                  
                  const SizedBox(height: 20),
                  
                  // Services Grid
                  _buildServicesGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.amareloClaro,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Image.asset(
                'assets/img/LogoBackgroundYellow.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 8),
              const Text(
                'Chronora',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Search Bar
          Container(
            width: MediaQuery.of(context).size.width * 0.4,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pintura de parede, aula de inglês...',
                hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
                filled: true,
                fillColor: AppColors.branco,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/img/Search.png', width: 20),
                ),
              ),
            ),
          ),
          
          // Navbar Buttons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/service-creation');
                },
                icon: Image.asset('assets/img/Plus.png', width: 24),
              ),
              const SizedBox(width: 8),
              // Chronos
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Image.asset('assets/img/Coin.png', width: 20),
                    const SizedBox(width: 4),
                    const Text(
                      '123',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/img/Briefcase.png', width: 24),
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/img/Profile.png', width: 24),
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/img/Settings.png', width: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMakeRequestSection() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        children: [
          const Text(
            'As horas acumuladas no seu banco representam oportunidades reais de ação.',
            style: TextStyle(
              color: AppColors.branco,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/service-creation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.branco,
              foregroundColor: AppColors.preto,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Faça um pedido',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Image.asset('assets/img/Plus.png', width: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ou realize o de alguém',
            style: TextStyle(
              color: AppColors.branco,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          Image.asset('assets/img/White Lines.png', width: 100),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 20,
            childAspectRatio: 3,
            children: [
              // Avaliação
              _buildFilterItem(
                'Avaliação de usuário',
                DropdownButtonFormField<String>(
                  value: avaliacaoValue,
                  items: const [
                    DropdownMenuItem(value: "0", child: Text("0 - 1 estrelas")),
                    DropdownMenuItem(value: "1", child: Text("1 - 2 estrelas")),
                    DropdownMenuItem(value: "2", child: Text("2 - 3 estrelas")),
                    DropdownMenuItem(value: "3", child: Text("3 - 4 estrelas")),
                    DropdownMenuItem(value: "4", child: Text("4 - 5 estrelas")),
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
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              
              // Tempo Slider
              _buildFilterItem(
                'Tempo',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.branco,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
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
                      Positioned(
                        bottom: 25,
                        left: (tempoValue - 5) / 95 * (MediaQuery.of(context).size.width * 0.7 / 4 - 32),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.preto,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tempoValue == 5 ? "0-5" : "${tempoValue.toInt() - 5}-${tempoValue.toInt()}",
                            style: const TextStyle(
                              color: AppColors.branco,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Categorias
              _buildFilterItem(
                'Categorias',
                TextField(
                  controller: _categoriaController,
                  decoration: InputDecoration(
                    hintText: 'Digite ou escolha',
                    filled: true,
                    fillColor: AppColors.branco,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              
              // Ordenação
              _buildFilterItem(
                'Ordenação',
                DropdownButtonFormField<String>(
                  value: ordenacaoValue,
                  items: const [
                    DropdownMenuItem(value: "0", child: Text("Mais recentes")),
                    DropdownMenuItem(value: "1", child: Text("Mais antigos")),
                    DropdownMenuItem(value: "2", child: Text("Melhores avaliados")),
                    DropdownMenuItem(value: "3", child: Text("Maior tempo")),
                    DropdownMenuItem(value: "4", child: Text("Menor tempo")),
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
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.branco,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildServicesGrid() {
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

    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.7,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return ServiceCard(service: services[index]);
        },
      ),
    );
  }
}
import 'dart:convert';
import 'package:chronora/core/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/background_auth_widget.dart';
import '../auth/widgets/service_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

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
                  const SizedBox(height: 40), // Reduzido de 60
                  
                  // Make Request Section
                  _buildMakeRequestSection(),
                  
                  const SizedBox(height: 30), // Reduzido de 40
                  
                  // Filters
                  _buildFiltersSection(),
                  
                  const SizedBox(height: 16), // Reduzido de 20
                  
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
      height: 60, // Reduzido de 70
      padding: const EdgeInsets.symmetric(horizontal: 16), // Reduzido de 20
      color: AppColors.amareloClaro,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Image.asset(
                'assets/img/LogoBackgroundYellow.png',
                width: 32, // Reduzido de 40
                height: 32, // Reduzido de 40
              ),
              const SizedBox(width: 6), // Reduzido de 8
              const Text(
                'Chronora',
                style: TextStyle(
                  fontSize: 20, // Reduzido de 24
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Search Bar
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pintura de parede, aula de inglês...',
                hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
                filled: true,
                fillColor: AppColors.branco,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Reduzido de 10
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Vertical reduzido
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6.0), // Reduzido de 8
                  child: Image.asset('assets/img/Search.png', width: 18), // Reduzido de 20
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
                icon: Image.asset('assets/img/Plus.png', width: 22), // Reduzido de 24
                padding: const EdgeInsets.all(6), // Adicionado padding reduzido
              ),
              const SizedBox(width: 6), // Reduzido de 8
              // Chronos
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduzido
                child: Row(
                  children: [
                    Image.asset('assets/img/Coin.png', width: 18), // Reduzido de 20
                    const SizedBox(width: 3), // Reduzido de 4
                    const Text(
                      '123',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Adicionado tamanho menor
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6), // Reduzido de 8
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/img/Briefcase.png', width: 22), // Reduzido de 24
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/img/Profile.png', width: 22), // Reduzido de 24
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                onPressed: () {},
                icon: Image.asset('assets/img/Settings.png', width: 22), // Reduzido de 24
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMakeRequestSection() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        children: [
          const Text(
            'As horas acumuladas no seu banco representam oportunidades reais de ação.',
            style: TextStyle(
              color: AppColors.branco,
              fontSize: 16, // Reduzido de 18
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16), // Reduzido de 20
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/service-creation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.branco,
              foregroundColor: AppColors.preto,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10), // Reduzido
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Reduzido de 20
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Faça um pedido',
                  style: TextStyle(fontSize: 16), // Reduzido de 18
                ),
                const SizedBox(width: 6), // Reduzido de 8
                Image.asset('assets/img/Plus.png', width: 18), // Reduzido de 20
              ],
            ),
          ),
          const SizedBox(height: 16), // Reduzido de 20
          const Text(
            'Ou realize o de alguém',
            style: TextStyle(
              color: AppColors.branco,
              fontSize: 16, // Reduzido de 18
            ),
          ),
          const SizedBox(height: 16), // Reduzido de 20
          Image.asset('assets/img/White Lines.png', width: 80), // Reduzido de 100
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16, // Reduzido de 20
            childAspectRatio: 3.2, // Ajustado para compensar altura reduzida
            children: [
              // Avaliação
              _buildFilterItem(
                'Avaliação de usuário',
                DropdownButtonFormField<String>(
                  initialValue: avaliacaoValue,
                  items: const [
                    DropdownMenuItem(value: "0", child: Text("0 - 1 estrelas", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "1", child: Text("1 - 2 estrelas", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "2", child: Text("2 - 3 estrelas", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "3", child: Text("3 - 4 estrelas", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "4", child: Text("4 - 5 estrelas", style: TextStyle(fontSize: 12))),
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
                      borderRadius: BorderRadius.circular(12), // Reduzido de 20
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduzido
                  ),
                  style: const TextStyle(fontSize: 12), // Fonte menor
                ),
              ),
              
              // Tempo Slider
              _buildFilterItem(
                'Tempo',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12), // Reduzido
                  decoration: BoxDecoration(
                    color: AppColors.branco,
                    borderRadius: BorderRadius.circular(12), // Reduzido de 20
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
                        bottom: 20, // Ajustado
                        left: (tempoValue - 5) / 95 * (MediaQuery.of(context).size.width * 0.7 / 4 - 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduzido
                          decoration: BoxDecoration(
                            color: AppColors.preto,
                            borderRadius: BorderRadius.circular(3), // Reduzido
                          ),
                          child: Text(
                            tempoValue == 5 ? "0-5" : "${tempoValue.toInt() - 5}-${tempoValue.toInt()}",
                            style: const TextStyle(
                              color: AppColors.branco,
                              fontSize: 10, // Reduzido
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
                    hintStyle: const TextStyle(fontSize: 12), // Fonte menor
                    filled: true,
                    fillColor: AppColors.branco,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Reduzido de 20
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduzido
                  ),
                  style: const TextStyle(fontSize: 12), // Fonte menor
                ),
              ),
              
              // Ordenação
              _buildFilterItem(
                'Ordenação',
                DropdownButtonFormField<String>(
                  initialValue: ordenacaoValue,
                  items: const [
                    DropdownMenuItem(value: "0", child: Text("Mais recentes", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "1", child: Text("Mais antigos", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "2", child: Text("Melhores avaliados", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "3", child: Text("Maior tempo", style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: "4", child: Text("Menor tempo", style: TextStyle(fontSize: 12))),
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
                      borderRadius: BorderRadius.circular(12), // Reduzido de 20
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduzido
                  ),
                  style: const TextStyle(fontSize: 12), // Fonte menor
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
            fontSize: 14, // Reduzido de 16
          ),
        ),
        const SizedBox(height: 6), // Reduzido de 8
        Expanded(child: child),
      ],
    );
  }

  Widget _buildServicesGrid() {
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
            style: const TextStyle(color: AppColors.branco),
          ),
        ),
      );
    }

    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Nenhum serviço encontrado.',
            style: const TextStyle(color: AppColors.branco),
          ),
        ),
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16, // Reduzido de 20
          mainAxisSpacing: 16, // Reduzido de 20
          childAspectRatio: 0.65, // Ajustado para cards mais compactos
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return ServiceCard(service: services[index]);
        },
      ),
    );
  }
}
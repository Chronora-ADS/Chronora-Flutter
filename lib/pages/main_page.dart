import 'dart:convert';
import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../widgets/backgrounds/background_default_widget.dart';
import '../widgets/header.dart';
import '../widgets/service_card.dart';
import '../widgets/filters_modal.dart';
import '../widgets/side_menu.dart';
import '../widgets/wallet_modal.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  List<Service> services = [];
  List<Service> filteredServices = [];
  bool isLoading = true;
  String errorMessage = '';

  double tempoValue = 5.0;
  String avaliacaoValue = "0";
  String ordenacaoValue = "0";
  List<String> selectedCategories = [];
  String selectedTipoServico = "";

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
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
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('services')) {
            data = responseData['services'] as List<dynamic>;
          } else if (responseData.containsKey('data')) {
            data = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('content')) {
            data = responseData['content'] as List<dynamic>;
          } else {
            print('Estrutura inesperada: $responseData');
          }
        } else if (responseData is List<dynamic>) {
          data = responseData;
        }

        setState(() {
          services = data.map((item) => Service.fromJson(item)).toList();
          // Atualiza a lista filtrada também
          filteredServices = services;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Erro ${response.statusCode} ao carregar os serviços.";
        });
      }
    } catch (error) {
      print('Erro na requisição: $error');
      setState(() {
        isLoading = false;
        errorMessage = "Falha ao carregar os serviços: $error";
      });
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      filteredServices = services.where((service) {
        // Filtra pelo título
        final titleMatch = service.title.toLowerCase().contains(query);
        // Filtra pela descrição
        final descriptionMatch = service.description.toLowerCase().contains(query);
        // Filtra pela modalidade
        final modalityMatch = service.modality.toLowerCase().contains(query);
        // Filtra pelas categorias
        final categoryMatch = service.categoryEntities.any((category) =>
          category.name.toLowerCase().contains(query));

        // Verifica se o serviço corresponde à pesquisa textual
        bool matchesSearch = query.isEmpty || titleMatch || descriptionMatch || modalityMatch || categoryMatch;

        // Verifica se o serviço tem as categorias selecionadas (se houver categorias selecionadas)
        bool matchesCategories = selectedCategories.isEmpty ||
          selectedCategories.every((selectedCategory) =>
            service.categoryEntities.any((category) =>
              category.name.toLowerCase().contains(selectedCategory.toLowerCase())));

        // Verifica se o serviço corresponde ao tipo de serviço selecionado
        bool matchesTipoServico = selectedTipoServico.isEmpty ||
          // Se o filtro for 'À distância', verifica se a modalidade é 'Remoto'
          (selectedTipoServico == 'À distância' && service.modality.toLowerCase().contains('remoto')) ||
          // Se o filtro for 'Presencial', verifica se a modalidade é 'Presencial'
          (selectedTipoServico == 'Presencial' && service.modality.toLowerCase().contains('presencial'));

        // Verifica se o serviço corresponde ao filtro de tempo em chronos
        bool matchesTempo = true; // Por padrão, não filtra por tempo se o valor for 5 (slider no mínimo)
        if (tempoValue > 5) {
          int tempoMax = tempoValue.toInt();
          int tempoMin = tempoMax - 5;
          matchesTempo = service.timeChronos >= tempoMin && service.timeChronos <= tempoMax;
        }

        return matchesSearch && matchesCategories && matchesTipoServico && matchesTempo;
      }).toList();
    });
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersModal(
        onApplyFilters: (selectedCategoriesList, selectedTipoServicoString, tempoValueParam) {
          setState(() {
            selectedCategories = selectedCategoriesList;
            selectedTipoServico = selectedTipoServicoString;
            tempoValue = tempoValueParam; // Atualiza o valor do tempo
          });
          _filterServices();
        },
        initialTempoValue: tempoValue,
        initialAvaliacaoValue: avaliacaoValue,
        initialOrdenacaoValue: ordenacaoValue,
        initialSelectedCategories: selectedCategories,
        initialSelectedTipoServico: selectedTipoServico,
      ),
    );
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _openWallet() {
    setState(() {
      _isDrawerOpen = false; // Fecha o side menu
      _isWalletOpen = true; // Abre a carteira
    });
  }

  void _closeWallet() {
    setState(() {
      _isWalletOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      body: Stack(
        children: [
          // Conteúdo principal
          Column(
            children: [
              Header(
                onMenuPressed: _toggleDrawer,
              ),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _filterServices(),
                            decoration: InputDecoration(
                              hintText: 'Pintura de parede, aula de inglês...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textoPlaceholder),
                              filled: true,
                              fillColor: AppColors.branco,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.textoPlaceholder),
                            ),
                          ),
                        ),

                        // Make Request Section
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
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/request-creation'
                                );

                                // Se retornou true, atualiza os serviços
                                if (result == true) {
                                  await _fetchServices();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.branco,
                                foregroundColor: AppColors.preto,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
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

                        const SizedBox(height: 24),
                        Align(
                            alignment: Alignment.center,
                            child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 3,
                                color: AppColors.branco,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                            alignment: Alignment.center,
                            child: Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 3,
                                color: AppColors.branco,
                            ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showFiltersModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.branco,
                              foregroundColor: AppColors.preto,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
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

                        _buildServicesList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Menu lateral
          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: SideMenu(
                        onWalletPressed: _openWallet, // Usa a nova função
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleDrawer,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Modal da Carteira
          if (_isWalletOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WalletModal(
                      onClose: _closeWallet, // Usa a nova função
                    ),
                  ),
                ),
              ),
            ),
        ],
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

    // Usar a lista filtrada em vez da lista completa
    if (filteredServices.isEmpty) {
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
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: filteredServices[index],
            onEdit: () async {
              // Navega para a página de edição com o serviço
              final result = await Navigator.pushNamed(
                context,
                '/request-editing',
                arguments: filteredServices[index],
              );

              // Se retornou true, atualiza os serviços
              if (result == true) {
                await _fetchServices();
              }
            },
            onCardEdited: (edited) async {
              // Quando o card é editado pelo clique direto
              if (edited) {
                await _fetchServices();
              }
            },
          ),
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
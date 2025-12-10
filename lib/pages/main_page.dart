import 'dart:convert';
import 'package:chronora/core/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../widgets/backgrounds/background_default_widget.dart';
import '../widgets/header.dart';
import '../widgets/filters_modal.dart';
import '../widgets/side_menu.dart';
import '../widgets/wallet_modal.dart';
import '../widgets/service_card.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_filterServices);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchServices() async {
    try {
      final String? token = await _getToken();

      if (token == null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage =
              "Você precisa estar logado para visualizar os serviços.";
        });
        return;
      }

      final response =
          await ApiService.get('/service/get/all', token: token);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('services')) {
            data = responseData['services'];
          } else if (responseData.containsKey('data')) {
            data = responseData['data'];
          } else if (responseData.containsKey('content')) {
            data = responseData['content'];
          }
        } else if (responseData is List<dynamic>) {
          data = responseData;
        }

        if (!mounted) return;
        setState(() {
          services = data.map((item) => Service.fromJson(item)).toList();
          filteredServices = services;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage =
              "Erro ${response.statusCode} ao carregar os serviços.";
        });
      }
    } catch (error) {
      debugPrint('Erro na requisição: $error');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Falha ao carregar os serviços: $error";
      });
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredServices = services.where((service) {
        return service.title.toLowerCase().contains(query) ||
            service.userCreator.name.toLowerCase().contains(query) ||
            service.categoryEntities.any((category) =>
                category.name.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersModal(
        onApplyFilters: () {
          // Aplicar filtros (implementar lógica de filtragem)
          _applyFilters();
        },
        initialTempoValue: tempoValue,
        initialAvaliacaoValue: avaliacaoValue,
        initialOrdenacaoValue: ordenacaoValue,
      ),
    );
  }

  void _applyFilters() {
    // Implementar lógica de filtragem baseada nos valores dos filtros
    // Por enquanto, apenas recarrega os serviços
    _fetchServices();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _openWallet() {
    setState(() {
      _isDrawerOpen = false;
      _isWalletOpen = true;
    });
  }

  void _closeWallet() {
    setState(() {
      _isWalletOpen = false;
    });
  }

  // Método para converter Service para formato de pedido
  Map<String, dynamic> _convertServiceToPedido(Service service) {
    return {
      'titulo': service.title,
      'descricao_breve': 'Descrição do serviço ${service.title}',
      'descricao_completa': 'Descrição completa do serviço ${service.title}. Uma descrição muito longa de Lorem ipsum dolor sit amet. Vivamus dolor dolor, bibendum a conque eu, fringilla et sem. Phasellus non sem. Maceenasante turpis, finibus vel odio eget, cursus sagittis dui. Cras eu tristique nibh. Sed lacinia, nibh at convallis pellentesque, tortor ipsum imperdiet nisi, a placerat arcu nulla ut diam. Phasellus aliquam nisi sit amet sollicitudin ultricies. Suspendisse venenatis pulvinar ligula vel hendrerit. Suspendisse in cursus metus. Maceenas non convallis turpis, id varius lorem. Fusce in odio at urna ultrices placerat id at mi. Etiam tempor non elit vel convallis.',
      'tempo_chronos': service.timeChronos,
      'prazo': '30/10/2025', // Data padrão ou da API
      'modalidade': 'Presencial', // Definir com base nos dados do serviço
      'categoria_principal': service.categoryEntities.isNotEmpty 
          ? service.categoryEntities.first.name 
          : 'Geral',
      'subcategoria': service.categoryEntities.length > 1 
          ? service.categoryEntities[1].name 
          : service.categoryEntities.first.name,
      'postador': service.userCreator.name,
      'horario': '15:41', // Horário do post
      'status': 'Disponível',
      'avaliacao': '4.9',
      'serviceImage': service.serviceImage,
      'temAcompanhamento': true, // Dados de exemplo
      'temMotivacao': true, // Dados de exemplo
      'categorias': service.categoryEntities.map((cat) => cat.name).toList(),
    };
  }

  // Verifica se o usuário atual é o criador do serviço
  bool _isUserOwnerOfService(Service service) {
    // Em uma implementação real, você compararia o ID do usuário logado
    // com o ID do criador do serviço (service.userCreator.id)
    // Por enquanto, retornamos false para todos os serviços
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0C0C),
        body: Stack(
          children: [
            Column(
              children: [
                Header(
                  onMenuPressed: _toggleDrawer,
                ),
                Expanded(
                  child: BackgroundDefaultWidget(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Pintura de parede, aula de inglês...',
                                filled: true,
                                fillColor: AppColors.branco,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Botão de Filtros
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ElevatedButton.icon(
                              onPressed: _showFiltersModal,
                              icon: const Icon(Icons.filter_list, 
                                  color: AppColors.amareloUmPoucoEscuro),
                              label: Text(
                                'Filtros',
                                style: TextStyle(
                                  color: AppColors.amareloUmPoucoEscuro,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.branco,
                                foregroundColor: AppColors.amareloUmPoucoEscuro,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: AppColors.amareloUmPoucoEscuro,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          _buildServicesList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isDrawerOpen)
              Positioned(
                top: kToolbarHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.6,
                        child: SideMenu(
                          onWalletPressed: _openWallet,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleDrawer,
                          child:
                              const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isWalletOpen)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: WalletModal(
                      onClose: _closeWallet,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (filteredServices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _searchController.text.isEmpty
                ? 'Nenhum pedido encontrado.'
                : 'Nenhum pedido encontrado para "${_searchController.text}".',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        final isOwner = _isUserOwnerOfService(service);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: service,
            onTap: () {
              // Navegar para a tela de ver pedido com os dados do serviço
              Navigator.pushNamed(
                context,
                '/view-request',
                arguments: {
                  'pedido': _convertServiceToPedido(service),
                  'ehProprietario': isOwner,
                },
              );
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
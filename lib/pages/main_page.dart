import 'dart:convert';

import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/services/api_service.dart';
import '../widgets/backgrounds/background_default_widget.dart';
import '../widgets/filters_modal.dart';
import '../widgets/header.dart';
import '../widgets/service_card.dart';
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

  double tempoValue = 0.0;
  bool _isTimeFilterActive = false;
  String avaliacaoValue = '0';
  String ordenacaoValue = '0';
  List<String> selectedCategories = [];
  String selectedTipoServico = '';
  int _prazoDias = 0;
  DateTime? _selectedPrazoDate;

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
          errorMessage = 'Você precisa estar logado para visualizar os serviços.';
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
            debugPrint('Estrutura inesperada: $responseData');
          }
        } else if (responseData is List<dynamic>) {
          data = responseData;
        }

        setState(() {
          services = data
              .map((item) => Service.fromJson(item))
              .where((service) => service.status.toUpperCase() == 'CRIADO')
              .toList();
          filteredServices = List<Service>.from(services);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Erro ${response.statusCode} ao carregar os serviços.';
        });
      }
    } catch (error) {
      debugPrint('Erro na requisição: $error');
      setState(() {
        isLoading = false;
        errorMessage = 'Falha ao carregar os serviços: $error';
      });
    }
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      filteredServices = services.where((service) {
        final titleMatch = service.title.toLowerCase().contains(query);
        final descriptionMatch =
            service.description.toLowerCase().contains(query);
        final modalityMatch = service.modality.toLowerCase().contains(query);
        final categoryMatch = service.categoryEntities.any(
          (category) => category.name.toLowerCase().contains(query),
        );

        final matchesSearch = query.isEmpty ||
            titleMatch ||
            descriptionMatch ||
            modalityMatch ||
            categoryMatch;

        final matchesCategories = selectedCategories.isEmpty ||
            service.categoryEntities.any(
              (category) => selectedCategories.any(
                (selectedCategory) => category.name
                    .toLowerCase()
                    .contains(selectedCategory.toLowerCase()),
              ),
            );

        final matchesTipoServico = selectedTipoServico.isEmpty ||
            (selectedTipoServico == 'À distância' &&
                service.modality.toLowerCase().contains('remoto')) ||
            (selectedTipoServico == 'Presencial' &&
                service.modality.toLowerCase().contains('presencial'));

        var matchesTempo = true;
        if (_isTimeFilterActive && tempoValue > 0) {
          final tempoMax = tempoValue.toInt();
          final tempoMin = tempoValue == 5 ? 0 : tempoMax - 5;
          matchesTempo = service.timeChronos >= tempoMin &&
              service.timeChronos <= tempoMax;
        }

        var matchesPrazo = true;
        if (_selectedPrazoDate != null) {
          final hoje = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          final prazoLimite = DateTime(
            _selectedPrazoDate!.year,
            _selectedPrazoDate!.month,
            _selectedPrazoDate!.day,
          );

          matchesPrazo =
              (service.deadline.isAtSameMomentAs(hoje) ||
                  service.deadline.isAfter(hoje)) &&
              (service.deadline.isBefore(prazoLimite) ||
                  service.deadline.isAtSameMomentAs(prazoLimite));
        }

        return matchesSearch &&
            matchesCategories &&
            matchesTipoServico &&
            matchesTempo &&
            matchesPrazo;
      }).toList();

      switch (ordenacaoValue) {
        case '0':
          filteredServices.sort((a, b) => b.id.compareTo(a.id));
          break;
        case '1':
          filteredServices.sort((a, b) => a.id.compareTo(b.id));
          break;
        case '2':
          filteredServices.sort((a, b) => b.id.compareTo(a.id));
          break;
        case '3':
          filteredServices.sort((a, b) => b.timeChronos.compareTo(a.timeChronos));
          break;
        case '4':
          filteredServices.sort((a, b) => a.timeChronos.compareTo(b.timeChronos));
          break;
        default:
          break;
      }
    });
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersModal(
        onApplyFilters: (
          selectedCategoriesList,
          selectedTipoServicoString,
          tempoValueParam,
          ordenacaoValueParam,
          prazoDias,
          selectedPrazoDate,
        ) {
          setState(() {
            selectedCategories = selectedCategoriesList;
            selectedTipoServico = selectedTipoServicoString;
            tempoValue = tempoValueParam;
            ordenacaoValue = ordenacaoValueParam;
            _isTimeFilterActive = true;
            _prazoDias = prazoDias;
            _selectedPrazoDate = selectedPrazoDate;
          });
          _filterServices();
        },
        onClearFilters: _clearFilters,
        initialTempoValue: tempoValue,
        initialAvaliacaoValue: avaliacaoValue,
        initialOrdenacaoValue: ordenacaoValue,
        initialSelectedCategories: selectedCategories,
        initialSelectedTipoServico: selectedTipoServico,
        initialPrazoDias: _prazoDias,
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
      _isDrawerOpen = false;
      _isWalletOpen = true;
    });
  }

  void _clearFilters() {
    setState(() {
      tempoValue = 0.0;
      _isTimeFilterActive = false;
      avaliacaoValue = '0';
      ordenacaoValue = '0';
      selectedCategories = [];
      selectedTipoServico = '';
      _prazoDias = 0;
      _selectedPrazoDate = null;
      _searchController.clear();
    });
    _filterServices();
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
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _filterServices(),
                                decoration: InputDecoration(
                                  hintText:
                                      'Pintura de parede, aula de inglês...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textoPlaceholder,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.branco,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                  final result =
                                      await context.push(AppRoutes.requestCreation);

                                  if (result == true) {
                                    await _fetchServices();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.branco,
                                  foregroundColor: AppColors.preto,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                        ),
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
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showFiltersModal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.branco,
                                  foregroundColor: AppColors.preto,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
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
                          ],
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
          if (_isDrawerOpen)
            Positioned.fill(
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.72,
                    child: SideMenu(onWalletPressed: _openWallet),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggleDrawer,
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isWalletOpen)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
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
        final service = filteredServices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: service,
            onView: () async {
              final result =
                  await context.push(AppRoutes.requestView, extra: service);

              if (result == true) {
                await _fetchServices();
              }
            },
            onCardEdited: (edited) async {
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

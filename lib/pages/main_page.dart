import 'dart:convert';

import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/api/api_service.dart';
import 'package:chronora/core/api/service_catalog_service.dart';
import '../core/constants/app_routes.dart';
import '../core/services/auth_session_service.dart';
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
  final ServiceCatalogService _serviceCatalogService =
      ServiceCatalogService();
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  String _userName = 'Usuário';
  double _userRating = 0.0;
  String? _userPhotoUrl;

  List<Service> services = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _isFetching = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;
  int _nextPage = 0;
  bool _hasMorePages = true;

  double tempoValue = 5.0;
  String avaliacaoValue = "0";
  String ordenacaoValue = "0";

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchServices();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) return;

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || !mounted) return;

      setState(() {
        _userName = (data['name'] ?? 'Usuário').toString();
        final ratingRaw = data['rating'] ?? data['userRating'] ?? data['avaliacao'];
        if (ratingRaw is num) {
          _userRating = ratingRaw.toDouble();
        } else if (ratingRaw is String) {
          _userRating = double.tryParse(ratingRaw) ?? 0.0;
        }

        final photo = data['profileImageUrl'] ?? data['profileImage'] ?? data['photoUrl'];
        _userPhotoUrl = photo?.toString();
      });
    } catch (_) {
      // Mantém fallback visual sem quebrar o fluxo principal da página.
    }
  }

  Future<void> _fetchServices({bool showLoading = false, bool reset = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (reset) {
      _nextPage = 0;
      _hasMorePages = true;
      services = [];
    }

    if ((showLoading || services.isEmpty) && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    } else if (mounted) {
      setState(() {
        _isLoadingMore = true;
        errorMessage = '';
      });
    }

    try {
      final result = await _serviceCatalogService.fetchServices(
        page: _nextPage,
        size: _pageSize,
      );

      if (mounted) {
        final updatedServices = reset || _nextPage == 0
            ? result.services
            : [...services, ...result.services];

        final totalPages = result.totalPages;
        final currentPage = result.page ?? _nextPage;
        final hasMore = totalPages != null
            ? currentPage + 1 < totalPages
            : result.services.length >= _pageSize;

        setState(() {
          services = updatedServices;
          _nextPage = currentPage + 1;
          _hasMorePages = hasMore;
          isLoading = false;
          _isLoadingMore = false;
          errorMessage = '';
        });
      }
    } on ServiceCatalogException catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorMessage = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorMessage = "Falha ao carregar os serviços: $error";
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersModal(
        onApplyFilters: () => _fetchServices(reset: true),
        initialTempoValue: tempoValue,
        initialAvaliacaoValue: avaliacaoValue,
        initialOrdenacaoValue: ordenacaoValue,
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
    final screenWidth = MediaQuery.of(context).size.width;

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
                                  AppRoutes.requestCreation
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
                                width: screenWidth * 0.8,
                                height: 3,
                                color: AppColors.branco,
                            ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                            alignment: Alignment.center,
                            child: Container(
                                width: screenWidth * 0.5,
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
                        const SizedBox(height: 12),
                        _buildLoadMoreButton(),
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
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: screenWidth * 0.6,
                      child: SafeArea(
                        top: true,
                        bottom: false,
                        child: SideMenu(
                          onWalletPressed: _openWallet, // Usa a nova função
                          userName: _userName,
                          userRating: _userRating,
                          userPhotoUrl: _userPhotoUrl,
                        ),
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
          child: ServiceCard(
            service: services[index],
            onView: () async {
              // Navega para a página de edição com o serviço
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.requestViewWithId(services[index].id),
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

  Widget _buildLoadMoreButton() {
    if (isLoading || errorMessage.isNotEmpty || services.isEmpty || !_hasMorePages) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoadingMore ? null : () => _fetchServices(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.branco,
          foregroundColor: AppColors.preto,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isLoadingMore
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Carregar mais',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

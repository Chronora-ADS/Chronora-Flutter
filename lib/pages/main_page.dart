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
import '../widgets/service_card.dart'; // Alterado de card_pedido.dart para service_card.dart

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
        return service.title.toLowerCase().contains(query);
      }).toList();
    });
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
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'Pintura de parede, aula de inglês...',
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon:
                                  const Icon(Icons.search),
                            ),
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: _showFiltersModal,
                            icon:
                                const Icon(Icons.filter_list),
                            label: const Text('Filtros'),
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
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(errorMessage),
      );
    }

    if (filteredServices.isEmpty) {
      return const Center(
        child: Text('Nenhum pedido encontrado.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ServiceCard( // Alterado de CardPedido para ServiceCard
            service: service,
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
import 'dart:convert';

import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/api/service_catalog_service.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/services/auth_session_service.dart';
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
  final ServiceCatalogService _serviceCatalogService =
      ServiceCatalogService();

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  String _userName = 'Usuario';
  double _userRating = 0.0;
  String? _userPhotoUrl;

  List<Service> services = [];
  List<Service> _visibleServices = [];
  bool isLoading = true;
  String errorMessage = '';
  bool _isFetching = false;
  bool _isFetchingAllForFilters = false;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;
  int _nextPage = 0;
  bool _hasMorePages = true;

  ServiceFilters _activeFilters = const ServiceFilters();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _fetchCurrentUser();
    _reloadServices();
  }

  bool get _hasSearchQuery => _searchController.text.trim().isNotEmpty;

  bool get _isFilterMode =>
      _hasSearchQuery ||
      _activeFilters.hasActiveFilters ||
      _activeFilters.hasCustomSort;

  Future<void> _fetchCurrentUser() async {
    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) return;

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || !mounted) return;

      setState(() {
        _userName = (data['name'] ?? 'Usuario').toString();
        final ratingRaw =
            data['rating'] ?? data['userRating'] ?? data['avaliacao'];
        if (ratingRaw is num) {
          _userRating = ratingRaw.toDouble();
        } else if (ratingRaw is String) {
          _userRating = double.tryParse(ratingRaw) ?? 0.0;
        }

        final photo =
            data['profileImageUrl'] ?? data['profileImage'] ?? data['photoUrl'];
        _userPhotoUrl = photo?.toString();
      });
    } catch (_) {
      // Mantem fallback visual sem quebrar a pagina principal.
    }
  }

  Future<void> _reloadServices() async {
    await _fetchServices(showLoading: true, reset: true);
    _scheduleFetchRemainingServicesForFilters();
  }

  Future<void> _fetchServices({
    bool showLoading = false,
    bool reset = false,
  }) async {
    if (_isFetching) return;
    _isFetching = true;

    if (reset) {
      _nextPage = 0;
      _hasMorePages = true;
      services = [];
      _visibleServices = [];
    }

    if (mounted) {
      setState(() {
        if (showLoading || services.isEmpty) {
          isLoading = true;
          _isLoadingMore = false;
        } else {
          _isLoadingMore = true;
        }
        errorMessage = '';
      });
    }

    try {
      final result = await _serviceCatalogService.fetchServices(
        page: _nextPage,
        size: _pageSize,
      );

      final updatedServices = reset || _nextPage == 0
          ? result.services
          : _mergeServices(services, result.services);

      final totalPages = result.totalPages;
      final currentPage = result.page ?? _nextPage;
      final hasMore = totalPages != null
          ? currentPage + 1 < totalPages
          : result.services.length >= _pageSize;

      if (mounted) {
        setState(() {
          services = updatedServices;
          _visibleServices = _applyFiltersToList(updatedServices);
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
          errorMessage = 'Falha ao carregar os servicos: $error';
        });
      }
    } finally {
      _isFetching = false;
      _scheduleFetchRemainingServicesForFilters();
    }
  }

  Future<void> _fetchRemainingServicesForFilters() async {
    if (_isFetching ||
        _isFetchingAllForFilters ||
        !_isFilterMode ||
        !_hasMorePages) {
      return;
    }

    _isFetchingAllForFilters = true;

    if (mounted) {
      setState(() {
        if (services.isEmpty) {
          isLoading = true;
        } else {
          _isLoadingMore = true;
        }
        errorMessage = '';
      });
    }

    var loadedServices = List<Service>.from(services);
    var nextPage = _nextPage;
    var hasMorePages = _hasMorePages;

    try {
      while (hasMorePages) {
        final result = await _serviceCatalogService.fetchServices(
          page: nextPage,
          size: _pageSize,
        );

        loadedServices = _mergeServices(loadedServices, result.services);

        final totalPages = result.totalPages;
        final currentPage = result.page ?? nextPage;
        nextPage = currentPage + 1;
        hasMorePages = totalPages != null
            ? currentPage + 1 < totalPages
            : result.services.length >= _pageSize;
      }

      if (mounted) {
        setState(() {
          services = loadedServices;
          _visibleServices = _applyFiltersToList(loadedServices);
          _nextPage = nextPage;
          _hasMorePages = hasMorePages;
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
          errorMessage =
              'Falha ao carregar os servicos restantes para os filtros: $error';
        });
      }
    } finally {
      _isFetchingAllForFilters = false;
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _scheduleFetchRemainingServicesForFilters() {
    if (!_isFilterMode ||
        !_hasMorePages ||
        _isFetching ||
        _isFetchingAllForFilters) {
      return;
    }

    Future.microtask(() {
      if (mounted) {
        _fetchRemainingServicesForFilters();
      }
    });
  }

  void _handleSearchChanged() {
    if (!mounted) return;

    setState(() {
      _visibleServices = _applyFiltersToList(services);
    });

    _scheduleFetchRemainingServicesForFilters();
  }

  void _handleFiltersApplied(ServiceFilters filters) {
    setState(() {
      _activeFilters = filters;
      _visibleServices = _applyFiltersToList(services);
    });

    _scheduleFetchRemainingServicesForFilters();
  }

  List<Service> _applyFiltersToList(List<Service> source) {
    final normalizedQuery = _normalizeText(_searchController.text);
    final normalizedCategory = _normalizeText(_activeFilters.categoriaText);
    final normalizedModality =
        _normalizeModality(_activeFilters.modalidadeSelecionada ?? '');
    final selectedDeadline = _parseDate(_activeFilters.deadlineText);
    final maxTime = _activeFilters.tempoValue >= ServiceFilters.maxTempoValue
        ? null
        : _activeFilters.tempoValue.toInt();
    final ratingFloor = _activeFilters.avaliacaoValue == ServiceFilters.allRatings
        ? null
        : double.tryParse(_activeFilters.avaliacaoValue);
    final hasRatingData =
        source.any((service) => service.userCreator.rating != null);

    final filtered = source.where((service) {
      if (normalizedQuery.isNotEmpty &&
          !_matchesSearch(service, normalizedQuery)) {
        return false;
      }

      if (selectedDeadline != null &&
          _dateOnly(service.deadline).isAfter(selectedDeadline)) {
        return false;
      }

      if (normalizedCategory.isNotEmpty &&
          !service.categoryEntities.any(
            (category) =>
                _normalizeText(category.name).contains(normalizedCategory),
          )) {
        return false;
      }

      if (normalizedModality.isNotEmpty &&
          _normalizeModality(service.modality) != normalizedModality) {
        return false;
      }

      if (maxTime != null && service.timeChronos > maxTime) {
        return false;
      }

      if (ratingFloor != null && hasRatingData) {
        final rating = service.userCreator.rating;
        if (rating == null || rating < ratingFloor || rating >= ratingFloor + 1) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort(_compareServices);
    return filtered;
  }

  int _compareServices(Service a, Service b) {
    switch (_activeFilters.ordenacaoValue) {
      case ServiceFilters.sortOldest:
        return a.id.compareTo(b.id);
      case ServiceFilters.sortBestRated:
        final ratingComparison =
            _compareNullableDoubleDesc(a.userCreator.rating, b.userCreator.rating);
        if (ratingComparison != 0) return ratingComparison;
        return b.id.compareTo(a.id);
      case ServiceFilters.sortHighestTime:
        final timeComparison = b.timeChronos.compareTo(a.timeChronos);
        if (timeComparison != 0) return timeComparison;
        return b.id.compareTo(a.id);
      case ServiceFilters.sortLowestTime:
        final timeComparison = a.timeChronos.compareTo(b.timeChronos);
        if (timeComparison != 0) return timeComparison;
        return b.id.compareTo(a.id);
      case ServiceFilters.sortMostRecent:
      default:
        return b.id.compareTo(a.id);
    }
  }

  int _compareNullableDoubleDesc(double? left, double? right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  bool _matchesSearch(Service service, String query) {
    final searchableContent = [
      service.title,
      service.description,
      service.userCreator.name,
      service.modality,
      ...service.categoryEntities.map((category) => category.name),
    ].map(_normalizeText).join(' ');

    return searchableContent.contains(query);
  }

  List<Service> _mergeServices(List<Service> current, List<Service> incoming) {
    final mergedById = <int, Service>{};

    for (final service in current) {
      mergedById[service.id] = service;
    }

    for (final service in incoming) {
      mergedById[service.id] = service;
    }

    return mergedById.values.toList();
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .trim();
  }

  String _normalizeModality(String value) {
    final normalized = _normalizeText(value);

    if (normalized.contains('presencial')) return 'presencial';
    if (normalized.contains('remoto')) return 'remoto';
    if (normalized.contains('hibrido')) return 'hibrido';

    return normalized;
  }

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final parts = text.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    final parsedDate = DateTime(year, month, day);
    if (parsedDate.day != day ||
        parsedDate.month != month ||
        parsedDate.year != year) {
      return null;
    }

    return _dateOnly(parsedDate);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersModal(
        onApplyFilters: _handleFiltersApplied,
        initialFilters: _activeFilters,
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Pintura de parede, aula de ingles...',
                              hintStyle: const TextStyle(
                                color: AppColors.textoPlaceholder,
                              ),
                              filled: true,
                              fillColor: AppColors.branco,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textoPlaceholder,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              'As horas acumuladas no seu banco representam oportunidades reais de acao.',
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
                                  AppRoutes.requestCreation,
                                );

                                if (result == true) {
                                  await _reloadServices();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.branco,
                                foregroundColor: AppColors.preto,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
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
                              'ou realize o de alguem',
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
          if (_isDrawerOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: screenWidth * 0.6,
                      child: SafeArea(
                        top: true,
                        bottom: false,
                        child: SideMenu(
                          onWalletPressed: _openWallet,
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
          if (_isWalletOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WalletModal(
                      onClose: _closeWallet,
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

    if (_visibleServices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            _isFilterMode
                ? 'Nenhum servico corresponde a busca ou aos filtros.'
                : 'Nenhum servico encontrado.',
            style: const TextStyle(
              color: AppColors.branco,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visibleServices.length,
      itemBuilder: (context, index) {
        final service = _visibleServices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: service,
            onView: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.requestViewWithId(service.id),
              );

              if (result == true) {
                await _reloadServices();
              }
            },
            onCardEdited: (edited) async {
              if (edited) {
                await _reloadServices();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    if (isLoading ||
        errorMessage.isNotEmpty ||
        services.isEmpty ||
        !_hasMorePages ||
        _isFilterMode) {
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
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }
}

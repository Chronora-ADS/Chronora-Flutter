import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/main_page_requests_model.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/api_service.dart';
import 'request_accepted_view.dart';
import '../../widgets/backgrounds/background_default_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

class RequestView extends StatefulWidget {
  final Service? service; // Serviço passado da main page (opcional via construtor)

  const RequestView({super.key, this.service});

  @override
  State<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends State<RequestView> {
  ServiceDetailModel? _serviceDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOwner = false;
  int? _currentUserId;
  String? _currentUserName;
  int? _currentUserPhone;

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  // Serviço extraído (prioriza o widget, depois argumentos da rota)
  Service? _extractedService;

  @override
  void initState() {
    super.initState();
    _extractServiceAndLoad();
  }

  /// Tenta obter o serviço do widget ou dos argumentos da rota
  void _extractServiceAndLoad() {
    // 1. Tenta pegar do widget
    if (widget.service != null) {
      _extractedService = widget.service;
      _loadData();
      return;
    }

    // 2. Se não veio pelo widget, tenta pegar dos argumentos da rota
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Service) {
        _extractedService = arguments;
      } else if (arguments is Map && arguments['service'] is Service) {
        _extractedService = arguments['service'] as Service;
      }

      if (_extractedService != null) {
        _loadData();
      } else {
        setState(() {
          _errorMessage = 'Nenhum serviço informado.';
          _isLoading = false;
        });
      }
    });
  }

  Widget _buildBackgroundImages() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 135,
          child: Image.asset(
            'assets/img/Comb2.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210.47,
            height: 178.9,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 60,
          child: Image.asset(
            'assets/img/Comb3.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ],
    );
  }
  // Substitua o método _getCurrentUserId por:
  Future<void> _getCurrentUserFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuário não autenticado');

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        final resolvedUserData = userData['user'] is Map<String, dynamic>
            ? userData['user'] as Map<String, dynamic>
            : userData;
        setState(() {
          _currentUserId = resolvedUserData['id']; // ou userData['user']['id']
          _currentUserName = (resolvedUserData['name'] as String?)?.trim();
          _currentUserPhone = resolvedUserData['phoneNumber'] as int?;
        });
        print('Current user ID from API: $_currentUserId');
      } else {
        throw Exception('Falha ao obter dados do usuário');
      }
    } catch (e) {
      print('Erro ao obter usuário: $e');
      setState(() {
        _currentUserId = null;
        _currentUserName = null;
        _currentUserPhone = null;
      });
    }
  }

  // Atualize o método _loadData:
  Future<void> _loadData() async {
    await _getCurrentUserFromApi(); // <-- chamada alterada
    if (_extractedService != null) {
      await _fetchServiceDetail(_extractedService!.id);
    } else {
      setState(() {
        _errorMessage = 'Nenhum serviço informado.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchServiceDetail(int serviceId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuário não autenticado');

      final response = await ApiService.get(
        '/service/get/$serviceId',
        token: token,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final detail = ServiceDetailModel.fromJson(data);

        print('Current user ID: $_currentUserId');
        print('Creator ID: ${detail.userCreator?.id}');

        // Verifica se o usuário atual é o dono do serviço
        final isOwner = detail.userCreator?.id.toString() == _currentUserId?.toString();

        setState(() {
          _serviceDetail = detail;
          _isOwner = isOwner;
          _isLoading = false;
        });
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar detalhes: $e';
        _isLoading = false;
      });
    }
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

  Future<void> _cancelRequest() async {
    // Confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('Tem certeza que deseja cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuário não autenticado');

      const status = "CANCELADO";

      final response = await ApiService.changeStatus(
        '/service/changeStatus/${_serviceDetail!.id}',
        status,
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado com sucesso'),
            backgroundColor: AppColors.amareloClaro,
          ),
        );
        Navigator.pop(context, true); // Retorna true para atualizar a lista
      } else {
        throw Exception('Erro ao cancelar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _editRequest() {
    // Navega para a página de edição passando o serviço original
    Navigator.pushNamed(
      context,
      '/request-editing',
      arguments: _extractedService,
    ).then((edited) {
      if (edited == true) {
        // Se editado, recarrega os detalhes
        _fetchServiceDetail(_extractedService!.id);
      }
    });
  }

  void _openRequesterAcceptedPreview() {
    if (_serviceDetail == null) return;

    Navigator.pushNamed(
      context,
      '/request-accepted-view',
      arguments: {
        'serviceDetail': _serviceDetail,
        'audience': RequestAcceptedAudience.requester,
        'acceptedUserName': 'Prestador aceito',
        'acceptedUserPhone': 554799121221,
        'acceptedAt': DateTime.now(),
        'authenticationCode': '1234',
      },
    );
  }

  void _acceptRequest() {
    // TODO: Implementar lógica de aceitar pedido
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de aceitar pedido em desenvolvimento'),
        backgroundColor: AppColors.amareloUmPoucoEscuro,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          _buildBackgroundImages(),
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(),
                  ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight * 1.5,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.preto.withOpacity(0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: SideMenu(onWalletPressed: _openWallet),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleDrawer,
                        child: Container(color: Colors.transparent),
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
                color: AppColors.preto.withOpacity(0.5),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.branco),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_serviceDetail == null) {
      return const Center(
        child: Text(
          'Detalhes não disponíveis',
          style: TextStyle(color: AppColors.branco),
        ),
      );
    }

    return Container(
      child: 
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    _serviceDetail!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.preto,
                border: Border(
                  bottom: BorderSide(color: AppColors.amareloUmPoucoMaisEscuro, width: 3),
                  top: BorderSide(color: AppColors.amareloUmPoucoMaisEscuro, width: 3),
                  left: BorderSide(color: AppColors.amareloUmPoucoMaisEscuro, width: 3),
                  right: BorderSide(color: AppColors.amareloUmPoucoMaisEscuro, width: 3)
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  // Linha com imagem à esquerda e informações à direita
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem
                      ClipRRect(
                        child: Container(
                          width: 200,
                          height: 113,
                          decoration: BoxDecoration(
                            color: AppColors.cinza,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _serviceDetail!.serviceImageUrl != null &&
                                  _serviceDetail!.serviceImageUrl!.isNotEmpty
                              ? Image.network(
                                  _serviceDetail!.serviceImageUrl!,
                                  width: 160,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.cinza,
                                      child: const Icon(Icons.broken_image,
                                          size: 40, color: AppColors.cinza),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.amareloClaro),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: AppColors.cinza,
                                  child: const Icon(Icons.image,
                                      size: 40, color: AppColors.cinza),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Informações à direita
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Prazo
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.amareloUmPoucoEscuro,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Prazo: ${_formatDate(_serviceDetail!.deadline)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.branco,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Modalidade
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.amareloUmPoucoEscuro,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _serviceDetail!.modality,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.branco,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Chronos
                            // Chronos com ícone alinhado à direita
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/img/CoinYellow.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.currency_bitcoin, color: AppColors.amareloClaro, size: 20),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${_serviceDetail!.timeChronos} Chronos',
                                      style: const TextStyle(
                                        color: AppColors.amareloClaro,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: 
                      // Descrição
                      Text(
                        _serviceDetail!.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.branco
                        ),
                      ),
                  )
                ],
              ),
            ),
        
            const SizedBox(height: 5),
            if (_serviceDetail!.categoryEntities.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _serviceDetail!.categoryEntities.map((cat) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.amareloClaro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        cat.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Informações do criador em container separado
            if (_serviceDetail!.userCreator != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.branco,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Postado às ${_formatTime(_serviceDetail!.postedAt)} por:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.amareloClaro,
                          child: Text(
                            _serviceDetail!.userCreator!.name[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.branco),
                          ), // imagem perfil
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _serviceDetail!.userCreator!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Text(
                                    // _serviceDetail!.userCreator!.rating?.toStringAsFixed(1) ?? 
                                    "5.0",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.star, color: AppColors.amareloClaro, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Botões de ação
            _buildActionButtons(),
          ],
        )
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cinza,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.preto),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isOwner) {
      // Botões para o criador: Editar e Cancelar (empilhados)
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _editRequest,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                side: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Editar pedido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancelRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.preto,
                foregroundColor: AppColors.branco,
                side: const BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Cancelar pedido',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openRequesterAcceptedPreview,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.amareloClaro,
                foregroundColor: AppColors.preto,
                side: const BorderSide(
                  color: AppColors.amareloUmPoucoEscuro,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Ver pedido aceito',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Botão para outros usuários: Aceitar
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/request-accepted-view',
              arguments: {
                'serviceDetail': _serviceDetail,
                'acceptedUserName': _currentUserName,
                'acceptedUserPhone': _currentUserPhone,
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amareloUmPoucoEscuro,
            foregroundColor: AppColors.branco,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Aceitar pedido',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return date;
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '--:--';
    try {
      final parts = dateTime.split('T');
      if (parts.length > 1) {
        return parts[1].substring(0, 5); // HH:MM
      }
    } catch (_) {}
    return '--:--';
  }
}

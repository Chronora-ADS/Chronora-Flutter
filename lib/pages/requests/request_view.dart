import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/main_page_requests_model.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/api_service.dart';
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

  Future<void> _loadData() async {
    await _getCurrentUserId();
    if (_extractedService != null) {
      await _fetchServiceDetail(_extractedService!.id);
    } else {
      setState(() {
        _errorMessage = 'Nenhum serviço informado.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
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

        // Verifica se o usuário atual é o dono do serviço
        final isOwner = detail.userCreator?.id == _currentUserId;

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

      final response = await ApiService.delete(
        '/service/delete/${_serviceDetail!.id}',
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado com sucesso'),
            backgroundColor: Colors.green,
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
          backgroundColor: Colors.red,
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

  void _acceptRequest() {
    // TODO: Implementar lógica de aceitar pedido
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de aceitar pedido em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
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
                    child: _buildContent(),
                  ),
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
                color: Colors.black.withOpacity(0.5),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(15),
      ),
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
          const SizedBox(height: 16),

          // Linha com prazo, modalidade e chronos (como na imagem)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prazo: ${_formatDate(_serviceDetail!.deadline)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _serviceDetail!.modality,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amareloClaro,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_serviceDetail!.timeChronos} Chronos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Descrição
          Text(
            _serviceDetail!.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Categorias em container separado, formato lista com marcadores
          if (_serviceDetail!.categoryEntities.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categorias:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ..._serviceDetail!.categoryEntities.map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(cat.name)),
                          ],
                        ),
                      )),
                ],
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
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Postado por:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.amareloClaro,
                        child: Text(
                          _serviceDetail!.userCreator!.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
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
                            Row(
                              children: [
                                Text(
                                  // _serviceDetail!.userCreator!.rating?.toStringAsFixed(1) ?? 
                                  "5.0",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'às ${_formatTime(_serviceDetail!.postedAt)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
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
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isOwner) {
      // Botões para o criador: Editar e Cancelar
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _editRequest,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Editar pedido',
                style: TextStyle(color: AppColors.amareloUmPoucoEscuro),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _cancelRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar pedido'),
            ),
          ),
        ],
      );
    } else {
      // Botão para outros usuários: Aceitar
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _acceptRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amareloUmPoucoEscuro,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Aceitar pedido',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
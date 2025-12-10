import 'package:flutter/material.dart';
import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/widgets/header.dart';
import 'package:chronora/widgets/side_menu.dart'; 
import 'dart:convert';

class MeusPedidos extends StatefulWidget {
  const MeusPedidos({Key? key}) : super(key: key);

  @override
  _MeusPedidosState createState() => _MeusPedidosState();
}

class _MeusPedidosState extends State<MeusPedidos> with TickerProviderStateMixin {
  int _abaAtual = 0;
  final List<String> _abas = ['Pedidos Aceitos', 'Pedidos Criados'];
  final TextEditingController _searchController = TextEditingController();
  bool _isDrawerOpen = false;

  // NOVOS ESTADOS PARA LOADING/ERROR/EMPTY
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasError = false;

  // Estados de ordenação
  String _ordenacaoAtual = 'Mais recentes';
  late AnimationController _animacaoTransicao;

  // Dados de exemplo para pedidos aceitos
  final List<Map<String, dynamic>> _pedidosAceitos = [
    {
      'titulo': 'Título do pedido Lorem Ipsum dolor',
      'descricao_breve': 'Pintura de parede, aula de inglês...',
      'descricao_completa': 'Uma descrição muito longa de Lorem ipsum dolor sit amet. Vivamus dolor dolor, bibendum a conque eu, fringilla et sem. Phasellus non sem.',
      'postador': 'João Silva Santos',
      'horario': '15:41',
      'prazo': '30/10/2025',
      'modalidade': 'À distância',
      'tempo_chronos': 6,
      'temAcompanhamento': true,
      'temMotivacao': true,
      'status': 'Aceito',
      'avaliacao': '4.9',
      'categoria_principal': 'Aulas',
      'subcategoria': 'Inglês',
      'serviceImage': '', // Base64 da imagem
    },
    {
      'titulo': 'Conserto de Computador',
      'descricao_breve': 'Manutenção de hardware e software',
      'descricao_completa': 'Preciso de ajuda para consertar meu computador que não está ligando.',
      'postador': 'Maria Oliveira',
      'horario': '09:30',
      'prazo': '15/11/2025',
      'modalidade': 'Presencial',
      'tempo_chronos': 8,
      'temAcompanhamento': false,
      'temMotivacao': true,
      'status': 'Em Andamento',
      'avaliacao': '4.7',
      'categoria_principal': 'Tecnologia',
      'subcategoria': 'Informática',
      'serviceImage': '',
    },
    {
      'titulo': 'Aulas de Piano Intermediário',
      'descricao_breve': 'Aulas semanais de piano',
      'descricao_completa': 'Preciso de professor de piano para nível intermediário.',
      'postador': 'Carlos Música',
      'horario': '14:00',
      'prazo': '20/12/2025',
      'modalidade': 'Presencial',
      'tempo_chronos': 12,
      'temAcompanhamento': true,
      'temMotivacao': false,
      'status': 'Finalizado',
      'avaliacao': '5.0',
      'categoria_principal': 'Aulas',
      'subcategoria': 'Música',
      'serviceImage': '',
    },
  ];

  // Dados de exemplo para pedidos criados
  final List<Map<String, dynamic>> _pedidosCriados = [
    {
      'titulo': 'Reparo Hidráulico Residencial',
      'descricao_breve': 'Reparo em vazamento na cozinha',
      'descricao_completa': 'Preciso de um encanador para consertar um vazamento na pia da cozinha.',
      'postador': 'Carlos Mendes',
      'horario': '09:15',
      'prazo': '30/10/2025',
      'modalidade': 'Presencial',
      'tempo_chronos': 10,
      'temAcompanhamento': false,
      'temMotivacao': true,
      'status': 'Disponível',
      'avaliacao': '5.0',
      'categoria_principal': 'Reparos Domésticos',
      'subcategoria': 'Hidráulica',
      'serviceImage': '',
    },
    {
      'titulo': 'Design de Logo para Empresa',
      'descricao_breve': 'Criação de identidade visual',
      'descricao_completa': 'Preciso de um designer para criar um logo para minha nova empresa de tecnologia.',
      'postador': 'Ana Costa',
      'horario': '14:20',
      'prazo': '25/11/2025',
      'modalidade': 'À distância',
      'tempo_chronos': 15,
      'temAcompanhamento': true,
      'temMotivacao': false,
      'status': 'Aceito',
      'avaliacao': '4.8',
      'categoria_principal': 'Design',
      'subcategoria': 'Gráfico',
      'serviceImage': '',
    },
  ];

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    _animacaoTransicao = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _simularCarregamento();
  }

  @override
  void dispose() {
    _animacaoTransicao.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // NOVO: Método para gerar estrelas de avaliação
  Widget _buildRating(dynamic rating) {
    final ratingValue = double.tryParse(rating.toString()) ?? 0;
    final fullStars = ratingValue.floor();
    final hasHalfStar = (ratingValue % 1) > 0.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (i) {
          return const Icon(Icons.star, size: 14, color: Colors.amber);
        }),
        if (hasHalfStar)
          const Icon(Icons.star_half, size: 14, color: Colors.amber),
        ...List.generate(5 - fullStars - (hasHalfStar ? 1 : 0), (i) {
          return Icon(Icons.star_outline, size: 14, color: Colors.grey.withOpacity(0.5));
        }),
        const SizedBox(width: 4),
        Text(
          ratingValue.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // NOVO: Método para filtrar pedidos pela busca
  List<Map<String, dynamic>> _filtrarPedidos(List<Map<String, dynamic>> pedidos) {
    final termoBusca = _searchController.text.toLowerCase();
    
    if (termoBusca.isEmpty) {
      return _ordenarPedidos(pedidos);
    }
    
    return _ordenarPedidos(
      pedidos.where((pedido) {
        return pedido['titulo'].toString().toLowerCase().contains(termoBusca) ||
            pedido['descricao_breve'].toString().toLowerCase().contains(termoBusca) ||
            pedido['postador'].toString().toLowerCase().contains(termoBusca);
      }).toList(),
    );
  }

  // NOVO: Método para ordenar pedidos
  List<Map<String, dynamic>> _ordenarPedidos(List<Map<String, dynamic>> pedidos) {
    final pedidosOrdenados = [...pedidos];
    
    switch (_ordenacaoAtual) {
      case 'Mais recentes':
        // Já vem em ordem
        break;
      case 'Maior Chronos':
        pedidosOrdenados.sort((a, b) => (b['tempo_chronos'] ?? 0).compareTo(a['tempo_chronos'] ?? 0));
        break;
      case 'Melhor avaliação':
        pedidosOrdenados.sort((a, b) {
          final ratingA = double.tryParse(a['avaliacao'].toString()) ?? 0;
          final ratingB = double.tryParse(b['avaliacao'].toString()) ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Status':
        final ordem = {'Aceito': 1, 'Em Andamento': 2, 'Finalizado': 3, 'Disponível': 4, 'Pendente': 5};
        pedidosOrdenados.sort((a, b) {
          final statusA = ordem[a['status']] ?? 99;
          final statusB = ordem[b['status']] ?? 99;
          return statusA.compareTo(statusB);
        });
        break;
    }
    
    return pedidosOrdenados;
  }

  // NOVO: Método para calcular progresso de pedidos em andamento
  double _calcularProgresso(String status) {
    switch (status) {
      case 'Aceito':
        return 0.25;
      case 'Em Andamento':
        return 0.65;
      case 'Finalizado':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Future<void> _simularCarregamento() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    await Future.delayed(const Duration(seconds: 1)); // Simular delay de rede
    
    // Verificar se temos dados mockados
    if (_pedidosAceitos.isEmpty && _pedidosCriados.isEmpty) {
      // Pode simular erro ou empty state
      // Para simular empty state, não fazemos nada
      // Para simular erro, descomente:
      // setState(() {
      //   _hasError = true;
      //   _errorMessage = 'Não foi possível carregar os pedidos';
      // });
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _openWallet() {
    // Implementar abertura da carteira se necessário
  }

  // Função para iniciar pedido
  void _iniciarPedido(Map<String, dynamic> pedido) {
    setState(() {
      pedido['status'] = 'Em Andamento';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido "${pedido['titulo']}" iniciado!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Função para finalizar pedido
  void _finalizarPedido(Map<String, dynamic> pedido) {
    setState(() {
      pedido['status'] = 'Finalizado';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido "${pedido['titulo']}" finalizado!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // NOVO: Método para construir conteúdo dinâmico
  Widget _buildListaConteudo() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError) {
      return _buildErrorState();
    }
    
    final listaAtual = _abaAtual == 0 ? _pedidosAceitos : _pedidosCriados;
    final listaFiltrada = _filtrarPedidos(listaAtual);
    
    if (listaAtual.isEmpty) {
      return _buildEmptyState();
    }

    if (listaFiltrada.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Nenhum pedido encontrado',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar os filtros ou termos de busca',
                style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listaFiltrada.length,
      itemBuilder: (context, index) {
        final pedido = listaFiltrada[index];
        return _buildCardPedido(pedido);
      },
    );
  }

  // NOVO: Método para estado de carregamento
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: 16),
            const Text(
              'Carregando seus pedidos...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Método para estado de erro
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _simularCarregamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Método para estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _abaAtual == 0
                  ? 'Você ainda não aceitou nenhum pedido'
                  : 'Você ainda não criou nenhum pedido',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Quando você aceitar ou criar pedidos, eles aparecerão aqui.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/request-creation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text('Criar primeiro pedido'),
            ),
          ],
        ),
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
              // Header igual ao da main_page com menu funcional
              Header(
                onMenuPressed: _toggleDrawer,
              ),

              // Campo de pesquisa (igual ao main)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar meus pedidos...',
                    filled: true,
                    fillColor: AppColors.branco,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // Implementar busca nos pedidos
                    setState(() {});
                  },
                ),
              ),

              // Botão de filtro CENTRALIZADO e BRANCO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _mostrarFiltros,
                      icon: const Icon(Icons.filter_list, color: AppColors.amareloUmPoucoEscuro),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: AppColors.amareloUmPoucoEscuro,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Abas - Pedidos Aceitos / Pedidos Criados
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.branco,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: _abas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final title = entry.value;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _abaAtual = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _abaAtual == index
                                    ? AppColors.amareloClaro
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _abaAtual == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: AppColors.preto,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Linha amarela abaixo das abas
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.amareloClaro,
              ),

              // Conteúdo das abas
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _simularCarregamento,
                  color: Colors.amber,
                  backgroundColor: const Color(0xFF0B0C0C),
                  child: Container(
                    color: AppColors.preto,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contador de pedidos
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _abaAtual == 0 
                                ? '${_pedidosAceitos.length} pedidos aceitos' 
                                : '${_pedidosCriados.length} pedidos criados',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.branco.withOpacity(0.7),
                              ),
                            ),
                          ),

                          // Lista dinâmica com estados
                          _buildListaConteudo(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Menu lateral (igual ao da main_page)
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
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: SideMenu(
                        onWalletPressed: _openWallet,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleDrawer,
                        child: const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido) {
    return GestureDetector(
      onTap: () {
        // Navegar para a tela de ver pedido
        Navigator.pushNamed(
          context,
          '/view-request',
          arguments: {
            'pedido': pedido,
            'ehProprietario': _abaAtual == 1,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.amareloClaro.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do serviço
            if (pedido['serviceImage'] != null && pedido['serviceImage'].toString().isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: MemoryImage(base64.decode(pedido['serviceImage'])),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              // Placeholder para imagem
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.amareloClaro.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 40,
                    color: AppColors.amareloClaro.withOpacity(0.3),
                  ),
                ),
              ),

            // Header com título e status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(pedido['status']).withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pedido['titulo'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.preto,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(pedido['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pedido['status'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informações do pedido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descrição breve
                  Text(
                    pedido['descricao_breve'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.preto.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // NOVO: Badges visuais
                  if (pedido['temAcompanhamento'] || pedido['temMotivacao'])
                    Wrap(
                      spacing: 6,
                      children: [
                        if (pedido['temAcompanhamento'])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility, size: 12, color: Colors.blue),
                                const SizedBox(width: 4),
                                const Text(
                                  'Acompanhamento',
                                  style: TextStyle(fontSize: 11, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        if (pedido['temMotivacao'])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite, size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                const Text(
                                  'Motivação',
                                  style: TextStyle(fontSize: 11, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  
                  if (pedido['temAcompanhamento'] || pedido['temMotivacao'])
                    const SizedBox(height: 10),

                  // Informações do postador com avaliação em estrelas
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.preto.withOpacity(0.6), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Postado por ${pedido['postador']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.preto.withOpacity(0.6),
                          ),
                        ),
                      ),
                      // NOVO: Avaliação em estrelas
                      _buildRating(pedido['avaliacao']),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Prazo e Modalidade
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.amareloClaro, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Prazo: ${pedido['prazo']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.preto,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        pedido['modalidade'] == 'À distância' 
                          ? Icons.language 
                          : Icons.location_on,
                        color: AppColors.amareloClaro,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pedido['modalidade'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.preto,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Chronos
                  Row(
                    children: [
                      Image.asset(
                        'assets/img/Coin.png',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pedido['tempo_chronos']} Chronos',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.preto,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Categorias
                  if (pedido['categoria_principal'] != null || pedido['subcategoria'] != null)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (pedido['categoria_principal'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.amareloClaro.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.amareloClaro),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/Paintbrush.png',
                                  width: 12,
                                  height: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pedido['categoria_principal'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.preto,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  // NOVO: Indicador de progresso para pedidos em andamento
                  if (pedido['status'] == 'Em Andamento') ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progresso',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.preto,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(_calcularProgresso(pedido['status']) * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.preto,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _calcularProgresso(pedido['status']),
                            minHeight: 6,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Botões de ação específicos para pedidos aceitos
                  if (_abaAtual == 0) ...[
                    const SizedBox(height: 12),
                    _buildBotaoAcao(pedido),
                  ],
                ],
              ),
            ),

            // Rodapé com link para ver detalhes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.preto.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  'Clique para ver detalhes',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.amareloUmPoucoEscuro,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAcao(Map<String, dynamic> pedido) {
    switch (pedido['status']) {
      case 'Aceito':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _iniciarPedido(pedido),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Iniciar Pedido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      
      case 'Em Andamento':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _finalizarPedido(pedido),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Finalizar Pedido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      
      case 'Finalizado':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Pedido Finalizado',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aceito':
        return Colors.orange;
      case 'em andamento':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      case 'disponível':
        return Colors.orange;
      case 'pendente':
        return Colors.orange;
      default:
        return AppColors.amareloClaro;
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrar Meus Pedidos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 28, color: AppColors.preto),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFiltroItem('Status', _buildStatusFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Modalidade', _buildModalidadeFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Prazo', _buildPrazoFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Valor em Chronos', _buildValorFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Categorias', _buildCategoriasFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Ordenação', _buildOrdenacaoFiltro()),
                    const SizedBox(height: 10),
                    _buildCheckboxFiltro('Com Acompanhamento', false),
                    const SizedBox(height: 10),
                    _buildCheckboxFiltro('Com Motivação', false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Limpar filtros
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.amareloUmPoucoEscuro,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Limpar Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amareloUmPoucoEscuro,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Aplicar filtros
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloUmPoucoEscuro,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroItem(String titulo, Widget conteudo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        conteudo,
      ],
    );
  }

  Widget _buildStatusFiltro() {
    final statusList = ['Todos', 'Disponível', 'Pendente', 'Aceito', 'Em Andamento', 'Finalizado'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statusList.map((status) {
        return ChoiceChip(
          label: Text(status),
          selected: status == 'Todos',
          onSelected: (selected) {},
          selectedColor: AppColors.amareloClaro,
          labelStyle: TextStyle(
            color: status == 'Todos' ? AppColors.branco : AppColors.preto,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModalidadeFiltro() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.amareloUmPoucoEscuro),
              backgroundColor: Colors.transparent,
            ),
            child: const Text('Presencial'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.amareloUmPoucoEscuro),
              backgroundColor: Colors.transparent,
            ),
            child: const Text('À distância'),
          ),
        ),
      ],
    );
  }

  Widget _buildPrazoFiltro() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data inicial:',
              style: TextStyle(color: AppColors.preto.withOpacity(0.7)),
            ),
            Text(
              '30/10/2025',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data final:',
              style: TextStyle(color: AppColors.preto.withOpacity(0.7)),
            ),
            Text(
              '30/11/2025',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValorFiltro() {
    return Column(
      children: [
        Slider(
          value: 50.0,
          min: 0,
          max: 100,
          onChanged: (value) {},
          activeColor: AppColors.amareloClaro,
        ),
        const Text('0-100 Chronos'),
      ],
    );
  }

  Widget _buildCategoriasFiltro() {
    return DropdownButtonFormField<String>(
      value: 'Todas',
      items: ['Todas', 'Pinturas gerais', 'Aula de inglês', 'Reparos domésticos', 'Tecnologia', 'Design', 'Música']
          .map((categoria) {
        return DropdownMenuItem(
          value: categoria,
          child: Text(categoria),
        );
      }).toList(),
      onChanged: (value) {},
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.branco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.amareloUmPoucoEscuro),
        ),
      ),
    );
  }

  Widget _buildOrdenacaoFiltro() {
    return DropdownButtonFormField<String>(
      value: 'Mais recentes',
      items: ['Mais recentes', 'Mais antigos', 'Mais Chronos', 'Menos Chronos', 'Prazo próximo']
          .map((opcao) {
        return DropdownMenuItem(
          value: opcao,
          child: Text(opcao),
        );
      }).toList(),
      onChanged: (value) {},
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.branco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.amareloUmPoucoEscuro),
        ),
      ),
    );
  }

  Widget _buildCheckboxFiltro(String label, bool value) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) {},
          activeColor: AppColors.amareloClaro,
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.preto,
          ),
        ),
      ],
    );
  }
}
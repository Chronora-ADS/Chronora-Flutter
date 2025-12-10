import 'package:flutter/material.dart';
import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/widgets/header.dart';
import 'package:chronora/widgets/side_menu.dart';
import 'dart:convert';

class VerPedido extends StatefulWidget {
  final Map<String, dynamic> pedido;
  final bool ehProprietario;

  const VerPedido({
    Key? key,
    required this.pedido,
    required this.ehProprietario,
  }) : super(key: key);

  @override
  _VerPedidoState createState() => _VerPedidoState();
}

class _VerPedidoState extends State<VerPedido> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _openWallet() {
    // Implementar abertura da carteira
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

  // NOVO: Método seguro para carregar imagem
  Widget _buildServiceImage() {
    try {
      final imageData = widget.pedido['serviceImage'];
      
      // Verificar se existe e é uma string válida
      if (imageData == null || 
          imageData.toString().isEmpty || 
          imageData.toString().trim() == '') {
        return _buildPlaceholderImage();
      }
      
      // Tentar decodificar
      final decodedImage = base64.decode(imageData.toString());
      
      // Verificar se a decodificação produziu bytes válidos
      if (decodedImage.isEmpty) {
        return _buildPlaceholderImage();
      }
      
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          image: DecorationImage(
            image: MemoryImage(decodedImage),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao carregar imagem: $e');
      return _buildPlaceholderImage();
    }
  }

  // Método para placeholder quando imagem não disponível
  Widget _buildPlaceholderImage() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFB5BFAE).withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 40, color: Colors.grey.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text(
              'Sem imagem',
              style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              // Header igual ao da main_page
              Header(
                onMenuPressed: _toggleDrawer,
              ),

              // Conteúdo principal com rolagem
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.branco,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagem do serviço com decodificação segura
                        _buildServiceImage(),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título Chronora e descrição breve
                              Text(
                                'Chronora',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.preto,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.pedido['descricao_breve']?.toString() ?? 'Pintura de parede, aula de inglês...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.preto.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Título do pedido
                              Text(
                                widget.pedido['titulo']?.toString() ?? 'Título do pedido Lorem Ipsum',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.preto,
                                ),
                              ),

                              // Prazo e Modalidade
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: AppColors.amareloClaro, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prazo: ${widget.pedido['prazo']?.toString() ?? '30/10/2025'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.preto,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    widget.pedido['modalidade'] == 'À distância' 
                                      ? Icons.language 
                                      : Icons.location_on,
                                    color: AppColors.amareloClaro,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.pedido['modalidade']?.toString() ?? 'Presencial',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.preto,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // NOVO: Badges visuais
                              if (widget.pedido['temAcompanhamento'] || widget.pedido['temMotivacao'])
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (widget.pedido['temAcompanhamento'])
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blue, width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.visibility, size: 14, color: Colors.blue),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Com Acompanhamento',
                                              style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.pedido['temMotivacao'])
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green, width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite, size: 14, color: Colors.green),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Com Motivação',
                                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                              if (widget.pedido['temAcompanhamento'] || widget.pedido['temMotivacao'])
                                const SizedBox(height: 12),

                              // Card de Chronos (reduzido)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.amareloClaro.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.amareloClaro,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/img/Coin.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.pedido['tempo_chronos']?.toString() ?? '100'} Chronos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.preto,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Descrição completa
                              const SizedBox(height: 12),
                              Text(
                                widget.pedido['descricao_completa']?.toString() ?? 
                                'Uma descrição muito longa de Lorem ipsum dolor sit amet. Vivamus dolor dolor, bibendum a conque eu, fringilla et sem. Phasellus non sem.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.preto,
                                  height: 1.4,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  _mostrarDescricaoCompleta(context);
                                },
                                child: Text(
                                  'Ver mais...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.amareloUmPoucoEscuro,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Categorias
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _buildCategoryChips(),
                              ),

                              // Linha divisória e informações do postador
                              const SizedBox(height: 16),
                              Divider(color: AppColors.preto.withOpacity(0.2)),
                              const SizedBox(height: 8),
                              Text(
                                'Postado às ${widget.pedido['horario']?.toString() ?? '15:41'} por:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.preto.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.amareloClaro,
                                    radius: 16,
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.branco,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.pedido['postador']?.toString() ?? 'Lorem Ipsum da Silva',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.preto,
                                          ),
                                        ),
                                        // NOVO: Avaliação com estrelas
                                        _buildRating(widget.pedido['avaliacao']),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Botões de ação
                              const SizedBox(height: 20),
                              if (widget.ehProprietario) ...[
                                // VISÃO DO CRIADOR
                                Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Editar pedido
                                          Navigator.pushNamed(
                                            context,
                                            '/edit-request',
                                            arguments: widget.pedido,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.amareloUmPoucoEscuro,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Editar pedido',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.branco,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          _mostrarDialogCancelamento(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: AppColors.vermelho,
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Cancelar pedido',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.vermelho,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // VISÃO DE QUEM VAI ACEITAR - SIMPLIFICADO
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _mostrarDialogAceitarPedido(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Aceitar Pedido',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.branco,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  List<Widget> _buildCategoryChips() {
    final categories = <String>[];
    
    if (widget.pedido['categoria_principal'] != null) {
      categories.add(widget.pedido['categoria_principal']!.toString());
    }
    if (widget.pedido['subcategoria'] != null) {
      categories.add(widget.pedido['subcategoria']!.toString());
    }
    
    // Adicionar categorias padrão se não houver
    if (categories.isEmpty) {
      categories.add('Pinturas gerais');
    }

    return categories.map((category) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.amareloClaro.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amareloClaro, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/img/Paintbrush.png',
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _mostrarDescricaoCompleta(BuildContext context) {
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Descrição Completa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.pedido['descricao_completa']?.toString() ?? 
                  'Uma descrição muito longa de Lorem ipsum dolor sit amet. Vivamus dolor dolor, bibendum a conque eu, fringilla et sem. Phasellus non sem. Maceenasante turpis, finibus vel odio eget, cursus sagittis dui. Cras eu tristique nibh. Sed lacinia, nibh at convallis pellentesque, tortor ipsum imperdiet nisi, a placerat arcu nulla ut diam. Phasellus aliquam nisi sit amet sollicitudin ultricies. Suspendisse venenatis pulvinar ligula vel hendrerit. Suspendisse in cursus metus. Maceenas non convallis turpis, id varius lorem. Fusce in odio at urna ultrices placerat id at mi. Etiam tempor non elit vel convallis.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.preto,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogCancelamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Cancelar Pedido'),
          ],
        ),
        content: const Text('Tem certeza que deseja cancelar este pedido? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não, manter'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha dialog
              
              // Mostrar snackbar de feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Pedido cancelado com sucesso!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Simular delay antes de voltar
              Future.delayed(const Duration(milliseconds: 500), () {
                Navigator.pop(context);
              });
            },
            child: const Text('Sim, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogAceitarPedido(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Aceitar Pedido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Você deseja aceitar este pedido?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Row(
                children: [
                  Image.asset('assets/img/Coin.png', width: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.pedido['tempo_chronos'] ?? '0'} Chronos serão creditados na sua carteira após conclusão.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Mostrar feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pedido aceito!'),
                            const Text(
                              'Você será notificado sobre atualizações.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              // Voltar após delay
              Future.delayed(const Duration(milliseconds: 800), () {
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Aceitar Pedido'),
          ),
        ],
      ),
    );
  }
}
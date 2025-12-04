import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';

class MeusPedidos extends StatefulWidget {
  const MeusPedidos({Key? key}) : super(key: key);

  @override
  _MeusPedidosState createState() => _MeusPedidosState();
}

class _MeusPedidosState extends State<MeusPedidos> {
  int _abaAtual = 0;
  final List<String> _abas = ['Pedidos Aceitos', 'Pedidos Criados'];
  final TextEditingController _searchController = TextEditingController();
  bool _isDrawerOpen = false;

  // Dados de exemplo para pedidos aceitos
  final List<Map<String, dynamic>> _pedidosAceitos = [
    {
      'titulo': 'Título do pedido Lorem Ipsum dolor',
      'descricao': 'Pintura de parede, aula de inglês...',
      'postador': 'Lorem Ipsum da Silva',
      'horario': '15:41',
      'prazo': '30/10/2025',
      'modalidade': 'À distância',
      'chronos': 6,
      'temAcompanhamento': true,
      'temMotivacao': true,
      'status': 'Aceito',
    },
  ];

  // Dados de exemplo para pedidos criados
  final List<Map<String, dynamic>> _pedidosCriados = [
    {
      'titulo': 'Reparo Hidráulico Residencial',
      'descricao': 'Reparo em vazamento na cozinha',
      'postador': 'João Pereira',
      'horario': '09:15',
      'prazo': '30/10/2025',
      'modalidade': 'Presencial',
      'chronos': 10,
      'temAcompanhamento': false,
      'temMotivacao': true,
      'status': 'Pendente',
    },
  ];

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _openWallet() {
    // Implementar abertura da carteira se necessário
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
                    hintText: 'Pintura de parede, aula de inglês...',
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

              // Botão de filtro CENTRALIZADO e BRANCO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // CENTRALIZADO
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
                        backgroundColor: AppColors.branco, // COR BRANCA
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
                child: Container(
                  color: AppColors.preto,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prazo
                        _buildSectionHeader('Prazo: 30/10/2025'),
                        
                        // Modalidade
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Icon(
                                _abaAtual == 0
                                    ? Icons.language
                                    : Icons.location_on,
                                color: AppColors.amareloClaro,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _abaAtual == 0 ? 'À distância' : 'Presencial',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.branco,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lista de pedidos
                        ...(_abaAtual == 0 ? _pedidosAceitos : _pedidosCriados)
                            .map((pedido) => _buildCardPedido(pedido))
                            .toList(),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.amareloClaro,
        ),
      ),
    );
  }

  Widget _buildCardPedido(Map<String, dynamic> pedido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amareloClaro.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              pedido['titulo'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
          ),

          // Informações do postador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.person, color: AppColors.preto.withOpacity(0.6), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Postado por ${pedido['postador']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.preto.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, color: AppColors.preto.withOpacity(0.6), size: 16),
                const SizedBox(width: 4),
                Text(
                  'às ${pedido['horario']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.preto.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Chronos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Image.asset(
                  'assets/img/Coin.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${pedido['chronos']} Chronos',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
              ],
            ),
          ),

          // Acompanhamento e Motivação
          if (pedido['temAcompanhamento'] || pedido['temMotivacao'])
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (pedido['temAcompanhamento'])
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
                          Icon(Icons.check_circle, color: AppColors.amareloClaro, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Acompanhamento',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.preto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (pedido['temMotivacao'])
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
                          Icon(Icons.emoji_events, color: AppColors.amareloClaro, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Motivação',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.preto,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Status do pedido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pedido['status'] == 'Aceito'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                pedido['status'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pedido['status'] == 'Aceito'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFiltroItem('Avaliação do usuário', _buildAvaliacaoFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Tempo', _buildTempoFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Categorias', _buildCategoriasFiltro()),
                    const SizedBox(height: 20),
                    _buildFiltroItem('Ordenação', _buildOrdenacaoFiltro()),
                    const SizedBox(height: 20),
                    _buildCheckboxFiltro('Acompanhamento', false),
                    const SizedBox(height: 10),
                    _buildCheckboxFiltro('Motivação', false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.branco,
                  ),
                ),
              ),
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
          style: const TextStyle(
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

  Widget _buildAvaliacaoFiltro() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const Icon(Icons.star_border, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        const Text('4.0 estrelas'),
      ],
    );
  }

  Widget _buildTempoFiltro() {
    return Column(
      children: [
        Slider(
          value: 5.0,
          min: 1,
          max: 10,
          onChanged: (value) {},
          activeColor: AppColors.amareloClaro,
        ),
        const Text('1-5 Chronos'),
      ],
    );
  }

  Widget _buildCategoriasFiltro() {
    return DropdownButtonFormField<String>(
      value: 'Pinturas gerais',
      items: ['Pinturas gerais', 'Aula de inglês', 'Reparos domésticos', 'Consultoria', 'Design']
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
          borderSide: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
        ),
      ),
    );
  }

  Widget _buildOrdenacaoFiltro() {
    return DropdownButtonFormField<String>(
      value: 'Mais recentes',
      items: ['Mais recentes', 'Mais antigos', 'Mais Chronos', 'Menos Chronos']
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
          borderSide: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
        ),
      ),
    );
  }

  Widget _buildCheckboxFiltro(String label, bool value) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (newValue) {},
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
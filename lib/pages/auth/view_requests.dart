import 'package:flutter/material.dart';

class VerPedido extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final bool ehProprietario;

  const VerPedido({
    Key? key,
    required this.pedido,
    required this.ehProprietario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver Pedido'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com Chronos
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chronora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pedido['tempo_chronos'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descrição breve
            Text(
              pedido['descricao_breve'] ?? 'Pintura de parede, aula de inglês...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Título do pedido
            Text(
              pedido['titulo'] ?? 'Título do pedido Lorem Ipsum',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Prazo
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Prazo: ${pedido['prazo'] ?? '30/10/2025'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Modalidade
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Text(
                  pedido['modalidade'] ?? 'Presencial',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card de Chronos
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '${pedido['tempo_chronos'] ?? '100'} Chronos',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descrição completa
            Text(
              pedido['descricao_completa'] ?? 
              'Uma descrição muito longa de Lorem ipsum dolor sit amet. Vivamus dolor dolor, bibendum a congue eu, fringilla et sem. Phasellus non sem. Maeoenas ante turpis, finibus vel odio eget, cursus sagittis dui. Cras eu tristique nibh. Sed lectus, nibh at convallis pellentesque, tortor ipsum imperdiet nisi, a placerat arcu nulla ut diam. Phasellus aliquam nisi sit amet sollicitudin ultricies.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 20),

            // Categorias
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(pedido['categoria_principal'] ?? 'Pinturas gerais'),
                ),
                Chip(
                  label: Text(pedido['subcategoria'] ?? 'Pintura de parede'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Informações do postador
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Postado às 15:41 por:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: const Text(
                        'Lorem Ipsum da Silva',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('4.9'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status do pedido
            if (!ehProprietario)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aceito',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Botões de ação para proprietário
            if (ehProprietario) ...[
              ElevatedButton(
                onPressed: () {
                  // Editar pedido
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Editar pedido'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  _mostrarDialogCancelamento(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Cancelar pedido'),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogCancelamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('Tem certeza que deseja cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              // Cancelar pedido
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }
}
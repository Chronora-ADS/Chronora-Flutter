import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FiltersModal extends StatefulWidget {
  final Function() onApplyFilters;
  final double initialTempoValue;
  final String initialAvaliacaoValue;
  final String initialOrdenacaoValue;

  const FiltersModal({
    super.key,
    required this.onApplyFilters,
    this.initialTempoValue = 5.0,
    this.initialAvaliacaoValue = "0",
    this.initialOrdenacaoValue = "0",
  });

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  late double tempoValue;
  late String avaliacaoValue;
  late String ordenacaoValue;
  final TextEditingController _categoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tempoValue = widget.initialTempoValue;
    avaliacaoValue = widget.initialAvaliacaoValue;
    ordenacaoValue = widget.initialOrdenacaoValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  // Prazo
                  _buildFilterSection(
                    'Prazo',
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        border:
                            Border.all(color: AppColors.amareloUmPoucoEscuro),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: '30/10/2025',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tipo de serviço
                  _buildFilterSection(
                    'Tipo de serviço',
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.amareloUmPoucoEscuro),
                              backgroundColor:
                                  AppColors.amareloClaro.withOpacity(0.1),
                            ),
                            child: const Text('À distância'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.amareloUmPoucoEscuro),
                            ),
                            child: const Text('Presencial'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avaliação
                  _buildFilterSection(
                    'Avaliação de usuário',
                    DropdownButtonFormField<String>(
                      value: avaliacaoValue,
                      items: const [
                        DropdownMenuItem(
                            value: "0", child: Text("0 - 1 estrelas")),
                        DropdownMenuItem(
                            value: "1", child: Text("1 - 2 estrelas")),
                        DropdownMenuItem(
                            value: "2", child: Text("2 - 3 estrelas")),
                        DropdownMenuItem(
                            value: "3", child: Text("3 - 4 estrelas")),
                        DropdownMenuItem(
                            value: "4", child: Text("4 - 5 estrelas")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          avaliacaoValue = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tempo
                  _buildFilterSection(
                    'Tempo',
                    Column(
                      children: [
                        Slider(
                          value: tempoValue,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          onChanged: (value) {
                            setState(() {
                              tempoValue = value;
                            });
                          },
                          activeColor: AppColors.amareloClaro,
                        ),
                        Text(
                          tempoValue == 5
                              ? "0-5 horas"
                              : "${tempoValue.toInt() - 5}-${tempoValue.toInt()} horas",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Categorias
                  _buildFilterSection(
                    'Categorias',
                    TextField(
                      controller: _categoriaController,
                      decoration: InputDecoration(
                        hintText: 'Digite ou escolha',
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ordenação
                  _buildFilterSection(
                    'Ordenação',
                    DropdownButtonFormField<String>(
                      value: ordenacaoValue,
                      items: const [
                        DropdownMenuItem(
                            value: "0", child: Text("Mais recentes")),
                        DropdownMenuItem(
                            value: "1", child: Text("Mais antigos")),
                        DropdownMenuItem(
                            value: "2", child: Text("Melhores avaliados")),
                        DropdownMenuItem(
                            value: "3", child: Text("Maior tempo")),
                        DropdownMenuItem(
                            value: "4", child: Text("Menor tempo")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ordenacaoValue = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botão aplicar filtros
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApplyFilters();
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  void dispose() {
    _categoriaController.dispose();
    super.dispose();
  }
}

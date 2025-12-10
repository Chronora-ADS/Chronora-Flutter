import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class FiltersModal extends StatefulWidget {
  final Function(List<String> selectedCategories, String selectedTipoServico, double tempoValue, String ordenacaoValue) onApplyFilters;
  final double initialTempoValue;
  final String initialAvaliacaoValue;
  final String initialOrdenacaoValue;
  final List<String> initialSelectedCategories;
  final String initialSelectedTipoServico;

  const FiltersModal({
    super.key,
    required this.onApplyFilters,
    this.initialTempoValue = 5.0,
    this.initialAvaliacaoValue = "0",
    this.initialOrdenacaoValue = "0",
    this.initialSelectedCategories = const [],
    this.initialSelectedTipoServico = "",
  });

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  late double tempoValue;
  late String avaliacaoValue;
  late String ordenacaoValue;
  late String selectedTipoServico;
  final TextEditingController _categoriaController = TextEditingController();
  Set<String> selectedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    tempoValue = widget.initialTempoValue;
    avaliacaoValue = widget.initialAvaliacaoValue;
    ordenacaoValue = widget.initialOrdenacaoValue;
    selectedTipoServico = widget.initialSelectedTipoServico;
    selectedCategories = widget.initialSelectedCategories.toSet();
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
                            onPressed: () {
                              setState(() {
                                selectedTipoServico = selectedTipoServico == 'À distância' ? '' : 'À distância';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: selectedTipoServico == 'À distância'
                                      ? AppColors.amareloUmPoucoEscuro
                                      : AppColors.amareloUmPoucoEscuro.withOpacity(0.3)),
                              backgroundColor: selectedTipoServico == 'À distância'
                                  ? AppColors.amareloClaro.withOpacity(0.1)
                                  : AppColors.branco,
                            ),
                            child: Text(
                              'À distância',
                              style: TextStyle(
                                color: selectedTipoServico == 'À distância'
                                    ? AppColors.preto
                                    : AppColors.amareloUmPoucoEscuro.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                selectedTipoServico = selectedTipoServico == 'Presencial' ? '' : 'Presencial';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: selectedTipoServico == 'Presencial'
                                      ? AppColors.amareloUmPoucoEscuro
                                      : AppColors.amareloUmPoucoEscuro.withOpacity(0.3)),
                              backgroundColor: selectedTipoServico == 'Presencial'
                                  ? AppColors.amareloClaro.withOpacity(0.1)
                                  : AppColors.branco,
                            ),
                            child: Text(
                              'Presencial',
                              style: TextStyle(
                                color: selectedTipoServico == 'Presencial'
                                    ? AppColors.preto
                                    : AppColors.amareloUmPoucoEscuro.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.branco,
                            border:
                                Border.all(color: AppColors.amareloUmPoucoEscuro),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _categoriaController,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                setState(() {
                                  selectedCategories.add(value.trim());
                                });
                                _categoriaController.clear();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Digite e pressione Enter',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: selectedCategories.map((categoria) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amareloClaro,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    categoria,
                                    style: const TextStyle(
                                      color: AppColors.preto,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategories.remove(categoria);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.preto,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ordenação
                  _buildFilterSection(
                    'Ordenação',
                    DropdownButtonFormField<String>(
                      initialValue: ordenacaoValue,
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

          // Botões aplicar e limpar filtros
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Limpa todos os filtros
                    setState(() {
                      selectedTipoServico = "";
                      tempoValue = 5.0;
                      selectedCategories.clear();
                      avaliacaoValue = "0";
                      ordenacaoValue = "0";
                    });
                    // Chama a função de limpeza passando listas vazias e valores padrão
                    Navigator.pop(context);
                    widget.onApplyFilters([], "", 5.0, "0");
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Limpar Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amareloUmPoucoEscuro,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApplyFilters(selectedCategories.toList(), selectedTipoServico, tempoValue, ordenacaoValue);
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
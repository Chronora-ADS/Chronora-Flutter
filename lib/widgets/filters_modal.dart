import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class FiltersModal extends StatefulWidget {
  final Function(List<String> selectedCategories, String selectedTipoServico, double tempoValue, String ordenacaoValue, int prazoDias) onApplyFilters;
  final Function()? onClearFilters; // Função opcional para limpar filtros
  final double initialTempoValue;
  final String initialAvaliacaoValue;
  final String initialOrdenacaoValue;
  final List<String> initialSelectedCategories;
  final String initialSelectedTipoServico;
  final int initialPrazoDias;

  const FiltersModal({
    super.key,
    required this.onApplyFilters,
    this.onClearFilters,
    this.initialTempoValue = 0.0, // Valor inicial agora é 0 ("Qualquer")
    this.initialAvaliacaoValue = "0",
    this.initialOrdenacaoValue = "0",
    this.initialSelectedCategories = const [],
    this.initialSelectedTipoServico = "",
    this.initialPrazoDias = 0,
  });

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  late double tempoValue;
  late String avaliacaoValue;
  late String ordenacaoValue;
  late String selectedTipoServico;
  int prazoDias = 0;
  final TextEditingController _categoriaController = TextEditingController();
  Set<String> selectedCategories = <String>{};

  @override
  void initState() {
    super.initState();
    tempoValue = widget.initialTempoValue;
    avaliacaoValue = widget.initialAvaliacaoValue;
    ordenacaoValue = widget.initialOrdenacaoValue;
    selectedTipoServico = widget.initialSelectedTipoServico;
    prazoDias = widget.initialPrazoDias;
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
                    'Prazo limite',
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.branco,
                        border:
                            Border.all(color: AppColors.amareloUmPoucoEscuro),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              prazoDias > 0
                                ? 'Até ${DateTime.now().add(Duration(days: prazoDias)).day}/${DateTime.now().add(Duration(days: prazoDias)).month}'
                                : 'Selecione a data limite',
                              style: TextStyle(
                                color: prazoDias > 0
                                  ? AppColors.preto
                                  : AppColors.amareloUmPoucoEscuro.withOpacity(0.6),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.date_range, color: AppColors.amareloUmPoucoEscuro),
                            onPressed: () {
                              _showPrazoDialog();
                            },
                          ),
                        ],
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

                  // Avaliação
                  _buildFilterSection(
                    'Avaliação de usuário',
                    DropdownButtonFormField<String>(
                      initialValue: avaliacaoValue,
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
                          min: 0,
                          max: 100,
                          divisions: 20, // 20 divisões para cobrir 0-100 com incrementos de 5
                          onChanged: (value) {
                            setState(() {
                              tempoValue = value;
                            });
                          },
                          activeColor: AppColors.amareloClaro,
                        ),
                        Text(
                          tempoValue == 0
                              ? "Qualquer"
                              : tempoValue == 5
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

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Limpar todos os filtros
                    setState(() {
                      tempoValue = 0.0; // Reseta para "Qualquer"
                      avaliacaoValue = "0";
                      ordenacaoValue = "0";
                      selectedTipoServico = "";
                      selectedCategories.clear();
                      prazoDias = 0;
                      _categoriaController.clear();
                    });

                    // Chama a função de callback para limpar filtros no widget pai, se existir
                    if (widget.onClearFilters != null) {
                      Navigator.pop(context);
                      widget.onClearFilters!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amareloClaro,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Limpar Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApplyFilters(selectedCategories.toList(), selectedTipoServico, tempoValue, ordenacaoValue, prazoDias);
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

  void _showPrazoDialog() {
    DateTime? selectedDate = prazoDias > 0
        ? DateTime.now().add(Duration(days: prazoDias))
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione a data limite'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Data selecionada: ${selectedDate != null ? "${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}" : "Nenhuma data selecionada"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );

                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });

                        // Calculate days difference from today
                        final today = DateTime.now();
                        final difference = selectedDate!.difference(today);
                        prazoDias = difference.inDays;
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.amareloClaro,
                      foregroundColor: AppColors.preto,
                    ),
                    child: const Text('Selecionar Data'),
                  ),
                  const SizedBox(height: 8),
                  if (selectedDate != null) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                        });
                        prazoDias = 0; // Reset to "any date"
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro,
                        foregroundColor: AppColors.branco,
                      ),
                      child: const Text('Limpar Data'),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
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
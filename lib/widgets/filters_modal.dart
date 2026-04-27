import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/modality_options.dart';

class ServiceFilters {
  static const double maxTempoValue = 100.0;
  static const String allRatings = 'all';
  static const String sortMostRecent = '0';
  static const String sortOldest = '1';
  static const String sortBestRated = '2';
  static const String sortHighestTime = '3';
  static const String sortLowestTime = '4';

  final String deadlineText;
  final double tempoValue;
  final String avaliacaoValue;
  final String ordenacaoValue;
  final String? modalidadeSelecionada;
  final String categoriaText;

  const ServiceFilters({
    this.deadlineText = '',
    this.tempoValue = maxTempoValue,
    this.avaliacaoValue = allRatings,
    this.ordenacaoValue = sortMostRecent,
    this.modalidadeSelecionada,
    this.categoriaText = '',
  });

  bool get hasActiveFilters =>
      deadlineText.trim().isNotEmpty ||
      tempoValue < maxTempoValue ||
      avaliacaoValue != allRatings ||
      (modalidadeSelecionada?.trim().isNotEmpty ?? false) ||
      categoriaText.trim().isNotEmpty;

  bool get hasCustomSort => ordenacaoValue != sortMostRecent;
}

class FiltersModal extends StatefulWidget {
  final ValueChanged<ServiceFilters> onApplyFilters;
  final ServiceFilters initialFilters;

  const FiltersModal({
    super.key,
    required this.onApplyFilters,
    this.initialFilters = const ServiceFilters(),
  });

  @override
  State<FiltersModal> createState() => _FiltersModalState();
}

class _FiltersModalState extends State<FiltersModal> {
  late double tempoValue;
  late String avaliacaoValue;
  late String ordenacaoValue;
  String? modalidadeSelecionada;
  late final TextEditingController _deadlineController;
  late final TextEditingController _categoriaController;

  @override
  void initState() {
    super.initState();
    tempoValue = widget.initialFilters.tempoValue;
    avaliacaoValue = widget.initialFilters.avaliacaoValue;
    ordenacaoValue = widget.initialFilters.ordenacaoValue;
    modalidadeSelecionada = widget.initialFilters.modalidadeSelecionada;
    _deadlineController = TextEditingController(
      text: widget.initialFilters.deadlineText,
    );
    _categoriaController = TextEditingController(
      text: widget.initialFilters.categoriaText,
    );
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
                      child: TextField(
                        controller: _deadlineController,
                        decoration: const InputDecoration(
                          hintText: 'dd/mm/aaaa',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Tipo de servico',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ModalityOptions.labels.map((modality) {
                        final selected = modalidadeSelecionada == modality;
                        return ChoiceChip(
                          label: Text(modality),
                          selected: selected,
                          selectedColor:
                              AppColors.amareloClaro.withValues(alpha: 0.4),
                          side: const BorderSide(
                            color: AppColors.amareloUmPoucoEscuro,
                          ),
                          onSelected: (isSelected) {
                            setState(() {
                              modalidadeSelecionada =
                                  isSelected ? modality : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Avaliacao de usuario',
                    DropdownButtonFormField<String>(
                      initialValue: avaliacaoValue,
                      items: const [
                        DropdownMenuItem(
                          value: ServiceFilters.allRatings,
                          child: Text('Todas as avaliacoes'),
                        ),
                        DropdownMenuItem(
                          value: '0',
                          child: Text('0 - 1 estrelas'),
                        ),
                        DropdownMenuItem(
                          value: '1',
                          child: Text('1 - 2 estrelas'),
                        ),
                        DropdownMenuItem(
                          value: '2',
                          child: Text('2 - 3 estrelas'),
                        ),
                        DropdownMenuItem(
                          value: '3',
                          child: Text('3 - 4 estrelas'),
                        ),
                        DropdownMenuItem(
                          value: '4',
                          child: Text('4 - 5 estrelas'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          avaliacaoValue = value ?? ServiceFilters.allRatings;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.amareloUmPoucoEscuro,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Tempo',
                    Column(
                      children: [
                        Slider(
                          value: tempoValue,
                          min: 5,
                          max: ServiceFilters.maxTempoValue,
                          divisions: 19,
                          onChanged: (value) {
                            setState(() {
                              tempoValue = value;
                            });
                          },
                          activeColor: AppColors.amareloClaro,
                        ),
                        Text(
                          tempoValue >= ServiceFilters.maxTempoValue
                              ? 'Todos os tempos'
                              : 'Ate ${tempoValue.toInt()} horas',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            color: AppColors.amareloUmPoucoEscuro,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Ordenacao',
                    DropdownButtonFormField<String>(
                      initialValue: ordenacaoValue,
                      items: const [
                        DropdownMenuItem(
                          value: ServiceFilters.sortMostRecent,
                          child: Text('Mais recentes'),
                        ),
                        DropdownMenuItem(
                          value: ServiceFilters.sortOldest,
                          child: Text('Mais antigos'),
                        ),
                        DropdownMenuItem(
                          value: ServiceFilters.sortBestRated,
                          child: Text('Melhores avaliados'),
                        ),
                        DropdownMenuItem(
                          value: ServiceFilters.sortHighestTime,
                          child: Text('Maior tempo'),
                        ),
                        DropdownMenuItem(
                          value: ServiceFilters.sortLowestTime,
                          child: Text('Menor tempo'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ordenacaoValue =
                              value ?? ServiceFilters.sortMostRecent;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.branco,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.amareloUmPoucoEscuro,
                          ),
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
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      tempoValue = ServiceFilters.maxTempoValue;
                      avaliacaoValue = ServiceFilters.allRatings;
                      ordenacaoValue = ServiceFilters.sortMostRecent;
                      modalidadeSelecionada = null;
                      _deadlineController.clear();
                      _categoriaController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppColors.amareloUmPoucoEscuro,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Limpar',
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
                    FocusScope.of(context).unfocus();
                    widget.onApplyFilters(
                      ServiceFilters(
                        deadlineText: _deadlineController.text.trim(),
                        tempoValue: tempoValue,
                        avaliacaoValue: avaliacaoValue,
                        ordenacaoValue: ordenacaoValue,
                        modalidadeSelecionada: modalidadeSelecionada,
                        categoriaText: _categoriaController.text.trim(),
                      ),
                    );
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
    _deadlineController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ServiceFilters {
  static const double maxTempoValue = 100.0;
  static const double noTempoFilter = 0.0;
  static const String allRatings = 'all';
  static const String sortMostRecent = '0';
  static const String sortOldest = '1';
  static const String sortBestRated = '2';
  static const String sortHighestTime = '3';
  static const String sortLowestTime = '4';
  static const String remoteModality = 'Remoto';
  static const String presencialModality = 'Presencial';

  final String deadlineText;
  final DateTime? selectedPrazoDate;
  final double tempoValue;
  final String avaliacaoValue;
  final String ordenacaoValue;
  final String? modalidadeSelecionada;
  final String categoriaText;
  final List<String> selectedCategories;

  const ServiceFilters({
    this.deadlineText = '',
    this.selectedPrazoDate,
    this.tempoValue = noTempoFilter,
    this.avaliacaoValue = allRatings,
    this.ordenacaoValue = sortMostRecent,
    this.modalidadeSelecionada,
    this.categoriaText = '',
    this.selectedCategories = const [],
  });

  List<String> get effectiveCategories {
    final values = <String>[
      ...selectedCategories,
      if (categoriaText.trim().isNotEmpty) categoriaText.trim(),
    ];

    final normalized = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;

      final key = trimmed.toLowerCase();
      if (normalized.add(key)) {
        result.add(trimmed);
      }
    }

    return result;
  }

  bool get hasActiveFilters =>
      deadlineText.trim().isNotEmpty ||
      selectedPrazoDate != null ||
      tempoValue > noTempoFilter ||
      avaliacaoValue != allRatings ||
      (modalidadeSelecionada?.trim().isNotEmpty ?? false) ||
      effectiveCategories.isNotEmpty;

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
  DateTime? _selectedPrazoDate;
  late final TextEditingController _categoriaController;
  late final Set<String> selectedCategories;

  @override
  void initState() {
    super.initState();
    tempoValue = widget.initialFilters.tempoValue;
    avaliacaoValue = widget.initialFilters.avaliacaoValue;
    ordenacaoValue = widget.initialFilters.ordenacaoValue;
    modalidadeSelecionada = widget.initialFilters.modalidadeSelecionada;
    _selectedPrazoDate = widget.initialFilters.selectedPrazoDate ??
        _parseDate(widget.initialFilters.deadlineText);
    selectedCategories = widget.initialFilters.effectiveCategories.toSet();
    _categoriaController = TextEditingController();
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
                    'Prazo limite',
                    _buildDateSelector(),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Tipo de servico',
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectableButton(
                            label: 'A distancia',
                            selected: modalidadeSelecionada ==
                                ServiceFilters.remoteModality,
                            onPressed: () => _toggleModality(
                              ServiceFilters.remoteModality,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSelectableButton(
                            label: 'Presencial',
                            selected: modalidadeSelecionada ==
                                ServiceFilters.presencialModality,
                            onPressed: () => _toggleModality(
                              ServiceFilters.presencialModality,
                            ),
                          ),
                        ),
                      ],
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
                          child: Text('Todas as avaliações'),
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
                      decoration: _inputDecoration(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Tempo',
                    Column(
                      children: [
                        Slider(
                          value: tempoValue,
                          min: ServiceFilters.noTempoFilter,
                          max: ServiceFilters.maxTempoValue,
                          divisions: 20,
                          onChanged: (value) {
                            setState(() {
                              tempoValue = value;
                            });
                          },
                          activeColor: AppColors.amareloClaro,
                        ),
                        Text(
                          _formatTempoLabel(tempoValue),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSection(
                    'Categorias',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.branco,
                            border: Border.all(
                              color: AppColors.amareloUmPoucoEscuro,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _categoriaController,
                            onSubmitted: _addCategory,
                            decoration: InputDecoration(
                              hintText: 'Digite e pressione Enter',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    _addCategory(_categoriaController.text),
                                icon: const Icon(Icons.add),
                                color: AppColors.amareloUmPoucoEscuro,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
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
                      decoration: _inputDecoration(),
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
                  onPressed: _clearAndApplyFilters,
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
                  onPressed: _applyFilters,
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

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.branco,
        border: Border.all(color: AppColors.amareloUmPoucoEscuro),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedPrazoDate != null
                  ? 'Ate ${_formatDate(_selectedPrazoDate!)}'
                  : 'Selecione a data limite',
              style: TextStyle(
                color: _selectedPrazoDate != null
                    ? AppColors.preto
                    : AppColors.amareloUmPoucoEscuro.withValues(alpha: 0.6),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.date_range,
              color: AppColors.amareloUmPoucoEscuro,
            ),
            onPressed: _showPrazoDialog,
          ),
          if (_selectedPrazoDate != null)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.amareloUmPoucoEscuro,
              ),
              onPressed: () {
                setState(() {
                  _selectedPrazoDate = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSelectableButton({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: selected
              ? AppColors.amareloUmPoucoEscuro
              : AppColors.amareloUmPoucoEscuro.withValues(alpha: 0.3),
        ),
        backgroundColor: selected
            ? AppColors.amareloClaro.withValues(alpha: 0.1)
            : AppColors.branco,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? AppColors.preto
              : AppColors.amareloUmPoucoEscuro.withValues(alpha: 0.6),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _toggleModality(String value) {
    setState(() {
      modalidadeSelecionada = modalidadeSelecionada == value ? null : value;
    });
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.branco,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.amareloUmPoucoEscuro,
        ),
      ),
    );
  }

  void _addCategory(String value) {
    final category = value.trim();
    if (category.isEmpty) return;

    setState(() {
      selectedCategories.add(category);
      _categoriaController.clear();
    });
  }

  void _clearAndApplyFilters() {
    setState(() {
      tempoValue = ServiceFilters.noTempoFilter;
      avaliacaoValue = ServiceFilters.allRatings;
      ordenacaoValue = ServiceFilters.sortMostRecent;
      modalidadeSelecionada = null;
      selectedCategories.clear();
      _selectedPrazoDate = null;
      _categoriaController.clear();
    });

    widget.onApplyFilters(const ServiceFilters());
    Navigator.pop(context);
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    widget.onApplyFilters(
      ServiceFilters(
        selectedPrazoDate: _selectedPrazoDate,
        tempoValue: tempoValue,
        avaliacaoValue: avaliacaoValue,
        ordenacaoValue: ordenacaoValue,
        modalidadeSelecionada: modalidadeSelecionada,
        selectedCategories: _categoriesForApply(),
      ),
    );
    Navigator.pop(context);
  }

  List<String> _categoriesForApply() {
    final pendingCategory = _categoriaController.text.trim();
    return <String>{
      ...selectedCategories,
      if (pendingCategory.isNotEmpty) pendingCategory,
    }.toList();
  }

  Future<void> _showPrazoDialog() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPrazoDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      _selectedPrazoDate = DateTime(picked.year, picked.month, picked.day);
    });
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

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final parts = text.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    final parsedDate = DateTime(year, month, day);
    if (parsedDate.day != day ||
        parsedDate.month != month ||
        parsedDate.year != year) {
      return null;
    }

    return parsedDate;
  }

  String _formatDate(DateTime date) {
    return [
      date.day.toString().padLeft(2, '0'),
      date.month.toString().padLeft(2, '0'),
      date.year.toString(),
    ].join('/');
  }

  String _formatTempoLabel(double value) {
    if (value <= ServiceFilters.noTempoFilter) {
      return 'Qualquer';
    }

    final max = value.toInt();
    final min = max <= 5 ? 0 : max - 5;
    return '$min-$max horas';
  }

  @override
  void dispose() {
    _categoriaController.dispose();
    super.dispose();
  }
}

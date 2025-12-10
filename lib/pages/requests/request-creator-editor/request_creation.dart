import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Importe os widgets da main_page
import '../../../widgets/header.dart';
import '../../../widgets/side_menu.dart';
import '../../../widgets/wallet_modal.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/create_request_model.dart';

class RequestCreationPage extends StatefulWidget {
  const RequestCreationPage({super.key});
  @override
  _RequestCreationPageState createState() => _RequestCreationPageState();
}

class _RequestCreationPageState extends State<RequestCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _chronosController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedModality;
  
  late List<String> _categoriesTags;
  
  dynamic _selectedImage;
  String? _imageFileName;
  Uint8List? _imageBytes;

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoriesTags = [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _chronosController.dispose();
    _deadlineController.dispose();
    _categoriesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addCategory(String category) {
    if (category.trim().isNotEmpty) {
      setState(() {
        _categoriesTags.add(category.trim());
        _categoriesController.clear();
      });
    }
  }

  void _removeCategory(String category) {
    setState(() {
      _categoriesTags.remove(category);
    });
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      _pickImageWeb();
    } else {
      _pickImageMobile();
    }
  }

  Future<void> _pickImageMobile() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageFileName = image.name;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar imagem'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _pickImageWeb() {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/png,image/jpeg,image/jpg,image/webp,image/bmp';
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        
        reader.onLoadEnd.listen((e) {
          setState(() {
            _imageBytes = reader.result as Uint8List?;
            _imageFileName = file.name;
            _selectedImage = _imageBytes;
          });
        });
        
        reader.readAsArrayBuffer(file);
      }
    });
    
    uploadInput.click();
  }

  String _getDisplayFileName(String fileName, double maxWidth) {
    const double maxPercentage = 0.45;
    final textPainter = TextPainter(
      text: TextSpan(
        text: fileName,
        style: const TextStyle(
          color: Color(0xFFC29503),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    if (textPainter.width <= maxWidth * maxPercentage) {
      return fileName;
    }

    final extension = fileName.split('.').last;
    final nameWithoutExtension = fileName.substring(0, fileName.lastIndexOf('.'));
    final maxNameLength = (maxWidth * maxPercentage / textPainter.width * nameWithoutExtension.length * 0.6).floor();

    if (maxNameLength <= 3) {
      return '...$extension';
    }

    final truncatedName = '${nameWithoutExtension.substring(0, maxNameLength)}...$extension';
    return truncatedName;
  }

  // Método para converter imagem para base64
  Future<String?> _convertImageToBase64() async {
    try {
      if (kIsWeb) {
        if (_imageBytes != null) {
          String base64String = base64Encode(_imageBytes!);
          return base64String;
        }
      } else {
        if (_selectedImage != null && _selectedImage is File) {
          List<int> fileBytes = await _selectedImage.readAsBytes();
          String base64String = base64Encode(fileBytes);
          return base64String;
        }
      }
      return null;
    } catch (e) {
      print('Erro ao converter imagem: $e');
      return null;
    }
  }

  // Método para criar o pedido no backend - CORRIGIDO
  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriesTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma categoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedModality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma modalidade'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Recuperar o token salvo
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não autenticado. Faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // Converter imagem para base64 se existir
      String? base64Image;
      if (_selectedImage != null) {
        base64Image = await _convertImageToBase64();
      }

      // VALIDAÇÃO E FORMATAÇÃO CORRETA DA DATA
      final deadlineText = _deadlineController.text.trim();
      if (deadlineText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data de prazo é obrigatória'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // Converter data do formato DD/MM/YYYY para YYYY-MM-DD
      final deadlineParts = deadlineText.split('/');
      if (deadlineParts.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formato de data inválido. Use DD/MM/YYYY'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final String formattedDeadline;
      try {
        final day = deadlineParts[0].padLeft(2, '0');
        final month = deadlineParts[1].padLeft(2, '0');
        final year = deadlineParts[2];
        
        // Validar se é uma data válida
        final date = DateTime.parse('$year-$month-$day');
        if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A data não pode ser no passado'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _isLoading = false; });
          return;
        }
        
        formattedDeadline = '$year-$month-$day';
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data inválida'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // VALIDAÇÃO DO TEMPO EM CHRONOS
      final chronosText = _chronosController.text.trim();
      if (chronosText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tempo em Chronos é obrigatório'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final int timeChronos;
      try {
        timeChronos = int.parse(chronosText);
        if (timeChronos <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tempo em Chronos deve ser maior que zero'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _isLoading = false; });
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tempo em Chronos deve ser um número válido'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      // CRIAR O MODELO CORRETAMENTE
      final requestModel = CreateRequestModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        timeChronos: timeChronos,
        deadline: formattedDeadline,
        categories: _categoriesTags,
        modality: _selectedModality!,
        serviceImage: base64Image,
      );

      print('Enviando payload para criação de pedido...');
      print('Payload: ${requestModel.toJson()}');

      final response = await ApiService.post(
        '/service/post', 
        token: token,
        requestModel.toJson()
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpar formulário após sucesso
        _formKey.currentState!.reset();
        setState(() {
          _categoriesTags.clear();
          _selectedModality = null;
          _selectedImage = null;
          _imageFileName = null;
          _imageBytes = null;
        });

        Navigator.pop(context, true);
        
      } else {
        final error = response.body;
        print('Erro do servidor: ${response.statusCode} - $error');
        
        String errorMessage = 'Erro ao criar pedido';
        if (response.statusCode == 400) {
          errorMessage = 'Dados inválidos. Verifique as informações preenchidas.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Não autorizado. Faça login novamente.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Erro interno do servidor. Tente novamente.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage (${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erro na criação do pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      body: Stack(
        children: [
          _buildBackgroundImages(),
          
          Column(
            children: [
              Header(
                onMenuPressed: _toggleDrawer,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 60),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildForm(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
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
                        child: Container(
                          color: Colors.transparent,
                        ),
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
                    child: WalletModal(
                      onClose: _closeWallet,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImages() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 135,
          child: Image.asset(
            'assets/img/Comb2.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210.47,
            height: 178.9,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 60,
          child: Image.asset(
            'assets/img/Comb3.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFE9EAEC),
      ),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Pintura de parede, aula de inglês...',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/img/Search.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.search, size: 20),
            ),
          ),
        ),
        onChanged: (value) {
          print('Texto da busca: $value');
        },
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Criação do pedido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildFormField('Título', _titleController, validator: _requiredValidator),
            const SizedBox(height: 15),
            _buildDescriptionField(),
            const SizedBox(height: 15),
            _buildFormField('Tempo em Chronos', _chronosController, validator: _chronosValidator),
            const SizedBox(height: 15),
            _buildDateField('Prazo'),
            const SizedBox(height: 15),
            _buildCategoriesField(),
            const SizedBox(height: 15),
            _buildModalityDropdown(),
            const SizedBox(height: 25),
            _buildImageButton(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  String? _chronosValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return 'Digite um número válido maior que zero';
    }
    return null;
  }

  Widget _buildFormField(String placeholder, TextEditingController controller, {String? Function(String?)? validator}) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC),
          errorStyle: const TextStyle(fontSize: 12, height: 0.1),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        validator: _requiredValidator,
        maxLines: null,
        minLines: 3,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Descrição',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC),
          errorStyle: const TextStyle(fontSize: 12, height: 0.1),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _buildDateField(String placeholder) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _deadlineController,
        readOnly: true,
        validator: _dateValidator,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/img/calendar.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.calendar_today, size: 20),
            ),
          ),
          errorStyle: const TextStyle(fontSize: 12, height: 0.1),
        ),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _deadlineController.text = 
                  "${picked.day.toString().padLeft(2, '0')}/"
                  "${picked.month.toString().padLeft(2, '0')}/"
                  "${picked.year}";
            });
          }
        },
      ),
    );
  }

  String? _dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Data é obrigatória';
    }
    
    // Validar formato DD/MM/YYYY
    final parts = value.split('/');
    if (parts.length != 3) {
      return 'Use o formato DD/MM/YYYY';
    }
    
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        return 'Data não pode ser no passado';
      }
    } catch (e) {
      return 'Data inválida';
    }
    
    return null;
  }

  Widget _buildCategoriesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EAEC),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _categoriesController,
            decoration: InputDecoration(
              hintText: 'Categoria(s) - Pressione Enter para adicionar',
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.7),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFE9EAEC),
            ),
            onFieldSubmitted: _addCategory,
          ),
        ),
        
        if (_categoriesTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoriesTags.map((tag) => _buildTag(tag)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String tagText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFC29503),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPaintbrushIcon(),
          const SizedBox(width: 6),
          Text(
            tagText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeCategory(tagText),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaintbrushIcon() {
    return Image.asset(
      'assets/img/Paintbrush.png',
      width: 24,
      height: 24,
      color: Colors.white,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.category,
          color: Colors.white,
          size: 24,
        );
      },
    );
  }

  Widget _buildModalityDropdown() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedModality,
        validator: (value) => value == null ? 'Selecione uma modalidade' : null,
        decoration: InputDecoration(
          hintText: 'Modalidade',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/img/down-arrow.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.arrow_drop_down, size: 24),
            ),
          ),
          errorStyle: const TextStyle(fontSize: 12, height: 0.1),
        ),
        items: ['Presencial', 'Remoto', 'Híbrido']
            .map((modality) => DropdownMenuItem(
                  value: modality,
                  child: Text(modality),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedModality = value;
          });
        },
      ),
    );
  }

  Widget _buildImageButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = constraints.maxWidth;
        final displayText = _imageFileName != null 
            ? _getDisplayFileName(_imageFileName!, buttonWidth)
            : 'Imagem do pedido';

        return GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFC29503),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        color: Color(0xFFC29503),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _imageFileName != null
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFFC29503),
                          size: 24,
                        )
                      : Image.asset(
                          'assets/img/AddImage.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.add_photo_alternate, color: Color(0xFFC29503)),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFC29503),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFFC29503),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFC29503),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _createRequest,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Criar pedido',
                      style: TextStyle(
                        color: Color(0xFFE9EAEC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
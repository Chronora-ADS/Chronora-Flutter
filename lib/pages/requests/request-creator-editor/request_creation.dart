import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html if (dart.library.io) 'dart:io';
import 'dart:typed_data';

// Importe estes widgets se eles existirem no seu projeto
// import '../widgets/side_menu.dart';
// import '../widgets/wallet_modal.dart';

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

  // Fixed: Use late keyword to ensure initialization
  late List<String> _categoriesTags;

  // Updated: Variables for image handling (web compatible)
  dynamic _selectedImage;
  String? _imageFileName;
  Uint8List? _imageBytes;

  // New: Variables for side menu and wallet
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  @override
  void initState() {
    super.initState();
    _categoriesTags = []; // This will never be null
  }

  // Fixed: Dispose controllers to prevent memory leaks
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

  // Safe method to add categories
  void _addCategory(String category) {
    if (category.trim().isNotEmpty) {
      setState(() {
        _categoriesTags.add(category.trim());
        _categoriesController.clear();
      });
    }
  }

  // Safe method to remove categories
  void _removeCategory(String category) {
    setState(() {
      _categoriesTags.remove(category);
    });
  }

  // Updated: Web-compatible image picker
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web implementation
      _pickImageWeb();
    } else {
      // Mobile implementation
      _pickImageMobile();
    }
  }

  // Mobile image picker
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

  // Web image picker
  void _pickImageWeb() {
    // Create a file input element
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
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

    // Trigger the file selection dialog
    uploadInput.click();
  }

  // Updated: Method to truncate filename if too long (web compatible)
  String _getDisplayFileName(String fileName, double maxWidth) {
    const double maxPercentage = 0.45; // 45% of button width
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

    // Truncate the filename
    final extension = fileName.split('.').last;
    final nameWithoutExtension =
        fileName.substring(0, fileName.lastIndexOf('.'));
    final maxNameLength = (maxWidth *
            maxPercentage /
            textPainter.width *
            nameWithoutExtension.length *
            0.6)
        .floor();

    if (maxNameLength <= 3) {
      return '...$extension';
    }

    final truncatedName =
        '${nameWithoutExtension.substring(0, maxNameLength)}...$extension';
    return truncatedName;
  }

  // New: Side menu toggle function
  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  // New: Wallet open function
  void _openWallet() {
    setState(() {
      _isDrawerOpen = false; // Fecha o side menu
      _isWalletOpen = true; // Abre a carteira
    });
  }

  // New: Wallet close function
  void _closeWallet() {
    setState(() {
      _isWalletOpen = false;
    });
  }

  // Temporary SideMenu widget (substitua pelo seu widget real se existir)
  Widget _buildTemporarySideMenu() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 100,
            color: Color(0xFFFFC300),
            child: Center(
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Perfil'),
                  onTap: () {
                    // Navegar para perfil
                    _toggleDrawer();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.wallet),
                  title: Text('Carteira'),
                  onTap: _openWallet,
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Histórico'),
                  onTap: () {
                    // Navegar para histórico
                    _toggleDrawer();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configurações'),
                  onTap: () {
                    // Navegar para configurações
                    _toggleDrawer();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Sair'),
                  onTap: () {
                    // Fazer logout
                    _toggleDrawer();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Temporary WalletModal widget (substitua pelo seu widget real se existir)
  Widget _buildTemporaryWalletModal() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFFFFC300),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: _closeWallet,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Carteira',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 48), // Para balancear o espaço do ícone
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Saldo
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Saldo Disponível',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/img/Coin.png',
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.monetization_on,
                                      size: 30, color: Colors.amber),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '123',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chronos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Histórico de transações
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Últimas Transações',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            children: [
                              _buildTransactionItem(
                                  'Serviço de Pintura', '+5', true),
                              _buildTransactionItem(
                                  'Aula de Inglês', '-3', false),
                              _buildTransactionItem(
                                  'Manutenção Elétrica', '+8', true),
                              _buildTransactionItem('Consultoria', '-2', false),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildTransactionItem(
      String description, String amount, bool isCredit) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? Colors.green[100] : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Hoje - 14:30',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      body: Stack(
        children: [
          // Background images
          _buildBackgroundImages(),

          // Main content
          Column(
            children: [
              // Updated: Using the same header structure as main_page
              _buildHeader(),
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

          // Menu lateral
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
                      child:
                          _buildTemporarySideMenu(), // Use o SideMenu real aqui se disponível
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

          // Modal da Carteira
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
                    child:
                        _buildTemporaryWalletModal(), // Use o WalletModal real aqui se disponível
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Updated: Header following main_page structure
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC300), // Amarelo do header
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu button (left)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: GestureDetector(
              onTap: _toggleDrawer,
              child: Image.asset(
                'assets/img/Menu.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.menu, size: 30, color: Colors.black),
              ),
            ),
          ),

          // Logo (center)
          Image.asset(
            'assets/img/LogoHeader.png',
            width: 125,
            height: 39,
            errorBuilder: (context, error, stackTrace) => const Text(
              'CHRONORA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Coin and balance (right)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: _openWallet,
              child: Row(
                children: [
                  Image.asset(
                    'assets/img/Coin.png',
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.monetization_on,
                        size: 25,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '123',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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

            _buildFormField('Título', _titleController,
                validator: _requiredValidator),
            const SizedBox(height: 15),
            _buildDescriptionField(), // Updated: Expanded description field
            const SizedBox(height: 15),
            _buildFormField('Tempo em Chronos', _chronosController,
                validator: _requiredValidator),
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

  // Fixed: Added validation function
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  Widget _buildFormField(String placeholder, TextEditingController controller,
      {String? Function(String?)? validator}) {
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

  // New: Expanded description field that grows vertically
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
        maxLines: null, // Allows unlimited lines - expands vertically
        minLines: 3, // Minimum 3 lines height
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Descrição',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        validator: _requiredValidator,
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
                  "${picked.day}/${picked.month}/${picked.year}";
            });
          }
        },
      ),
    );
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

        // Fixed: Direct check on the late-initialized list
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
        value: _selectedModality,
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
                              const Icon(Icons.add_photo_alternate,
                                  color: Color(0xFFC29503)),
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
              onPressed: () => Navigator.pop(context),
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Fixed: Added validation for categories
                  if (_categoriesTags.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adicione pelo menos uma categoria'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Lógica para criar o pedido
                  print('Pedido criado com sucesso!');
                  print('Título: ${_titleController.text}');
                  print('Descrição: ${_descriptionController.text}');
                  print('Chronos: ${_chronosController.text}');
                  print('Prazo: ${_deadlineController.text}');
                  print('Categorias: $_categoriesTags');
                  print('Modalidade: $_selectedModality');
                  if (_imageFileName != null) {
                    print('Imagem selecionada: $_imageFileName');
                    if (kIsWeb) {
                      print('Image bytes length: ${_imageBytes?.length}');
                    } else {
                      print('Image path: ${_selectedImage?.path}');
                    }
                  }

                  // TODO: Implement actual request creation logic

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido criado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate back after successful creation
                  Navigator.pop(context);
                }
              },
              child: const Text(
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

import 'package:flutter/material.dart';

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
  String? _selectedModality;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      body: SafeArea(
        child: Column(
          children: [
            // Header - FORA do Padding para ocupar 100% da largura
            _buildHeader(),
            const SizedBox(height: 16),
            
            // Conteúdo principal DENTRO do Padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 60), // Gap de 6px abaixo da search bar
                    
                    // Main Form
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, // Ocupa 100% da largura
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribui espaço entre os elementos
        children: [
          // Menu na esquerda
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Image.asset(
              'assets/img/Menu.png',
              width: 40,
              height: 40,
            ),
          ),
          
          // Logo no centro
          Image.asset(
            'assets/img/LogoHeader.png',
            width: 125,
            height: 39,
          ),
          
          // Moedas na direita com texto
          Padding(
            padding: const EdgeInsets.only(right: 0), // Desloca 53px para a esquerda
            child: Row(
              children: [
                Image.asset(
                  'assets/img/Coin.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 8), // Espaço entre ícone e texto
                Container(
                  width: 39,
                  height: 24,
                  child: const Text(
                    '123',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFE9EAEC), // 100% de opacidade
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaço entre texto e ícone
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Pintura de parede, aula de inglês...',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/img/Search.png',
              width: 20,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC), // E9EAEC
        borderRadius: BorderRadius.circular(15),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do formulário - CENTRALIZADO
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

            // Campos do formulário
            _buildFormField('Título', _titleController),
            const SizedBox(height: 15),
            _buildFormField('Descrição', _descriptionController),
            const SizedBox(height: 15),
            _buildFormField('Tempo em Chronos', _chronosController),
            const SizedBox(height: 15),
            _buildDateField('Prazo'),
            const SizedBox(height: 15),
            _buildFormField('Categoria(s)', _categoriesController),
            const SizedBox(height: 15),
            _buildModalityDropdown(),
            const SizedBox(height: 25),

            // Botão de imagem
            _buildImageButton(),
            const SizedBox(height: 30),

            // Botões de ação
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String placeholder, TextEditingController controller) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC), // E9EAEC
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
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7), // 70% de transparência
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC), // E9EAEC
        ),
      ),
    );
  }

  Widget _buildDateField(String placeholder) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC), // E9EAEC
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
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7), // 70% de transparência
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC), // E9EAEC
          suffixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/img/calendar.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            _deadlineController.text = "${picked.day}/${picked.month}/${picked.year}";
          }
        },
      ),
    );
  }

  Widget _buildModalityDropdown() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC), // E9EAEC
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
        decoration: InputDecoration(
          hintText: 'Modalidade',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7), // 70% de transparência
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC), // E9EAEC
          suffixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/img/down-arrow.png',
              width: 24,
              height: 24,
            ),
          ),
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
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC29503),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaço entre texto e imagem
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: const Text(
              'Imagem do pedido',
              style: TextStyle(
                color: Color(0xFFC29503),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/img/AddImage.png',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão Cancelar
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
        
        // Botão Criar Pedido
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
                  // Lógica para criar o pedido
                }
              },
              child: const Text(
                'Criar pedido',
                style: TextStyle(
                  color: Color(0xFFE9EAEC), // E9EAEC
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
// pages/profile_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/services/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = ProfileController();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  bool _isLoading = false;
  bool _isEditing = false;
  File? _documentFile;
  String _documentFileName = '';

  @override
  void initState() {
    super.initState();
    
    // Inicializa os controladores
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('Iniciando carregamento do perfil...');
    await _controller.loadUserProfile();

    if (_controller.user != null) {
      nameController.text = _controller.user!.name;
      emailController.text = _controller.user!.email;
      phoneController.text = _controller.user!.phoneNumber;

      print('Perfil carregado com sucesso:');
      print('Nome: ${_controller.user!.name}');
      print('Email: ${_controller.user!.email}');
      print('Telefone: ${_controller.user!.phoneNumber}');
    } else {
      print('Erro ao carregar perfil: ${_controller.errorMessage}');
    }

    setState(() {});
  }

  Future<void> _pickDocument() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file != null) {
        setState(() {
          _documentFile = File(file.path);
          _documentFileName = file.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Conta'),
        content: const Text(
          'Tem certeza que deseja deletar sua conta? Esta ação não pode ser desfeita e todos os seus dados serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() => _isLoading = true);
      
      final success = await _controller.deleteAccount();
      
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta deletada com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar conta: ${_controller.errorMessage}')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    if (newPasswordController.text.isNotEmpty) {
      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem')),
        );
        return;
      }
      if (currentPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite sua senha atual para mudar a senha')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _isEditing = false;
    });

    final success = await _controller.updateUserProfile(
      name: nameController.text,
      email: emailController.text,
      phoneNumber: phoneController.text,
      newPassword: newPasswordController.text.isNotEmpty ? newPasswordController.text : null,
      currentPassword: currentPasswordController.text.isNotEmpty ? currentPasswordController.text : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      _loadUserProfile();
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${_controller.errorMessage}')),
      );
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      if (_controller.user != null) {
        nameController.text = _controller.user!.name;
        emailController.text = _controller.user!.email;
        phoneController.text = _controller.user!.phoneNumber;
      }
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _documentFile = null;
      _documentFileName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Column(
        children: [
          // Header igual ao da MainPage
          _buildHeader(),
          
          // Campo de pesquisa
          Container(
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pintura de parede, aula de inglês...',
                hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
                filled: true,
                fillColor: AppColors.branco,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.search, color: AppColors.textoPlaceholder),
              ),
            ),
          ),

          // Conteúdo do perfil
          Expanded(
            child: _controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
                    ),
                  )
                : _controller.user == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar perfil',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _controller.errorMessage,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadUserProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.amareloClaro,
                              ),
                              child: const Text(
                                'Tentar novamente',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Card(
                              color: AppColors.branco,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Informações Pessoais
                                    const Text(
                                      'Informações Pessoais',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.preto,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Nome
                                    _buildInfoRow('Nome', nameController, Icons.person, enabled: _isEditing),
                                    const SizedBox(height: 16),

                                    // Email
                                    _buildInfoRow('Email', emailController, Icons.email, enabled: false),
                                    const SizedBox(height: 16),

                                    // Telefone
                                    _buildInfoRow('Telefone', phoneController, Icons.phone, enabled: _isEditing),
                                    const SizedBox(height: 24),

                                    // Documento com Foto
                                    const Text(
                                      'Documento com Foto',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.preto,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    GestureDetector(
                                      onTap: _isEditing ? _pickDocument : null,
                                      child: Container(
                                        width: double.infinity,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: AppColors.cinza.withOpacity(0.1),
                                          border: Border.all(
                                            color: AppColors.cinza,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: _documentFile != null
                                            ? Stack(
                                                children: [
                                                  Center(
                                                    child: Image.file(
                                                      _documentFile!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  ),
                                                  if (_isEditing)
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            _documentFile = null;
                                                            _documentFileName = '';
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.red,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              )
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.upload_file,
                                                    size: 32,
                                                    color: AppColors.cinza,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    _isEditing 
                                                        ? 'Clique para selecionar um arquivo'
                                                        : 'Clique em "Atualizar perfil" para editar',
                                                    style: TextStyle(
                                                      color: AppColors.cinza,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _documentFile != null 
                                          ? 'Arquivo selecionado: $_documentFileName'
                                          : 'Nenhum arquivo selecionado',
                                      style: TextStyle(
                                        color: AppColors.cinza,
                                        fontSize: 10,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Alterar Senha (só aparece em modo edição)
                                    if (_isEditing) ...[
                                      const Text(
                                        'Alterar Senha',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.preto,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      _buildPasswordField('Senha Atual', currentPasswordController, Icons.lock),
                                      const SizedBox(height: 12),

                                      _buildPasswordField('Nova Senha', newPasswordController, Icons.lock_outline),
                                      const SizedBox(height: 12),

                                      _buildPasswordField('Confirmar Nova Senha', confirmPasswordController, Icons.lock_outline),

                                      const SizedBox(height: 24),
                                    ],

                                    // Botões de Ação
                                    if (_isEditing)
                                      // Modo edição: Cancelar + Atualizar
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: _isLoading ? null : _cancelEditing,
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppColors.amareloClaro),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  color: AppColors.amareloClaro,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _updateProfile,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.amareloClaro,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 18,
                                                      width: 18,
                                                      child: CircularProgressIndicator(
                                                        valueColor: AlwaysStoppedAnimation(AppColors.preto),
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Salvar alterações',
                                                      style: TextStyle(
                                                        color: AppColors.preto,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      // Modo visualização: Apenas Atualizar perfil
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _startEditing,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.amareloClaro,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: const Text(
                                            'Atualizar perfil',
                                            style: TextStyle(
                                              color: AppColors.preto,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 12),

                                    // Botão Deletar Conta (sempre visível)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : _deleteAccount,
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation(Colors.red),
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Deletar conta',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Header igual ao da MainPage
  Widget _buildHeader() {
    return AppBar(
      backgroundColor: AppColors.amareloClaro,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.preto),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/img/LogoHeader.png',
            width: 125,
            height: 32,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Image.asset('assets/img/Coin.png', width: 24, height: 24),
            const SizedBox(width: 4),
            Text(
              _controller.user?.timeChronos?.toString() ?? '0',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildInfoRow(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cinza, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.preto,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                enabled: enabled,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinza),
                  ),
                  disabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinza),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.amareloClaro),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cinza, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.preto,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinza),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.amareloClaro),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
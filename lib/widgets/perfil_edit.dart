import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/profile_controller.dart';

class PerfilEdit extends StatefulWidget {
  const PerfilEdit({super.key});

  @override
  State<PerfilEdit> createState() => _PerfilEditState();
}

class _PerfilEditState extends State<PerfilEdit> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController descricaoController;
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final ProfileController _controller = ProfileController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _documentFile;
  String _documentFileName = '';

  late User _user;
  late VoidCallback _onProfileUpdated;

  @override
  void initState() {
    super.initState();
    
    // Inicializa os controladores com valores vazios
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    descricaoController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtém os arguments passados na navegação
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args != null) {
      _user = args['user'] as User;
      _onProfileUpdated = args['onProfileUpdated'] as VoidCallback;
      
      // Preenche os controladores com os dados do usuário
      nameController.text = _user.name;
      emailController.text = _user.email;
      phoneController.text = _user.phoneNumber;
      descricaoController.text = _user.descricao ?? '';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.preto,
        foregroundColor: AppColors.branco,
        elevation: 0,
      ),
      backgroundColor: AppColors.preto,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card único com todas as informações pessoais
            Card(
              color: AppColors.cinza.withOpacity(0.1),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações Pessoais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nome
                    _buildInfoRow('Nome', nameController, Icons.person),
                    const SizedBox(height: 16),

                    // Email
                    _buildInfoRow('Email', emailController, Icons.email, enabled: false),
                    const SizedBox(height: 16),

                    // Telefone
                    _buildInfoRow('Telefone', phoneController, Icons.phone),
                    const SizedBox(height: 16),

                    // Time Chronos (somente leitura)
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: AppColors.cinza),
                        const SizedBox(width: 12),
                        const Text(
                          'Time Chronos:',
                          style: TextStyle(
                            color: AppColors.branco,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _user.timeChronos?.toString() ?? '0',
                          style: const TextStyle(
                            color: AppColors.branco,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Seção de Documento com Foto
            Card(
              color: AppColors.cinza.withOpacity(0.1),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documento com Foto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _pickDocument,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.cinza.withOpacity(0.05),
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
                                    size: 40,
                                    color: AppColors.cinza,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Clique para selecionar um arquivo',
                                    style: TextStyle(
                                      color: AppColors.cinza,
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
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Seção de Alterar Senha
            Card(
              color: AppColors.cinza.withOpacity(0.1),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alterar Senha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.branco,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField('Senha Atual', currentPasswordController, Icons.lock),
                    const SizedBox(height: 16),

                    _buildPasswordField('Nova Senha', newPasswordController, Icons.lock_outline),
                    const SizedBox(height: 16),

                    _buildPasswordField('Confirmar Nova Senha', confirmPasswordController, Icons.lock_outline),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botões de Ação
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.amareloClaro),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloClaro,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(AppColors.preto),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Atualizar perfil',
                                style: TextStyle(
                                  color: AppColors.preto,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botão Deletar Conta
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cinza),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                enabled: enabled,
                style: const TextStyle(
                  color: AppColors.branco,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
        Icon(icon, color: AppColors.cinza),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(
                  color: AppColors.branco,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

    setState(() => _isLoading = true);

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
      _onProfileUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${_controller.errorMessage}')),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    descricaoController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
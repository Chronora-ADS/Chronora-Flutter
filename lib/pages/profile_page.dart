import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/services/profile_controller.dart';
import '../widgets/backgrounds/background_default_widget.dart';
import '../widgets/header.dart';
import '../widgets/side_menu.dart';
import '../widgets/wallet_modal.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = ProfileController();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isSubmitting = false;
  bool _isEditing = false;

  XFile? _documentFile;
  Uint8List? _documentBytes;
  String _documentFileName = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    await _controller.loadUserProfile();
    if (!mounted) return;

    final user = _controller.user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
    }

    setState(() {});
  }

  Future<void> _pickDocument() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null || !mounted) return;

      setState(() {
        _documentFile = file;
        _documentBytes = null;
        _documentFileName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  Future<Map<String, String>?> _buildDocumentPayload() async {
    if (_documentFile == null) {
      return null;
    }

    final bytes = _documentBytes ?? await _documentFile!.readAsBytes();
    _documentBytes = bytes;

    final extension = _documentFileName.contains('.')
        ? _documentFileName.split('.').last
        : 'jpg';

    return {
      'name': _documentFileName,
      'type': extension,
      'data': base64Encode(bytes),
    };
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

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    final user = _controller.user;
    setState(() {
      _isEditing = false;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
      }
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _documentFile = null;
      _documentBytes = null;
      _documentFileName = '';
    });
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e email.')),
      );
      return;
    }

    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas nao coincidem.')),
      );
      return;
    }

    if (_newPasswordController.text.isNotEmpty &&
        _currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite a senha atual para trocar a senha.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await _controller.updateUserProfile(
      id: _controller.user?.id ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      document: await _buildDocumentPayload(),
      password: _newPasswordController.text.trim().isEmpty
          ? null
          : _newPasswordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _isEditing = false;
    });

    await _loadUserProfile();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, size: 32),
                  ),
                ],
              ),
              const Text(
                'Deseja mesmo deletar sua conta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.preto,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Voce perdera seus Chronos e pedidos em aberto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.preto),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Deletar conta',
                    style: TextStyle(
                      color: AppColors.branco,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    final success = await _controller.deleteAccount();

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage)),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasError = !_controller.isLoading && _controller.user == null;

    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _buildProfileCard(hasError),
                  ),
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: screenWidth * 0.6,
                      child: SafeArea(
                        top: true,
                        bottom: false,
                        child: SideMenu(
                          onWalletPressed: _openWallet,
                          userName: _controller.user?.name ?? 'Usuario',
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleDrawer,
                        child: Container(color: Colors.transparent),
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
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WalletModal(onClose: _closeWallet),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool hasError) {
    if (_controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
          ),
        ),
      );
    }

    if (hasError) {
      return _buildErrorCard();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Perfil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _nameController,
            hintText: 'Nome',
            enabled: _isEditing,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            controller: _emailController,
            hintText: 'E-mail',
            enabled: false,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            controller: _phoneController,
            hintText: 'Telefone',
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 14),
            _buildInputField(
              controller: _currentPasswordController,
              hintText: 'Senha atual',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _newPasswordController,
              hintText: 'Nova senha',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: _confirmPasswordController,
              hintText: 'Confirmar nova senha',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            _buildDocumentField(),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_isEditing
                          ? _cancelEditing
                          : () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.main,
                              )),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.amareloUmPoucoEscuro,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppColors.amareloUmPoucoEscuro,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_isEditing ? _updateProfile : _startEditing),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amareloUmPoucoEscuro,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.branco,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Atualizar perfil' : 'Editar perfil',
                          style: const TextStyle(
                            color: AppColors.branco,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _isSubmitting ? null : _confirmDeleteAccount,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Deletar conta',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        children: [
          const Text(
            'Erro ao carregar perfil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.preto),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloClaro,
              foregroundColor: AppColors.preto,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.preto),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.brancoBorda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.brancoBorda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
        ),
      ),
    );
  }

  Widget _buildDocumentField() {
    return InkWell(
      onTap: _pickDocument,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.amareloUmPoucoEscuro,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _documentFileName.isEmpty
                    ? 'Selecionar documento com foto'
                    : _documentFileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_documentFileName.isNotEmpty)
              InkWell(
                onTap: () {
                  setState(() {
                    _documentFile = null;
                    _documentBytes = null;
                    _documentFileName = '';
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.close, color: AppColors.preto, size: 18),
                ),
              ),
            const Icon(
              Icons.upload_file,
              color: AppColors.amareloUmPoucoEscuro,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

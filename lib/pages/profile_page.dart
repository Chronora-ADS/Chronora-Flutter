import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/camera_capture_page.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/services/profile_controller.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/service_image_resolver.dart';
import '../widgets/backgrounds/background_default_widget.dart';
import '../widgets/header.dart';
import '../widgets/animated_side_menu_overlay.dart';
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
  XFile? _profileImageFile;
  Uint8List? _profileImageBytes;
  String _profileImageFileName = '';

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
      AppSnackBar.show(context, 'Erro ao selecionar arquivo: $e', isError: true);
    }
  }

  Future<void> _pickProfileImageFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _profileImageFile = file;
        _profileImageBytes = bytes;
        _profileImageFileName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Erro ao selecionar foto de perfil: $e', isError: true);
    }
  }

  Future<void> _pickProfileImageFromCamera() async {
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _profileImageFile = null;
      _profileImageBytes = bytes;
      _profileImageFileName = 'foto_perfil.jpg';
    });
  }

  void _showProfileImagePicker() {
    if (kIsWeb) {
      _pickProfileImageFromGallery();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.branco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.amareloUmPoucoEscuro),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.amareloUmPoucoEscuro),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImageFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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

  Future<Map<String, String>?> _buildProfileImagePayload() async {
    if (_profileImageFile == null && _profileImageBytes == null) {
      return null;
    }

    final bytes = _profileImageBytes ?? await _profileImageFile!.readAsBytes();
    _profileImageBytes = bytes;

    final extension = _profileImageFileName.contains('.')
        ? _profileImageFileName.split('.').last
        : 'jpg';

    return {
      'name': _profileImageFileName,
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
      _profileImageFile = null;
      _profileImageBytes = null;
      _profileImageFileName = '';
    });
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      AppSnackBar.show(context, 'Preencha nome e email.', isError: true);
      return;
    }

    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      AppSnackBar.show(context, 'As senhas não coincidem.', isError: true);
      return;
    }

    if (_newPasswordController.text.isNotEmpty &&
        _currentPasswordController.text.isEmpty) {
      AppSnackBar.show(context, 'Digite a senha atual para trocar a senha.', isError: true);
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
      profileImage: await _buildProfileImagePayload(),
      password: _newPasswordController.text.trim().isEmpty
          ? null
          : _newPasswordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      AppSnackBar.show(context, _controller.errorMessage, isError: true);
      return;
    }

    AppSnackBar.show(context, 'Perfil atualizado com sucesso.');

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _isEditing = false;
      _documentFile = null;
      _documentBytes = null;
      _documentFileName = '';
      _profileImageFile = null;
      _profileImageBytes = null;
      _profileImageFileName = '';
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
                'Você perderá seus Chronos e pedidos em aberto.',
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
      AppSnackBar.show(context, _controller.errorMessage, isError: true);
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
          AnimatedSideMenuOverlay(
            isOpen: _isDrawerOpen,
            onClose: _toggleDrawer,
            onWalletPressed: _openWallet,
            top: 0,
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
          _buildProfileSummary(),
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

  Widget _buildProfileSummary() {
    final user = _controller.user;
    final rating = user?.rating ?? 0.0;

    return Column(
      children: [
        _buildProfileAvatar(),
        if (_isEditing) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _showProfileImagePicker,
            icon: const Icon(
              Icons.photo_camera,
              color: AppColors.amareloUmPoucoEscuro,
            ),
            label: Text(
              _profileImageFileName.isEmpty
                  ? 'Selecionar foto de perfil'
                  : _profileImageFileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.amareloUmPoucoEscuro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.brancoBorda),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: AppColors.amareloUmPoucoEscuro,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sua avaliação',
                style: TextStyle(
                  color: AppColors.preto,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    final imageBytes = _profileImageBytes ??
        ServiceImageResolver.tryDecodeBytes(_controller.user?.profileImage);
    final networkUrl = ServiceImageResolver.resolveNetworkUrl(
      _controller.user?.profileImage,
    );

    Widget child;
    if (imageBytes != null) {
      child = Image.memory(
        imageBytes,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      );
    } else if (networkUrl != null) {
      child = Image.network(
        networkUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
      );
    } else {
      child = _buildAvatarPlaceholder();
    }

    return ClipOval(
      child: Container(
        width: 96,
        height: 96,
        color: const Color(0xFFF3F3F3),
        child: child,
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return const Icon(
      Icons.person,
      size: 46,
      color: AppColors.amareloUmPoucoEscuro,
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

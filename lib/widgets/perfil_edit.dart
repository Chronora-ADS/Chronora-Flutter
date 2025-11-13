import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/profile_controller.dart';

class ProfileEditModal extends StatefulWidget {
  final User user;
  final VoidCallback onProfileUpdated;

  const ProfileEditModal({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<ProfileEditModal> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final ProfileController _controller = ProfileController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phone);
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
      phone: phoneController.text,
      newPassword:
          newPasswordController.text.isNotEmpty ? newPasswordController.text : null,
      currentPassword:
          currentPasswordController.text.isNotEmpty ? currentPasswordController.text : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      widget.onProfileUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${_controller.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.preto,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Perfil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.branco,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.branco,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              _buildTextField(
                controller: nameController,
                label: 'Nome',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Phone Field
              _buildTextField(
                controller: phoneController,
                label: 'Telefone',
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),

              // Divider - Password Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(child: Container(height: 1, color: AppColors.cinza)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Alterar Senha',
                        style: TextStyle(color: AppColors.cinza, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: AppColors.cinza)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Current Password
              _buildTextField(
                controller: currentPasswordController,
                label: 'Senha atual',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // New Password
              _buildTextField(
                controller: newPasswordController,
                label: 'Nova senha',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildTextField(
                controller: confirmPasswordController,
                label: 'Confirmar nova senha',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.preto),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.branco,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          style: const TextStyle(color: AppColors.branco),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: AppColors.cinza),
            prefixIcon: Icon(icon, color: AppColors.cinza),
            filled: true,
            fillColor: AppColors.cinza.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

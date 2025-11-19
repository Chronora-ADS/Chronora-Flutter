import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/profile_controller.dart';

class PerfilEdit extends StatefulWidget {
  final User user;
  final VoidCallback onProfileUpdated;

  const PerfilEdit({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<PerfilEdit> createState() => _PerfilEditState();
}

class _PerfilEditState extends State<PerfilEdit> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController chronoraController;
  late TextEditingController descricaoController;
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
    phoneController = TextEditingController(text: widget.user.phoneNumber);
    chronoraController = TextEditingController(text: widget.user.timeChronos?.toString() ?? '');
    descricaoController = TextEditingController(text: widget.user.descricao ?? '');
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),

            const Text(
              'Informações Pessoais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.branco,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: nameController,
              label: 'Nome completo',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
              enabled: false,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: phoneController,
              label: 'Telefone',
              icon: Icons.phone,
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: chronoraController,
              label: 'Chronora',
              icon: Icons.workspace_premium,
              keyboardType: TextInputType.number,
              enabled: false,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: descricaoController,
              label: 'Descrição',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            _buildDocumentSection(),
            const SizedBox(height: 32),

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

            _buildTextField(
              controller: currentPasswordController,
              label: 'Senha atual',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: newPasswordController,
              label: 'Nova senha',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: confirmPasswordController,
              label: 'Confirmar nova senha',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 32),

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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chronora',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.branco,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.timeChronos?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.cinza,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.descricao ?? 'Sem descrição',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.cinza,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documento com Foto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.branco,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.cinza.withOpacity(0.1),
            border: Border.all(color: AppColors.cinza),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file,
                size: 40,
                color: AppColors.cinza,
              ),
              const SizedBox(height: 8),
              Text(
                'documento_com_foto_atual X',
                style: TextStyle(
                  color: AppColors.cinza,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.branco),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: AppColors.cinza),
            prefixIcon: Icon(icon, color: AppColors.cinza),
            filled: true,
            fillColor: AppColors.cinza.withOpacity(0.1),
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
      widget.onProfileUpdated();
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
    chronoraController.dispose();
    descricaoController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
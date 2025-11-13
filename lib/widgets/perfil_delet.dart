import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/profile_controller.dart';

class ProfileDeleteModal extends StatefulWidget {
  final VoidCallback onAccountDeleted;

  const ProfileDeleteModal({
    Key? key,
    required this.onAccountDeleted,
  }) : super(key: key);

  @override
  State<ProfileDeleteModal> createState() => _ProfileDeleteModalState();
}

class _ProfileDeleteModalState extends State<ProfileDeleteModal> {
  final ProfileController _controller = ProfileController();
  bool _isLoading = false;

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.preto,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Você deseja mesmo',
                style: TextStyle(
                  color: AppColors.branco,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: const Icon(Icons.close, color: AppColors.branco),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'deletar',
                      style: TextStyle(
                        color: AppColors.branco,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' a sua conta?',
                      style: TextStyle(
                        color: AppColors.branco,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Você perderá todos os seus Chronos e os seus pedidos abertos serão cancelados',
                style: TextStyle(
                  color: AppColors.cinza,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _confirmDelete(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(AppColors.branco),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Deletar Conta',
                            style: TextStyle(
                              color: AppColors.branco,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.branco),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(
                        color: AppColors.branco,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext dialogContext) async {
    setState(() => _isLoading = true);

    final success = await _controller.deleteUserAccount();

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(dialogContext); // Close confirmation dialog
      Navigator.pop(context); // Close delete modal
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta deletada com sucesso')),
      );
      
      // Navigate to login screen
      widget.onAccountDeleted();
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

              // Info Text
              const Text(
                'Bertrania Dude',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'dude@gmail.com',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.cinza,
                ),
              ),
              const SizedBox(height: 24),

              // Delete Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Deletar Conta',
                    style: TextStyle(
                      color: AppColors.branco,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/profile_controller.dart';

class PerfilDelet extends StatefulWidget {
  final User user; // Recebe o usuário logado com todos os dados
  final VoidCallback onAccountDeleted;

  const PerfilDelet({
    Key? key,
    required this.user,
    required this.onAccountDeleted,
  }) : super(key: key);

  @override
  State<PerfilDelet> createState() => _PerfilDeletState();
}

class _PerfilDeletState extends State<PerfilDelet> {
  final ProfileController _controller = ProfileController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletar Conta'),
        backgroundColor: AppColors.preto,
        foregroundColor: AppColors.branco,
        elevation: 0,
      ),
      backgroundColor: AppColors.preto,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Perfil Deletar Conta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.branco,
              ),
            ),
            const SizedBox(height: 24),

            // Chronora Info - Mostra dados reais do usuário
            _buildHeader(),
            const SizedBox(height: 32),

            // User Info - Mostra dados reais do usuário
            _buildUserInfo(),
            const SizedBox(height: 32),

            // Delete Confirmation
            _buildDeleteConfirmation(),
            const SizedBox(height: 32),

            // Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
        // Mostra o Chronora real do usuário
        Text(
          widget.user.chronora ?? '299',
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.cinza,
          ),
        ),
        const SizedBox(height: 8),
        // Mostra a descrição real do usuário
        Text(
          widget.user.descricao ?? 'Pintura de parede, aula de inglês...',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.cinza,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.branco,
          ),
        ),
        const SizedBox(height: 16),
        // Mostra o nome real do usuário
        Text(
          widget.user.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.branco,
          ),
        ),
        const SizedBox(height: 8),
        // Mostra o email real do usuário
        Text(
          widget.user.email,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.cinza,
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Você deseja mesmo deletar a sua conta?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Você perderá todos os seus Chronos e os seus pedidos abertos serão cancelados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.red.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Deletar Conta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.amareloClaro),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Voltar',
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
            onPressed: _isLoading ? null : _deleteAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    'Deletar conta',
                    style: TextStyle(
                      color: AppColors.branco,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
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
      Navigator.pop(dialogContext);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta deletada com sucesso')),
      );
      
      widget.onAccountDeleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${_controller.errorMessage}')),
      );
    }
  }
}
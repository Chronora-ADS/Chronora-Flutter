import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/models/user_model.dart';
import '../core/services/profile_controller.dart';
import '../widgets/perfil_edit.dart';
import '../widgets/perfil_delet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = ProfileController();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    // Verifica se há token salvo; se não houver, redireciona imediatamente para login.
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      });
      return;
    }

    // Se houver token, carrega o perfil normalmente.
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    await _controller.loadUserProfile();
    setState(() {
      _user = _controller.user;
      _isLoading = false;
    });
  }

  void _showEditModal() {
    if (_user == null) return;
    
    showDialog(
      context: context,
      builder: (context) => ProfileEditModal(
        user: _user!,
        onProfileUpdated: _loadUserProfile,
      ),
    );
  }

  void _showDeleteModal() {
    showDialog(
      context: context,
      builder: (context) => ProfileDeleteModal(
        onAccountDeleted: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.preto,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.amareloClaro),
                  ),
                )
              : _user == null
                  ? Center(
                      child: Text(
                        'Erro ao carregar perfil: ${_controller.errorMessage}',
                        style: const TextStyle(
                          color: AppColors.branco,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          const Text(
                            'Perfil',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.branco,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Profile Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.preto,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.amareloClaro.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                _buildInfoField(
                                  label: 'Nome',
                                  value: _user!.name,
                                ),
                                const SizedBox(height: 16),

                                // Email
                                _buildInfoField(
                                  label: 'Email',
                                  value: _user!.email,
                                ),
                                const SizedBox(height: 16),

                                // Phone
                                _buildInfoField(
                                  label: 'Telefone',
                                  value: _user!.phone,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _showEditModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.amareloClaro,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Editar Perfil',
                                    style: TextStyle(
                                      color: AppColors.preto,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _showDeleteModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
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
                            ],
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.cinza,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.branco,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

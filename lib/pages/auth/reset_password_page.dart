import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/auth_session_service.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/backgrounds/background_auth_widget.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? accessToken;

  const ResetPasswordPage({super.key, this.accessToken});

  static String? extractAccessToken(Uri uri) {
    final candidates = <String>[
      uri.query,
      uri.fragment,
      uri.toString(),
    ];

    for (final candidate in candidates) {
      final match =
          RegExp(r'(?:^|[?#&])access_token=([^&#]+)').firstMatch(candidate);
      if (match != null) {
        return Uri.decodeComponent(match.group(1)!);
      }
    }

    return null;
  }

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  late final String? _accessToken;

  @override
  void initState() {
    super.initState();
    _accessToken =
        widget.accessToken ?? ResetPasswordPage.extractAccessToken(Uri.base);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) return 'Nova senha e obrigatoria';
    if (password.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    if (password.length > 72) return 'A senha deve ter ate 72 caracteres';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas nao conferem';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _accessToken;
    if (token == null || token.isEmpty) {
      _showSnackBar('Link de recuperacao invalido ou expirado.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post(
        '/auth/reset-password',
        {'newPassword': _passwordController.text},
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await AuthSessionService.clearSession();
        if (!mounted) return;

        _showSnackBar('Senha redefinida com sucesso. Faca login novamente.');
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      _showSnackBar(_extractErrorMessage(response.body));
    } catch (e) {
      _showSnackBar('Erro ao redefinir senha: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _extractErrorMessage(String body) {
    try {
      final data = json.decode(body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return 'Nao foi possivel redefinir a senha.';
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = _accessToken != null && _accessToken!.isNotEmpty;

    return Scaffold(
      body: BackgroundAuthWidget(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(28),
            ),
            child: hasToken ? _buildResetForm() : _buildInvalidLink(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nova senha',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Crie uma nova senha para acessar sua conta.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            hintText: 'Nova senha',
            controller: _passwordController,
            obscureText: true,
            validator: _validatePassword,
            textInputAction: TextInputAction.next,
          ),
          AuthTextField(
            hintText: 'Confirmar senha',
            controller: _confirmPasswordController,
            obscureText: true,
            validator: _validateConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _resetPassword(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Redefinir senha'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidLink() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Link invalido',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Solicite um novo link de recuperacao de senha.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.forgotPassword,
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloUmPoucoEscuro,
            ),
            child: const Text('Solicitar novo link'),
          ),
        ),
      ],
    );
  }
}

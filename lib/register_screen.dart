// lib/register_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chronora_flutter/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  final String backendBaseUrl = 'http://10.0.2.2:8080';

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.length >= 6;
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail inválido')));
      return;
    }

    if (!_isStrongPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha deve ter no mínimo 6 caracteres')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem')));
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você deve aceitar os termos de serviço')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$backendBaseUrl/api/auth/register');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['token'] as String?;
        final userId = body['userId'];
        final userEmail = body['email'];
        final userName = body['name'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_email', userEmail ?? '');
          await prefs.setString('user_name', userName ?? '');
          await prefs.setInt('user_id', (userId is int) ? userId : int.parse(userId.toString()));

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada com sucesso!')));
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resposta inválida do servidor')));
        }
      } else {
        String message = 'Erro ao criar conta';
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body.containsKey('message')) {
            message = body['message'];
          } else if (body is String) {
            message = body;
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com imagem
          Positioned.fill(
            child: Image.asset(
              'assets/background_login.png',
              fit: BoxFit.cover,
            ),
          ),

          // Logo Chronora no topo
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 20),
            child: Row(
              children: [
                Icon(Icons.hourglass_bottom, color: Colors.black, size: 36),
                const SizedBox(width: 8),
                Text(
                  'Chronora',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Container centralizado
          Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nome
                    TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // E-mail
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Senha
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        helperText: 'Mínimo 6 caracteres',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirmar Senha
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Checkbox de termos
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: _isLoading
                              ? null
                              : (value) => setState(() => _agreedToTerms = value ?? false),
                          activeColor: AppColors.primaryLightYellow,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => setState(() => _agreedToTerms = !_agreedToTerms),
                            child: const Text('Concordo com os Termos de Serviço'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botão Registrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLightYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('Registrar', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Link para login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Já tem conta? '),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            'Faça login',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
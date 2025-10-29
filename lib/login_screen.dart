// lib/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chronora_flutter/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  final String backendBaseUrl = 'http://10.0.2.2:8080'; // Emulador Android

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$backendBaseUrl/api/auth/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['token'] as String?;
        final userId = body['userId'];
        final userEmail = body['email'];
        final name = body['name'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_email', userEmail ?? '');
          await prefs.setString('user_name', name ?? '');
          await prefs.setInt('user_id', (userId is int) ? userId : int.parse(userId.toString()));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login realizado com sucesso')),
          );
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resposta inválida do servidor')),
          );
        }
      } else {
        String message = 'Erro ao autenticar';
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body.containsKey('message')) {
            message = body['message'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

          // Logo Chronora no canto superior esquerdo
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 20),
            child: Row(
              children: [
                // 🔁 Use ícone se não tiver a logo real
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bem vindo!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo E-mail
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Checkbox + "Esqueceu a senha?"
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        activeColor: AppColors.primaryLightYellow,
                      ),
                      const Expanded(child: Text('Lembre-se de mim')),
                      TextButton(
                        onPressed: () {
                          // Navegar para recuperação de senha
                        },
                        child: Text(
                          'Esqueceu a senha?',
                          style: TextStyle(color: AppColors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botão Entrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLightYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('Entrar', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botão Criar conta
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLightYellow,
                        side: BorderSide(color: AppColors.primaryLightYellow, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Criar conta', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
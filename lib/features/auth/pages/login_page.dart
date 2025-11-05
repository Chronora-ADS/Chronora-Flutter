import 'package:chronora/app/routes.dart';
import 'package:chronora/features/auth/pages/account_creation_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/widgets/background_widget.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _saveToken(String token) async {
  try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Token salvo com sucesso!');
    } catch (e) {
      print('Erro ao salvar token: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        final token = response.body;
        
        await _saveToken(token);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso!')),
        );
        
        Navigator.pushReplacementNamed(context, AppRoutes.main);
        print('Token recebido: $token');
      } else {
        final error = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bem vindo de volta!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  AuthTextField(
                    hintText: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  AuthTextField(
                    hintText: 'Senha',
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Checkbox "Lembre-se de mim" e "Esqueceu a senha"
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75 * 0.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: false,
                              onChanged: (value) {
                                // Implementar lembrar de mim
                              },
                            ),
                            const Text(
                              'Lembre-se de mim',
                              style: TextStyle(
                                color: AppColors.preto,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // Navegar para esqueci a senha
                          },
                          child: const Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: AppColors.azul,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botão de Login
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.79 * 0.3,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.branco,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botão de Criar Conta
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.79 * 0.3,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccountCreationPage(),
                                ),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.amareloUmPoucoEscuro,
                          width: 3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Criar Conta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.amareloUmPoucoEscuro,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
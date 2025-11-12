import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/backgrounds/background_auth_widget.dart';
import '../../widgets/auth_text_field.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return BackgroundAuthWidget(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Container(
            width: _getContainerWidth(screenSize.width),
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: _getContainerHeight(screenSize.height),
            ),
            margin: EdgeInsets.all(isMobile ? 16 : 24),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 32,
              vertical: isMobile ? 16 : 24,
            ),
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  AuthTextField(
                    hintText: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isWeb: !isMobile,
                  ),

                  const SizedBox(height: 16),

                  AuthTextField(
                    hintText: 'Senha',
                    controller: _passwordController,
                    obscureText: true,
                    isWeb: !isMobile,
                  ),

                  const SizedBox(height: 20),

                  // CORREÇÃO: Checkbox e "Esqueceu a senha" sempre na mesma linha
                  _buildRememberForgotSection(isMobile),

                  const SizedBox(height: 20),

                  // Botão de Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
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
                          : Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: isMobile ? 22 : 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.branco,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão de Criar Conta
                  SizedBox(
                    width: double.infinity,
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
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Criar Conta',
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 24,
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

  // MÉTODO NOVO: Constroi a seção "Lembre-se de mim" e "Esqueceu a senha"
  Widget _buildRememberForgotSection(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Checkbox "Lembre-se de mim"
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: false,
                onChanged: (value) {
                  // Implementar lembrar de mim
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Lembre-se de mim',
                  style: TextStyle(
                    color: AppColors.preto,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // "Esqueceu a senha"
        Flexible(
          child: TextButton(
            onPressed: () {
              // Navegar para esqueci a senha
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Esqueceu a senha?',
              style: TextStyle(
                color: AppColors.azul,
                fontStyle: FontStyle.italic,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getContainerWidth(double screenWidth) {
    if (screenWidth < 600) return screenWidth * 0.9;
    if (screenWidth < 1200) return screenWidth * 0.7;
    return screenWidth * 0.4;
  }

  double _getContainerHeight(double screenHeight) {
    if (screenHeight < 800) return screenHeight * 0.6;
    return screenHeight * 0.5;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
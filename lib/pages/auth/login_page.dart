import 'dart:convert';

import 'package:chronora/core/constants/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_session_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/backgrounds/background_auth_widget.dart';

class _SubmitLoginIntent extends Intent {
  const _SubmitLoginIntent();
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkEmailConfirmation());
    }
  }

  void _checkEmailConfirmation() {
    final fragment = Uri.base.fragment;
    final params = Uri.splitQueryString(fragment);
    if (params['type'] == 'signup') {
      _showSnackBar('E-mail confirmado com sucesso! Faça login para continuar.');
    }
  }

  Future<void> _loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    setState(() {
      _rememberMe = rememberMe;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    AppSnackBar.show(context, message);
  }

  Future<void> _showEmailNotConfirmedDialog() async {
    final email = _emailController.text.trim();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('E-mail não confirmado'),
        content: const Text(
          'Verifique sua caixa de entrada e clique no link de confirmação antes de fazer login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _resendConfirmation(email);
            },
            child: const Text('Reenviar e-mail'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendConfirmation(String email) async {
    try {
      await ApiService.post('/auth/resend-confirmation', {'email': email});
      _showSnackBar('E-mail de confirmação reenviado. Verifique sua caixa de entrada.');
    } catch (_) {
      _showSnackBar('Nao foi possivel reenviar o e-mail. Tente novamente.');
    }
  }

  String _buildLoginErrorMessage(int statusCode, String body) {
    final extracted = ApiService.extractErrorMessage(
      body,
      fallback: 'Nao foi possivel fazer login.',
    );
    final normalized = extracted.toLowerCase();

    if (statusCode == 401 ||
        normalized.contains('credenciais inv') ||
        normalized.contains('invalid login credentials') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('invalid_grant')) {
      return 'E-mail ou senha errados.';
    }

    return 'Erro no login: $extracted';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is! Map<String, dynamic>) {
          throw Exception('Resposta de login invalida');
        }

        await AuthSessionService.saveSessionFromResponse(responseData);

        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
        } else {
          await prefs.remove('remember_me');
        }

        if (!mounted) return;

        _showSnackBar('Login realizado com sucesso!');
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      } else {
        final errorMessage = ApiService.extractErrorMessage(
          response.body,
          fallback: 'Nao foi possivel fazer login.',
        );
        if (errorMessage.contains('EMAIL_NOT_CONFIRMED')) {
          _showEmailNotConfirmedDialog();
        } else {
          _showSnackBar(_buildLoginErrorMessage(response.statusCode, response.body));
        }
      }
    } catch (e) {
      _showSnackBar('Erro de conexao: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyQ, control: true):
            _SubmitLoginIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SubmitLoginIntent: CallbackAction<_SubmitLoginIntent>(
            onInvoke: (intent) {
              if (!_isLoading) {
                _login();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: BackgroundAuthWidget(
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
                          textInputAction: TextInputAction.next,
                          focusNode: _emailFocus,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          hintText: 'Senha',
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          focusNode: _passwordFocus,
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _login();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildRememberForgotSection(isMobile),
                        const SizedBox(height: 20),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.accountCreation,
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
          ),
        ),
      ),
    );
  }

  Widget _buildRememberForgotSection(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
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
        Flexible(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}

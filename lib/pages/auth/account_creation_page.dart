import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/auth_error_messages.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/backgrounds/background_auth_widget.dart';

class AccountCreationPage extends StatefulWidget {
  const AccountCreationPage({super.key});

  @override
  State<AccountCreationPage> createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  Uint8List? _documentBytes;
  String? _documentName;
  String? _documentMimeType;
  bool _isLoading = false;
  String? _feedbackMessage;
  bool _isFeedbackError = false;

  Future<void> _pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null) return;
      final file = result.files.first;
      final Uint8List bytes;
      if (kIsWeb) {
        if (file.bytes == null) throw Exception('Arquivo vazio');
        bytes = file.bytes!;
      } else {
        bytes = await File(file.path!).readAsBytes();
      }
      setState(() {
        _documentBytes = bytes;
        _documentName = file.name;
        _documentMimeType = _mimeFromExtension(file.extension ?? '');
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Erro ao selecionar arquivo: $e', isError: true);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      setState(() {
        _documentBytes = bytes;
        _documentName = 'documento.jpg';
        _documentMimeType = 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Erro ao tirar foto: $e', isError: true);
    }
  }

  void _showDocumentPicker() {
    if (kIsWeb) {
      _pickFromGallery();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.branco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.amareloUmPoucoEscuro),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: AppColors.amareloUmPoucoEscuro),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _mimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    AppSnackBar.show(context, message, isError: isError);
  }

  void _setFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _feedbackMessage = message;
      _isFeedbackError = isError;
    });
    _showSnackBar(message, isError: isError);
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome e obrigatorio';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail e obrigatorio';
    }
    if (!value.contains('@')) {
      return 'E-mail invalido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone e obrigatorio';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Telefone invalido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha e obrigatoria';
    }
    if (value.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra maiuscula';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Senha deve conter pelo menos um numero';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmacao de senha e obrigatoria';
    }
    if (value != _passwordController.text) {
      return 'Senhas nao coincidem';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_documentBytes == null) {
      _setFeedback('Selecione um documento com foto', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final base64Data = base64Encode(_documentBytes!);

      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': int.parse(phoneDigits),
        'password': _passwordController.text,
        'document': {
          'name': _documentName ?? 'documento.jpg',
          'type': _documentMimeType ?? 'image/jpeg',
          'data': base64Data,
        },
      };

      final response = await ApiService.post('/auth/register', payload);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _setFeedback(
          'Cadastro realizado com sucesso!',
          isError: false,
        );
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        final message = resolveRegistrationErrorMessage(
          response.statusCode,
          response.body,
        );
        _setFeedback('Erro no cadastro: $message', isError: true);
      }
    } catch (e) {
      _setFeedback('Erro: $e', isError: true);
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
    return BackgroundAuthWidget(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    'Bem vindo!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  AuthTextField(
                    hintText: 'Nome completo',
                    controller: _nameController,
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                    focusNode: _nameFocus,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_emailFocus);
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hintText: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                    focusNode: _emailFocus,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_phoneFocus);
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hintText: 'Numero de celular (com DDD)',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    inputFormatters: const [_BrazilianPhoneInputFormatter()],
                    textInputAction: TextInputAction.next,
                    focusNode: _phoneFocus,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hintText: 'Senha',
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                    textInputAction: TextInputAction.next,
                    focusNode: _passwordFocus,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_confirmPasswordFocus);
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hintText: 'Confirmar Senha',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                    focusNode: _confirmPasswordFocus,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _submitForm();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showDocumentPicker,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.amareloUmPoucoEscuro,
                          width: 3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Documento com foto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amareloUmPoucoEscuro,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/img/Import.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_documentName != null) ...{
                    const SizedBox(height: 10),
                    Text(
                      _documentName!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  },
                  if (_feedbackMessage != null) ...{
                    const SizedBox(height: 16),
                    _FormFeedbackMessage(
                      message: _feedbackMessage!,
                      isError: _isFeedbackError,
                    ),
                  },
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Criar Conta',
                              style: TextStyle(
                                fontSize: 18,
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
                              Navigator.pop(context);
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.amareloUmPoucoEscuro,
                          width: 3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 18,
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }
}

class _FormFeedbackMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _FormFeedbackMessage({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.vermelho : AppColors.amareloUmPoucoEscuro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BrazilianPhoneInputFormatter extends TextInputFormatter {
  const _BrazilianPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < limited.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

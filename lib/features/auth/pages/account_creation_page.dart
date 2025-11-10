import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/background_auth_widget.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class AccountCreationPage extends StatefulWidget {
  const AccountCreationPage({super.key});

  @override
  _AccountCreationPageState createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _fileName;
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          _fileName = _pickedFile!.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  Future<String> _convertToBase64(PlatformFile file) async {
    if (kIsWeb) {
      // Para Web - usa os bytes diretamente
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Arquivo vazio');
      String base64String = base64Encode(bytes);
      return base64String;
    } else {
      // Para Mobile - usa o arquivo do sistema de arquivos
      final file = File(_pickedFile!.path!);
      List<int> fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);
      return base64String;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail é obrigatório';
    }
    if (!value.contains('@')) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Telefone inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != _passwordController.text) {
      return 'Senhas não coincidem';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um documento com foto')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String base64Data = await _convertToBase64(_pickedFile!);

      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      
      final payload = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phoneNumber": int.parse(phoneDigits),
        "password": _passwordController.text,
        "confirmPassword": _confirmPasswordController.text,
        "document": {
          "name": _pickedFile!.name,
          "type": _pickedFile!.extension ?? 'jpg', // Fallback para web
          "data": base64Data
        }
      };

      print('Enviando payload para cadastro...');
      final response = await ApiService.post('/auth/register', payload);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        Navigator.pop(context);
      } else {
        final error = response.body;
        print('Erro do servidor: ${response.statusCode} - $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no cadastro: ${response.statusCode} - $error')),
        );
      }
    } catch (e) {
      print('Erro no cadastro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
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
          padding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Vertical reduzido
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
                  const SizedBox(height: 20), // Aumentado de 12 para 20
                  
                  AuthTextField(
                    hintText: 'Nome completo',
                    controller: _nameController,
                    validator: _validateName,
                  ),
                  
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'Número de celular',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'Senha',
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'Confirmar Senha',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: _validateConfirmPassword,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botão para anexar documento - ALTURA REDUZIDA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _pickFile,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.amareloUmPoucoEscuro,
                          width: 3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, // Reduzido de 20
                          vertical: 10, // Reduzido de 12
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Documento com foto',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: AppColors.amareloUmPoucoEscuro,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8), // Reduzido de 10
                          Image.asset(
                            'assets/img/Import.png',
                            width: 32, // Reduzido de 40
                            height: 32, // Reduzido de 40
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (_fileName != null) ...{
                    const SizedBox(height: 8), // Reduzido de 10
                    Text(
                      _fileName!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  },
                  
                  const SizedBox(height: 12),
                  
                  // Botão de criar conta - ALTURA REDUZIDA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro,
                        padding: const EdgeInsets.symmetric(vertical: 10), // Reduzido de 16
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
                              'Criar Conta',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: AppColors.branco,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 12), // Aumentado de 8 para 12
                  
                  // Botão de voltar para login - ALTURA REDUZIDA
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
                        padding: const EdgeInsets.symmetric(vertical: 10), // Reduzido de 16
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Voltar para Login',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context),
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

  // Função para tamanho de fonte responsivo - AJUSTADA
  double _getResponsiveFontSize(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    if (width < 350) return 18;
    if (width < 400) return 20;
    return 22;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
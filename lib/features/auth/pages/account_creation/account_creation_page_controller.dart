import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../app/routes.dart';

class AccountCreationPageController {
	final nameCtrl     = TextEditingController();
	final emailCtrl    = TextEditingController();
	final phoneCtrl    = TextEditingController();
	final passCtrl     = TextEditingController();
	final confirmCtrl  = TextEditingController();
	final formKey      = GlobalKey<FormState>();

	PlatformFile? pickedFile;
	String? fileName;
	bool isLoading = false;

	// Validações
	String? validateName(String? v) => (v == null || v.isEmpty) ? 'Nome é obrigatório' : null;

	String? validateEmail(String? v) {
		if (v == null || v.isEmpty) return 'E-mail obrigatório';
		return v.contains('@') ? null : 'E-mail inválido';
	}

	String? validatePhone(String? v) {
		if (v == null || v.isEmpty) return 'Telefone obrigatório';
		final digits = v.replaceAll(RegExp(r'\D'), '');
		return digits.length >= 10 ? null : 'Telefone inválido';
	}

	String? validatePass(String? v) {
		if (v == null || v.isEmpty) return 'Senha obrigatória';
		return v.length >= 6 ? null : 'Mínimo 6 caracteres';
	}

	String? validateConfirm(String? v) {
		if (v == null || v.isEmpty) return 'Confirme a senha';
		return v == passCtrl.text ? null : 'Senhas não coincidem';
	}

	Future<void> pickFile(BuildContext context) async {
		try {
			final result = await FilePicker.platform.pickFiles(
				type: FileType.custom,
				allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
			);
			if (result != null) {
				pickedFile = result.files.first;
				fileName   = pickedFile!.name;
			} catch (e) {
				ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Erro ao selecionar arquivo: $e')));
			}
		}
	}

	Future<String> fileToBase64() async {
		if (kIsWeb) {
			final bytes = pickedFile!.bytes;
			if (bytes == null) throw Exception('Arquivo vazio');
			return base64Encode(bytes);
		} else {
			final file = File(pickedFile!.path!);
			return base64Encode(await file.readAsBytes());
		}
	}

	Future<void> criarConta(BuildContext context) async {
		if (!formKey.currentState!.validate()) return;
		if (pickedFile == null) {
			ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um documento com foto')));
			return;
		}

		isLoading = true;
		try {
			final base64   = await fileToBase64();
			final phoneDig = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

			final payload = {
				"name": nameCtrl.text.trim(),
				"email": emailCtrl.text.trim(),
				"phoneNumber": int.parse(phoneDig),
				"password": passCtrl.text,
				"confirmPassword": confirmCtrl.text,
				"document": {
				"name": pickedFile!.name,
				"type": pickedFile!.extension ?? 'jpg',
				"data": base64
				}
			};

			final resp = await ApiService.post('/auth/register', payload);

			if (resp.statusCode == 200) {
				final prefs = await SharedPreferences.getInstance();
				await prefs.setString('auth_token', resp.body);

				if (context.mounted) {
					ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro realizado com sucesso!')));
					Navigator.pushReplacementNamed(context, AppRoutes.main);
				}
			} else {
				if (context.mounted) {
					ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no cadastro: ${resp.body}')));
				}
			}
		} catch (e) {
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Erro: $e')));
			}
		} finally {
			isLoading = false;
		}
	}

	void dispose() {
		nameCtrl.dispose();
		emailCtrl.dispose();
		phoneCtrl.dispose();
		passCtrl.dispose();
		confirmCtrl.dispose();
	}
}
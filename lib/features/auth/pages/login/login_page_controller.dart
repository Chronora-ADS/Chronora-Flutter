import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../app/routes.dart';

class LoginPageController {
	final TextEditingController emailCtrl = TextEditingController();
	final TextEditingController passCtrl  = TextEditingController();
	final formKey = GlobalKey<FormState>();
	bool isLoading = false;

	// Validações
	String? validateEmail(String? v) => (v == null || v.isEmpty) ? 'E-mail obrigatório' : null;

	String? validatePass(String? v) => (v == null || v.isEmpty) ? 'Senha obrigatória' : null;

	Future<void> login(BuildContext context) async {
		if (!formKey.currentState!.validate()) return;

		isLoading = true;
		try {
		final resp = await ApiService.post('/auth/login', {
			'email': emailCtrl.text.trim(),
			'password': passCtrl.text,
		});

		if (resp.statusCode == 200) {
			final prefs = await SharedPreferences.getInstance();
			await prefs.setString('auth_token', resp.body);

			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Login realizado com sucesso!')),
				);
				Navigator.pushReplacementNamed(context, AppRoutes.main);
			}
		} else {
			if (context.mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Erro no login: ${resp.body}')),
				);
			}
		}
		} catch (e) {
		if (context.mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Erro de conexão: $e')),
			);
		}
		} finally {
			isLoading = false;
		}
	}

	void dispose() {
		emailCtrl.dispose();
		passCtrl.dispose();
	}
}
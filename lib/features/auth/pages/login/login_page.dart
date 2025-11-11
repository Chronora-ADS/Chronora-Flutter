import 'package:flutter/material.dart';
import 'login_page_controller.dart';
import 'login_page_style.dart';
import '../../../../shared/widgets/background_auth_widget.dart';
import '../widgets/auth_text_field.dart';
import 'account_creation_page.dart';

class LoginPage extends StatefulWidget {
	const LoginPage({super.key});
	@override
	State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
	final ctrl = LoginPageController();

	@override
	void dispose() {
		ctrl.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return BackgroundWidget(
			child: Center(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(16),
					child: Container(
						width: MediaQuery.of(context).size.width * .9,
						constraints: const BoxConstraints(maxWidth: 400),
						margin: const EdgeInsets.all(16),
						padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
						decoration: BoxDecoration(
							color: LoginPageStyle.fundoCartao,
							borderRadius: BorderRadius.circular(LoginPageStyle.borderRadius),
						),
						child: Form(
							key: ctrl.formKey,
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									Text('Bem vindo de volta!', style: LoginPageStyle.titulo),
									const SizedBox(height: 30),
									AuthTextField(
										hintText: 'E-mail',
										controller: ctrl.emailCtrl,
										keyboardType: TextInputType.emailAddress,
										validator: ctrl.validateEmail,
									),
									const SizedBox(height: 16),
									AuthTextField(
										hintText: 'Senha',
										controller: ctrl.passCtrl,
										obscureText: true,
										validator: ctrl.validatePass,
									),
									const SizedBox(height: 20),
									_lembrarEsqueci(),
									const SizedBox(height: 20),
									SizedBox(
										width: double.infinity,
										child: ElevatedButton(
										style: LoginPageStyle.primario,
										onPressed: ctrl.isLoading ? null : () => ctrl.login(context),
										child: ctrl.isLoading
											? const SizedBox(
												width: 20, height: 20,
												child: CircularProgressIndicator(strokeWidth: 2,
												valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
											: Text('Entrar', style: LoginPageStyle.textoPrimario),
										),
									),
									const SizedBox(height: 16),
									SizedBox(
										width: double.infinity,
										child: OutlinedButton(
										style: LoginPageStyle.secundario,
										onPressed: ctrl.isLoading
											? null
											: () => Navigator.push(
												context,
												MaterialPageRoute(
													builder: (_) => const AccountCreationPage())),
										child: Text('Criar Conta', style: LoginPageStyle.textoSecundario),
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

	Widget _lembrarEsqueci() {
		return LayoutBuilder(
		builder: (_, c) {
			final small = c.maxWidth < 300;
			return small
				? Column(
					children: [
					_checkRow(),
					const SizedBox(height: 8),
					_esqueciBtn(),
					],
				)
				: Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [Flexible(child: _checkRow()), _esqueciBtn()],
				);
		},
		);
	}

	Widget _checkRow() => Row(
			children: [
			Checkbox(value: false, onChanged: (_) {}, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
			const SizedBox(width: 4),
			const Flexible(child: Text('Lembre-se de mim', style: LoginPageStyle.lembrete)),
			],
		);

	Widget _esqueciBtn() => TextButton(
			onPressed: () {},
			child: const Text('Esqueceu a senha?', style: LoginPageStyle.esqueci),
		);
}
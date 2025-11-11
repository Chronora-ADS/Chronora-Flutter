import 'package:flutter/material.dart';
import 'account_creation_page_controller.dart';
import 'account_creation_page_style.dart';
import '../../../../shared/widgets/background_auth_widget.dart';
import '../widgets/auth_text_field.dart';

class AccountCreationPage extends StatefulWidget {
	const AccountCreationPage({super.key});
	@override
	State<AccountCreationPage> createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
	final ctrl = AccountCreationPageController();

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
						color: AccountCreationPageStyle.fundoCartao,
						borderRadius: BorderRadius.circular(
							AccountCreationPageStyle.borderRadius),
						),
						child: Form(
							key: ctrl.formKey,
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									Text('Bem vindo!', style: AccountCreationPageStyle.titulo),
									const SizedBox(height: 30),
									AuthTextField(
										hintText: 'Nome completo',
										controller: ctrl.nameCtrl,
										validator: ctrl.validateName,
									),
									const SizedBox(height: 16),
									AuthTextField(
										hintText: 'E-mail',
										controller: ctrl.emailCtrl,
										keyboardType: TextInputType.emailAddress,
										validator: ctrl.validateEmail,
									),
									const SizedBox(height: 16),
									AuthTextField(
										hintText: 'Número de celular (com DDD)',
										controller: ctrl.phoneCtrl,
										keyboardType: TextInputType.phone,
										validator: ctrl.validatePhone,
									),
									const SizedBox(height: 16),
									AuthTextField(
										hintText: 'Senha',
										controller: ctrl.passCtrl,
										obscureText: true,
										validator: ctrl.validatePass,
									),
									const SizedBox(height: 16),
									AuthTextField(
										hintText: 'Confirmar Senha',
										controller: ctrl.confirmCtrl,
										obscureText: true,
										validator: ctrl.validateConfirm,
									),
									const SizedBox(height: 20),
									// Anexo
									SizedBox(
										width: double.infinity,
										child: OutlinedButton(
											style: AccountCreationPageStyle.outlinedAnexo,
											onPressed: () => ctrl.pickFile(context).then((_) => setState(() {})),
											child: Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													Expanded(
														child: Text(
															'Documento com foto',
															style: AccountCreationPageStyle.textoAnexo,
															overflow: TextOverflow.ellipsis,
														),
													),
													Image.asset('assets/img/Import.png', width: 24, height: 24),
												],
											),
										),
									),
									if (ctrl.fileName != null) ...[
										const SizedBox(height: 10),
										Text(ctrl.fileName!, style: AccountCreationPageStyle.nomeArquivo),
									],
									const SizedBox(height: 16),
									// Criar Conta
									SizedBox(
										width: double.infinity,
										child: ElevatedButton(
										style: AccountCreationPageStyle.primario,
										onPressed: ctrl.isLoading
											? null
											: () => ctrl.criarConta(context).then((_) => setState(() {})),
										child: ctrl.isLoading
											? const SizedBox(
												width: 20, height: 20,
												child: CircularProgressIndicator(
													strokeWidth: 2,
													valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
											: Text('Criar Conta', style: AccountCreationPageStyle.textoPrimario),
										),
									),
									const SizedBox(height: 16),
									// Voltar
									SizedBox(
										width: double.infinity,
										child: OutlinedButton(
											style: AccountCreationPageStyle.secundario,
											onPressed: ctrl.isLoading
												? null
												: () => Navigator.pop(context),
											child: Text('Entrar', style: AccountCreationPageStyle.textoSecundario),
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
}
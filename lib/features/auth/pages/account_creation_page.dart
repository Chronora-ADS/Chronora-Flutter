@ -175,14 +175,15 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
    return BackgroundWidget(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 400,
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Vertical reduzido
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(40),
@ -200,51 +201,57 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 20), // Aumentado de 12 para 20
                  
                  AuthTextField(
                    hintText: 'Nome completo',
                    controller: _nameController,
                    validator: _validateName,
                  ),
                  
                  const SizedBox(height: 16),
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  
                  const SizedBox(height: 16),
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'Número de celular (com DDD)',
                    hintText: 'Número de celular',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  
                  const SizedBox(height: 16),
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'Senha',
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  
                  const SizedBox(height: 16),
                  const SizedBox(height: 12), // Aumentado de 4 para 12
                  
                  AuthTextField(
                    hintText: 'Confirmar Senha',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: _validateConfirmPassword,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botão para anexar documento
                  // Botão para anexar documento - ALTURA REDUZIDA
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.79 * 0.3,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _pickFile,
                      style: OutlinedButton.styleFrom(
@ -253,8 +260,8 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                          width: 3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                          horizontal: 16, // Reduzido de 20
                          vertical: 10, // Reduzido de 12
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
@ -263,22 +270,22 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                          Expanded(
                            child: Text(
                              'Documento com foto',
                              style: TextStyle(
                                fontSize: 22,
                                fontSize: _getResponsiveFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: AppColors.amareloUmPoucoEscuro,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const SizedBox(width: 8), // Reduzido de 10
                          Image.asset(
                            'assets/img/Import.png',
                            width: 40,
                            height: 40,
                            width: 32, // Reduzido de 40
                            height: 32, // Reduzido de 40
                          ),
                        ],
                      ),
@ -286,7 +293,7 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                  ),
                  
                  if (_fileName != null) ...{
                    const SizedBox(height: 10),
                    const SizedBox(height: 8), // Reduzido de 10
                    Text(
                      _fileName!,
                      style: const TextStyle(
@ -294,19 +301,21 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  },
                  
                  const SizedBox(height: 30),
                  const SizedBox(height: 12),
                  
                  // Botão de criar conta
                  // Botão de criar conta - ALTURA REDUZIDA
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.79 * 0.3,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(vertical: 10), // Reduzido de 16
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
@ -320,10 +329,10 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                          : Text(
                              'Criar Conta',
                              style: TextStyle(
                                fontSize: 22,
                                fontSize: _getResponsiveFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: AppColors.branco,
                              ),
@ -331,11 +340,11 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const SizedBox(height: 12), // Aumentado de 8 para 12
                  
                  // Botão de voltar para login
                  // Botão de voltar para login - ALTURA REDUZIDA
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.79 * 0.3,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
@ -347,15 +356,15 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
                          color: AppColors.amareloUmPoucoEscuro,
                          width: 3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.symmetric(vertical: 10), // Reduzido de 16
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                      child: Text(
                        'Voltar para Login',
                        style: TextStyle(
                          fontSize: 22,
                          fontSize: _getResponsiveFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: AppColors.amareloUmPoucoEscuro,
                        ),
@ -371,6 +380,15 @@ class _AccountCreationPageState extends State<AccountCreationPage> {
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

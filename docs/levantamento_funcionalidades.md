# Levantamento de Funcionalidades — Chronora Flutter

> Gerado em: 2026-06-11

---

## Autenticação

### Login
- **Arquivo:** `lib/pages/auth/login_page.dart`
- ✅ Formulário com email/senha, integração com API, redirecionamento para main

### Criar Conta
- **Arquivo:** `lib/pages/auth/account_creation_page.dart`
- ✅ Validação completa de campos (nome, email, telefone, senha)
- ✅ Upload e conversão de documento para Base64
- ✅ Chamada API `POST /auth/register`
- ✅ Tratamento de erro (409 para email/telefone duplicados)
- ✅ Formatação de telefone brasileiro

### Esqueceu Senha
- **Arquivo:** `lib/pages/auth/forgot_password_page.dart`
- ✅ Validação de email
- ✅ Chamada API `POST /auth/forgot-password`
- ✅ Construção dinâmica da URL de redirecionamento

### Resetar Senha
- **Arquivo:** `lib/pages/auth/reset_password_page.dart`
- ✅ Validação de senha (6-72 caracteres)
- ✅ Extração de token via URL (query/fragment)
- ✅ Chamada API `POST /auth/reset-password`
- ✅ Limpeza de sessão após sucesso

---

## Catálogo e Filtros

### Página Principal
- **Arquivo:** `lib/pages/main_page.dart`
- ✅ Listagem de serviços com paginação
- ✅ Busca em tempo real
- ✅ Filtros avançados: categoria, modalidade, deadline, tempo, avaliação
- ✅ Side menu e wallet modal

---

## Pedidos / Serviços

### Meus Pedidos
- **Arquivo:** `lib/pages/requests/my_requests.dart`
- ✅ Carregamento via `GET /service/get/all`
- ✅ Filtro por status: CRIADO, ACEITO, EM_ANDAMENTO, CONCLUÍDO, CANCELADO
- ✅ Busca de pedidos
- ✅ Navegação para edição e visualização

### Criar Pedido
- **Arquivo:** `lib/pages/requests/request-creator-editor/request_creation.dart`
- ✅ Formulário completo com validação
- ✅ Upload de imagem convertida para Base64
- ✅ Seleção de categoria com tags
- ✅ Seleção de modalidade
- ✅ Validação de data e Chronos
- ✅ Chamada `POST /service/post`
- ⚠️ Campo de imagem: validação diz obrigatório mas comportamento inconsistente

### Editar Pedido
- **Arquivo:** `lib/pages/requests/request-creator-editor/request_edit.dart`
- ✅ Carregamento de dados do pedido via API
- ✅ Preenchimento automático do formulário
- ✅ Validação completa
- ✅ Chamada `PUT /service/put`
- ⚠️ Código duplicado na linha 281 (`if (!mounted) return;` duplo)
- ⚠️ Validar se endpoint `PUT /service/put` existe no backend

### Visualizar Pedido
- **Arquivo:** `lib/pages/requests/request_view.dart`
- ✅ Carregamento detalhado via `GET /service/get/$serviceId`
- ✅ Aceitação de pedido (`PUT /service/acceptService/$serviceId`)
- ✅ Cancelamento de pedido (`DELETE /service/cancelService/$serviceId`)
- ✅ Redirecionamento automático para tela de andamento quando EM_ANDAMENTO
- ✅ Exibição de código de autenticação e countdown
- ⚠️ Rating hardcoded (5.0) — não vem do backend

### Pedido Aceito (aguardando início)
- **Arquivo:** `lib/pages/requests/request_accepted_view.dart`
- ✅ Sincronização em tempo real de status (polling a cada 3s)
- ✅ Countdown do código de autenticação (2 minutos)
- ✅ Dialog para iniciar pedido com validação de código
- ✅ Chamada `PUT /service/startService/$serviceId` com código
- ✅ Tratamento de expiração automática do código

### Pedido em Andamento
- **Arquivo:** `lib/pages/requests/order_in_progress_page.dart`
- ✅ Polling de status a cada 5s
- ✅ Botão **"Concluir"** para prestador / **"Finalizar pedido"** para solicitante
- ✅ Botão do solicitante bloqueado até o prestador concluir
- ✅ Banner verde ao aguardar confirmação
- ✅ Chamada `PUT /service/finishService/$id` e `PUT /service/cancelService/$id`
- ✅ Redirecionamento automático ao concluir/cancelar

---

## Carteira (Chronos)

### Comprar Chronos
- **Arquivo:** `lib/pages/buy_chronos/buy_chronos_page.dart`
- ✅ Formulário com cálculo em tempo real
- ✅ Validação de limite máximo (300 Chronos)
- ✅ Integração com Mercado Pago

### PIX Compra
- **Arquivo:** `lib/pages/buy_chronos/pix_buy_page.dart`
- ✅ Exibição de QR Code (`qr_flutter`)
- ✅ Countdown de expiração
- ✅ Polling de status de pagamento a cada 3s
- ✅ Cópia do código PIX
- ✅ Redirecionamento automático ao confirmar pagamento

### Sucesso Compra
- **Arquivo:** `lib/pages/buy_chronos/buy_success_page.dart`
- ✅ Exibição dos detalhes da transação
- ✅ Cálculo de taxa (10%)
- ✅ Botões de voltar e nova compra

### Vender Chronos
- **Arquivo:** `lib/pages/sell_chronos/sell_chronos_page.dart`
- ✅ Formulário de venda (R$ 2/Chronos)
- ✅ Taxa de 10% calculada
- ✅ Validação de saldo mínimo

### PIX Venda
- **Arquivo:** `lib/pages/sell_chronos/pix_sell_page.dart`
- ✅ Validação de chave PIX (CPF, email, telefone, chave aleatória)
- ✅ Exibição de resumo da venda com taxa
- ✅ Chamada via `ChronosWalletService`
- ✅ Navegação para tela de sucesso
- ⚠️ Erro na chamada não restaura visual do spinner (`_isProcessing` não é resetado no catch)

### Sucesso Venda
- **Arquivo:** `lib/pages/sell_chronos/sell_success_page.dart`
- ✅ Exibição de confirmação com detalhes
- ✅ Formatação de chave PIX (caracteres ocultados)
- ✅ Prazo de 2 dias úteis informado
- ✅ Navegação para voltar/nova venda

---

## Perfil e Notificações

### Perfil
- **Arquivo:** `lib/pages/profile_page.dart`
- ✅ Carregamento via `ProfileController`
- ✅ Edição de nome, email, telefone
- ✅ Mudança de senha com validação
- ✅ Upload de documento e foto de perfil
- ✅ Deletar conta com confirmação

### Notificações
- **Arquivo:** `lib/pages/notification/notification_page.dart`
- ✅ Carregamento via `GET /notification/get/all`
- ✅ Renovação de prazo com date picker
- ✅ Cancelamento de pedido pela notificação
- ✅ Navegação para detalhe do pedido

---

## Utilitários

### Coming Soon (placeholder)
- **Arquivo:** `lib/pages/placeholder/coming_soon_page.dart`
- ✅ Placeholder para futuras funcionalidades (ex: Configurações)

---

## Serviços Core (`lib/core/services/`)

| Serviço | Responsabilidade |
|---|---|
| `api_service.dart` | Chamadas HTTP, autenticação via token |
| `auth_session_service.dart` | Gestão de sessão e tokens |
| `service_catalog_service.dart` | Busca e paginação de serviços |
| `chronos_wallet_service.dart` | Saldo, compra e venda de Chronos |
| `profile_controller.dart` | Dados do usuário logado |
| `deadline_controller.dart` | Notificações de prazo |

---

## Widgets Reutilizáveis (`lib/widgets/`)

`Header` · `SideMenu` · `WalletModal` · `ServiceCard` · `NotificationCard` · `AuthTextField` · `FiltersModal` · `ProfileEdit` · `BackgroundAuth` · `BackgroundDefault` · `AuthGuard`

---

## Resumo Geral

| Área | Status |
|---|---|
| Autenticação | ✅ Completo |
| Catálogo e filtros | ✅ Completo |
| Carteira Chronos (compra/venda) | ✅ Completo |
| Fluxo de pedidos ponta a ponta | ✅ Completo |
| Perfil | ✅ Completo |
| Notificações | ✅ Completo |

### Pontos de atenção (não críticos)
- Rating de serviços hardcoded (5.0) — precisaria vir do backend quando sistema de avaliação for implementado
- Validação de imagem na criação de pedido inconsistente
- Spinner da venda PIX não é resetado em caso de erro
- Código duplicado em `request_edit.dart` linha 281

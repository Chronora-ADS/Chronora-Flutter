# Handoff Front -> Backend (Chronora)

Este arquivo resume **o que o backend precisa ajustar/garantir** para ficar 100% alinhado com o que já está implementado no Flutter.

> Escopo: mudanças de autenticação, catálogo/serviços, modalidades, paginação, imagem, e monitoramento/logs.

---

## 1) Autenticação

### 1.1 Login
- **Endpoint:** `POST /auth/login`
- **Request (front):**

```json
{
  "email": "user@email.com",
  "password": "senha"
}
```

- **Response esperada (200):**

```json
{
  "access_token": "jwt"
}
```

> O app usa a chave `access_token` para persistir sessão (`auth_token` local).

### 1.2 Cadastro
- **Endpoint:** `POST /auth/register`
- **Request (front):**

```json
{
  "name": "Nome Completo",
  "email": "user@email.com",
  "phoneNumber": 5511999999999,
  "password": "senha",
  "confirmPassword": "senha",
  "document": {
    "name": "arquivo.jpg",
    "type": "jpg",
    "data": "BASE64_SEM_PREFIXO"
  }
}
```

- **Contrato esperado:**
  - `200` sucesso de cadastro.
  - `409` para duplicidade de e-mail/telefone (front já trata esta resposta).
  - Garantir consistência transacional (não deixar auth órfão se perfil falhar).

### 1.3 Sessão persistida (auth gate)
- **Endpoint usado para validar sessão no app:** `GET /user/get` (com Bearer token).
- **Esperado:**
  - `200` token válido.
  - `401`/`403` token inválido/expirado.

### 1.4 Esqueci a senha
- **Endpoint:** `POST /auth/forgot-password`
- **Request:**

```json
{
  "email": "user@email.com"
}
```

- **Status aceitos pelo app como sucesso:** `200`, `202` ou `204`.

---

## 2) Usuário

### 2.1 Perfil/resumo do usuário
- **Endpoint:** `GET /user/get`
- **Campos que o app consome:**
  - nome (`name`)
  - avaliação do usuário (`rating`, numérico)
  - foto de perfil (`profileImage`/`photoUrl`, recomendado padronizar um nome só)
  - saldo de Chronos (se existir no payload atual)

> Recomendação: padronizar chaves e manter tipos consistentes (`rating` numérico).

### 2.2 Compra e venda de Chronos (fluxo atual)
- **Compra:** `PUT /user/put/buy-chronos`
- **Venda:** `PUT /user/put/sell-chronos`
- **Auth:** Bearer token no header.

> Observação: no futuro esse fluxo deve migrar para pagamentos assíncronos com provider (Stripe/MP) e webhook.

---

## 3) Serviços (catálogo, criação, edição, detalhe)

### 3.1 Listagem com paginação
- **Endpoint:** `GET /service/get/all`
- **Query params usados pelo app:**
  - `page`
  - `size`
  - (filtros opcionais que já existirem no backend)

- **Formato de resposta aceito pelo front (compatível):**
  - lista direta `[]`
  - ou envelope com `services`, `data` ou `content`.

> Recomendado padronizar em um único formato paginado.

### 3.2 Criação
- **Endpoint:** `POST /service/post`
- **Campos relevantes enviados:**
  - `title`, `description`, `timeChronos`, `deadline`
  - `modality` (ver seção 4)
  - categorias (`categories`)
  - imagem (`serviceImage` em base64 quando houver)

### 3.3 Edição
- **Endpoint:** `PUT /service/put`
- **Payload atual enviado pelo front:**
  - `id`, `title`, `description`, `timeChronos`, `modality`, `deadline`
  - `categories: List<String>`
  - `categoryEntities: List<{ "name": string }>` (compatibilidade)
  - `serviceImage` (base64 opcional)

> O front envia **`categories` e `categoryEntities` juntos** por compatibilidade de versões.
> Backend deve padronizar 1 contrato definitivo para remover duplicidade no app.

### 3.4 Detalhe do serviço
- **Endpoint:** `GET /service/get/{id}`
- **Campos importantes para o app:**
  - `id`, `title`, `description`, `timeChronos`, `deadline`, `modality`
  - imagem: `serviceImage` **ou** `serviceImageUrl`
  - categorias: `categoryEntities` **ou** `categories`

---

## 4) Modalidade (padronização obrigatória)

No front foi centralizado:
- UI: `Presencial`, `Remoto`, `Híbrido`
- Backend esperado:
  - `PRESENCIAL`
  - `REMOTO`
  - `HIBRIDO` (sem acento)

Também há tolerância no parse para retorno `HÍBRIDO` (com acento), mas o recomendado é padronizar para `HIBRIDO`.

---

## 5) Imagens (serviço e perfil)

O app já tolera:
- URL (`http://` / `https://`)
- Base64 puro
- Data URI (`data:image/...;base64,...`)

### Recomendação backend
- Padronizar 1 campo principal para serviço (`serviceImageUrl` **ou** `serviceImage`) e manter documentação estável.
- Evitar variar tipo do mesmo campo entre registros.

---

## 6) Monitoramento e logs (Better Stack)

### 6.1 Health check
- **Endpoint:** `GET /health`
- Deve responder `200` quando aplicação estiver saudável.

### 6.2 Relay de logs do app
- **Endpoint:** `POST /monitoring/client-logs`
- Payload enviado pelo Flutter:

```json
{
  "level": "error",
  "source": "flutter_error | platform_dispatcher | run_zoned_guarded",
  "message": "texto do erro",
  "stackTrace": "stack opcional",
  "platform": "android|ios|web|...",
  "isReleaseMode": true,
  "timestamp": "ISO-8601",
  "context": {}
}
```

- **Response recomendada:** `202 Accepted` (ou `200`).
- Backend deve reenviar ao Better Stack com token secreto (não expor token no app).

> Detalhes operacionais no arquivo: `docs/backend/monitoring_better_stack_contract.md`.

---

## 7) Checklist de aceite para backend

- [ ] `POST /auth/login` retorna `access_token`.
- [ ] `POST /auth/register` responde `409` para duplicidade.
- [ ] `GET /user/get` funciona para auth gate e perfil.
- [ ] `POST /auth/forgot-password` ativo (`200/202/204`).
- [ ] `GET /service/get/all` suporta `page` e `size`.
- [ ] `PUT /service/put` aplica corretamente alteração de categorias.
- [ ] Contrato de modalidade padronizado (`PRESENCIAL|REMOTO|HIBRIDO`).
- [ ] Campos de imagem de serviço padronizados.
- [ ] `GET /health` publicado no ambiente de deploy.
- [ ] `POST /monitoring/client-logs` publicado e relaying para Better Stack.

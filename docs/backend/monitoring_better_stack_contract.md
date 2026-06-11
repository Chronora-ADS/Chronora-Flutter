# Monitoramento + Better Stack (contrato backend)

Este documento define o contrato mínimo que o backend precisa expor para suportar:

1. **Health check no Better Stack (Uptime)**.
2. **Relay de logs de erro do app Flutter para Better Stack Logs**.

## 1) Health check para deploy

### Endpoint
- `GET /health`

### Resposta esperada
- **200 OK** quando a aplicação e dependências essenciais estiverem operacionais.

Exemplo:

```json
{
  "status": "ok",
  "service": "chronora-api",
  "version": "1.0.0",
  "timestamp": "2026-04-10T00:00:00Z"
}
```

### Configuração no Better Stack
- Criar monitor HTTP apontando para `https://SEU_BACKEND/health`.
- Intervalo recomendado: `30s` ou `1m`.
- Alertas: e-mail + Slack/Telegram (opcional).

## 2) Relay de logs do cliente (Flutter -> Backend -> Better Stack)

> O app Flutter envia logs para o backend. O backend reenviará para Better Stack.
> Assim, tokens de ingestão não ficam expostos no cliente.

### Endpoint de entrada (backend)
- `POST /monitoring/client-logs`

### Payload enviado pelo app

```json
{
  "level": "error",
  "source": "flutter_error",
  "message": "Exception: erro de conexão",
  "stackTrace": "...",
  "platform": "android",
  "isReleaseMode": true,
  "timestamp": "2026-04-10T00:00:00Z",
  "context": {
    "library": "widgets library"
  }
}
```

### Resposta esperada pelo app
- `202 Accepted` (recomendado) ou `200 OK`.

### Regras de backend para relay
- Validar payload mínimo (`level`, `message`, `timestamp`).
- Enriquecer com:
  - `environment` (`prod`, `staging`),
  - `apiVersion`,
  - correlação (`requestId`/`traceId`) quando existir.
- Reenviar ao Better Stack Logs via HTTP ingest endpoint com token secreto no backend.
- Implementar retry com backoff para falhas transitórias.
- Aplicar rate limit para evitar abuso.
- Nunca retornar erro interno detalhado para o cliente.

## 3) Boas práticas recomendadas

- Adicionar autenticação opcional no endpoint de logs do cliente (Bearer do usuário ou app key).
- Mascarar dados sensíveis (PII) antes de enviar ao Better Stack.
- Garantir idempotência por hash (`message + timestamp + source`) se necessário.
- Criar dashboard com filtros por `platform`, `source` e `environment`.

# Chronora Flutter

Frontend Flutter Web da Chronora.

## Render production

O deploy de producao esta preparado para a branch `main` com Docker.

### Variavel obrigatoria

- `API_BASE_URL`

### Subir no Render

1. Conecte o repositorio no Render como `Web Service`.
2. Use a branch `main`.
3. Use `Docker` como runtime.
4. Garanta que o `Dockerfile` da raiz seja usado.
5. Defina `API_BASE_URL` com a URL publica do backend de producao.
6. Rode o deploy.

## Build local

Para rodar local apontando para o backend local, use um arquivo `.env.local` na raiz com base em `.env.local.example`:

```text
API_BASE_URL=http://localhost:8085
```

### Arquivos locais

- Crie um arquivo `.env.local` na raiz
- O arquivo `.env.local` esta no `.gitignore` e nao deve ser commitado
- Para rodar localmente com backend local, use `API_BASE_URL=http://localhost:8085`

### Rodar localmente

```powershell
.\scripts\run-local.ps1
```

### Build web local

```powershell
.\scripts\run-local.ps1 -Mode build
```

### Observacoes

- Se o PowerShell bloquear a execucao do script, rode:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-local.ps1
```

- Para desenvolvimento local completo:
  1. suba o backend local na porta `8085`
  2. depois rode o frontend com o `.env.local` apontando para `http://localhost:8085`

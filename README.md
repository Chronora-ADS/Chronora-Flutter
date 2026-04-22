# Chronora Flutter

Frontend Flutter Web da Chronora.

## Render dev

O deploy de desenvolvimento esta preparado para a branch `master` com Docker.

- Backend padrao: `https://chronora-java-master.onrender.com`
- Health check: `/`

### Subir no Render

1. Conecte o repositorio no Render como `Web Service`.
2. Use `Docker` como runtime.
3. Garanta que o `Dockerfile` da raiz seja usado.
4. Rode o deploy da branch `master`.

## Build local

Para rodar local apontando para o backend local, use um arquivo `.env.local` na raiz com base em `.env.local.example`:

```text
API_BASE_URL=http://localhost:8085
```

### Rodar localmente

```powershell
.\scripts\run-local.ps1
```

### Build web local

```powershell
.\scripts\run-local.ps1 -Mode build
```

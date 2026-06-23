# Chronora Flutter

Frontend Flutter Web da Chronora.


# Pré‑requisitos
- Flutter (versão 3.x ou superior)
- Docker (para deploy no Render)
- PowerShell (para executar os scripts locais)


# Configuração
### Variáveis de ambiente
O frontend precisa saber a URL base da API para se comunicar com o backend.
A variável obrigatória é:

| Variável |	Descrição |
|----------|------------|
| API_BASE_URL |	URL pública do backend (ex: https://api.exemplo.com) |


### Arquivos de ambiente
Desenvolvimento local – crie um arquivo .env.local na raiz do projeto baseado no .env.local.example:
- API_BASE_URL=http://localhost:8085

Produção / Deploy – a variável API_BASE_URL é definida no ambiente do servidor.


# Execução local
Para rodar o frontend em modo desenvolvimento apontando para o backend local:
- Subir o backend local – certifique‑se de que ele esteja rodando na porta 8085 (ou ajuste a URL no .env.local).
- Executar o script: .\scripts\run-local.ps1

O script iniciará o servidor de desenvolvimento do Flutter Web.


# Build local (gerar artefatos para produção)
- Para compilar o projeto e gerar os arquivos estáticos da web: .\scripts\run-local.ps1 -Mode build

Os arquivos compilados estarão na pasta build/web/.


# Deploy no Render
O projeto está configurado para deploy via Docker no Render.

### Produção (main branch)
- Branch: main
- Runtime: Docker
- Dockerfile: raiz do projeto
- Variável obrigatória: API_BASE_URL com a URL pública do backend de produção

### Passos
- Conecte o repositório ao Render como Web Service.
- Selecione a branch main.
- Escolha Docker como runtime.
- Defina a variável de ambiente API_BASE_URL com o endereço do backend de produção.
- Clique em Deploy.


### Desenvolvimento (master branch)
- Branch: master
- Runtime: Docker
- Dockerfile: raiz do projeto
- Backend padrão: https://chronora-java-master.onrender.com
- Health check: /

### Passos
- Conecte o repositório ao Render como Web Service.
- Selecione a branch master.
- Escolha Docker como runtime.
- Defina API_BASE_URL apontando para o backend de desenvolvimento.
- Clique em Deploy.
- O health check pode ser configurado na rota / para monitoramento.


# Estrutura de branches
- master → ambiente de desenvolvimento
- main → ambiente de produção

# Webhook Inspector

Ferramenta para **receber, inspecionar e depurar webhooks** durante o desenvolvimento, feita com Ruby on Rails 8.

Você cria um endpoint, recebe uma URL única, aponta qualquer serviço (GitHub, gateways de pagamento, bots, APIs) para ela e vê **ao vivo, na tela**, tudo o que chegou: método, headers, query params, corpo e IP de origem.

<!-- Adicione um print da tela de detalhe em docs/screenshot.png e descomente a linha abaixo -->
<!-- ![Tela de detalhe do endpoint](docs/screenshot.png) -->

## Funcionalidades

- **URL única por endpoint**, com token aleatório gerado automaticamente
- **Aceita qualquer verbo HTTP** (GET, POST, PUT, PATCH, DELETE...) na mesma URL
- **Captura completa**: método, headers, query params, corpo, content-type e IP
- **Atualização em tempo real** com Turbo Streams: a requisição aparece na tela sem recarregar a página
- **JSON formatado** automaticamente no corpo; outros formatos aparecem como texto
- **Limpeza automática**: um job diário apaga requisições com mais de 7 dias
- **Painel protegido por senha** (HTTP Basic Auth), mantendo as URLs de webhook abertas via token
- **Proteções básicas**: limite de tamanho do corpo, resposta 404 para tokens inválidos e escape automático de HTML (contra XSS)
- **Testes automatizados** de models, controllers e jobs

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Ruby on Rails 8 |
| Banco de dados | SQLite |
| Tempo real | Hotwire (Turbo Streams) sobre Action Cable |
| Jobs em segundo plano | Active Job com Solid Queue |
| Testes | Minitest |

## Como funciona

```
Serviço externo ──► POST /hooks/:token ──► CapturesController
                                                 │
                                       CapturedRequest.create!
                                                 │ (after_create_commit)
                                       broadcast_prepend_to endpoint
                                                 │
                                    Action Cable (WebSocket aberto)
                                                 │
                         Navegador insere o HTML no topo da lista
```

O painel (`/endpoints`) é protegido por senha. A rota de captura (`/hooks/:token`) não exige senha, porque os serviços externos não sabem enviá-la: o **token na URL** funciona como segredo.

## Requisitos

- Ruby 3.2 ou superior
- Bundler
- SQLite 3

## Instalação

```bash
git clone https://github.com/SEU-USUARIO/webhook_inspector.git
cd webhook_inspector
bundle install
bin/rails db:prepare
bin/rails server
```

Acesse `http://localhost:3000`.

## Como usar

1. Abra `http://localhost:3000/endpoints` e clique para criar um novo endpoint.
2. Na tela de detalhe, copie a URL exibida, por exemplo `http://localhost:3000/hooks/abc123...`.
3. Envie uma requisição para ela, ou cole a URL na configuração de webhook do serviço que você quer testar.
4. Veja a requisição aparecer no topo da lista, ao vivo.

### Testando com PowerShell (Windows)

```powershell
Invoke-RestMethod -Method Post `
  -Uri http://localhost:3000/hooks/SEU_TOKEN `
  -ContentType "application/json" `
  -Body '{"evento":"teste","valor":42}'
```

> No PowerShell, `curl` é um apelido de `Invoke-WebRequest`. Para usar o curl de verdade, chame `curl.exe`.

### Testando com curl

```bash
curl -X POST http://localhost:3000/hooks/SEU_TOKEN \
  -H "Content-Type: application/json" \
  -d '{"evento": "teste", "valor": 42}'
```

## Rotas

| Verbo | Caminho | Descrição |
|---|---|---|
| GET | `/endpoints` | Lista os endpoints |
| GET | `/endpoints/new` | Formulário de novo endpoint |
| POST | `/endpoints` | Cria um endpoint |
| GET | `/endpoints/:id` | Detalhe e requisições capturadas (ao vivo) |
| GET | `/endpoints/:id/edit` | Edição |
| PATCH/PUT | `/endpoints/:id` | Atualiza |
| DELETE | `/endpoints/:id` | Apaga o endpoint e suas requisições |
| **qualquer** | `/hooks/:token` | **Recebe webhooks** (200 se o token existe, 404 se não) |

## Configuração

| Variável | Obrigatória | Descrição |
|---|---|---|
| `ADMIN_PASSWORD` | Em produção, sim | Senha do painel. Se estiver ausente em produção, o app se recusa a abrir o painel. Em desenvolvimento e teste, sem ela o painel fica aberto. |
| `ADMIN_USER` | Não | Usuário do painel. Padrão: `admin` |
| `RAILS_MASTER_KEY` | Em produção | Conteúdo de `config/master.key` |
| `SOLID_QUEUE_IN_PUMA` | Em produção | Defina como `true` para rodar o processador de jobs junto do servidor web |

Para testar a senha localmente no PowerShell:

```powershell
$env:ADMIN_PASSWORD = "segredo"
bin/rails server
```

O fuso horário está configurado como `America/Manaus` em `config/application.rb`. Ajuste conforme necessário.

## Limpeza automática

O job `CleanupOldCapturesJob` apaga requisições com mais de 7 dias. Em produção, ele é agendado em `config/recurring.yml` para rodar todo dia às 3h pelo Solid Queue. Para executá-lo manualmente:

```bash
bin/rails runner "CleanupOldCapturesJob.perform_now"
```

## Testes

```bash
bin/rails test
```

Para rodar um arquivo ou filtrar por nome:

```bash
bin/rails test test/controllers/captures_controller_test.rb
bin/rails test test/controllers/captures_controller_test.rb -n "/token/"
```

A suíte cobre:

- **Models**: geração de token, validações, formatação do corpo, broadcast do Turbo Stream
- **Captura**: todos os verbos, query params, headers, token inválido, limite de tamanho do corpo
- **Painel**: CRUD, geração de token no servidor, escape de HTML, exigência de senha
- **Job**: remove apenas o que passou do prazo

## Estrutura do projeto

```
app/
  controllers/
    application_controller.rb    # autenticação do painel
    captures_controller.rb       # recebe os webhooks (/hooks/:token)
    endpoints_controller.rb      # CRUD de endpoints e tela de detalhe
  jobs/
    cleanup_old_captures_job.rb  # limpeza de requisições antigas
  models/
    endpoint.rb                  # token, validações, associação
    captured_request.rb          # broadcast em tempo real, formatação do corpo
  views/
    endpoints/                   # telas do painel
    captured_requests/           # partial de cada requisição capturada
config/
  routes.rb                      # rota catch-all /hooks/:token
  recurring.yml                  # agendamento do job de limpeza
test/                            # models, controllers, jobs, fixtures
```

## Segurança

- O token da URL é o único segredo das rotas de captura. Trate as URLs de webhook como senhas.
- O corpo capturado é limitado a 100.000 caracteres.
- O conteúdo recebido é sempre escapado na tela, então um `<script>` enviado em um webhook aparece como texto e não é executado.
- HTTP Basic Auth deve ser usado **somente com HTTPS** em produção.
- Requisições capturadas podem conter dados sensíveis (chaves de API em headers, por exemplo). Use a limpeza automática e apague endpoints que não usa mais.

## Deploy

O projeto inclui o `Dockerfile` padrão do Rails 8 e suporte ao Kamal. Pontos de atenção:

- Defina as variáveis de ambiente da seção [Configuração](#configuração).
- O SQLite precisa de **disco persistente**, senão o banco é perdido a cada novo deploy. Se a plataforma não oferecer volume persistente, considere PostgreSQL.
- Sirva a aplicação sempre atrás de **HTTPS**.

## Próximos passos

- [ ] Reenviar uma requisição capturada para outra URL (por exemplo, o `localhost`)
- [ ] Resposta customizável por endpoint (status e corpo)
- [ ] Botão para limpar todas as requisições de um endpoint
- [ ] Filtro por método e busca no corpo
- [ ] Validação de assinatura de webhooks (HMAC, como no GitHub)

## Licença

Defina a licença do projeto (por exemplo, MIT) e adicione um arquivo `LICENSE`.

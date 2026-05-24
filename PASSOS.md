# Registro de Passos — Construção da API

Este arquivo documenta, em ordem cronológica, cada comando executado e a sua finalidade
durante a construção da API REST de Clientes em Ruby on Rails.

> O conteúdo de apresentação do projeto (descrição, diagrama e instruções para rodar)
> fica no `README.md`. Este arquivo é o "diário de bordo" da construção.

---

## Pré-requisitos verificados

- Ruby `3.1.6`
- Rails `7.1.6`
- PostgreSQL instalado e acessível localmente

Comandos de verificação:

```bash
ruby --version
rails --version
```

---

## Passo 1 — Criação do projeto Rails em modo API

**Comando executado:**

```bash
rails new . --api -d postgresql
```

**O que foi feito:**

- `rails new .` gera o esqueleto Rails no diretório atual (`desafio-final-pos`).
- `--api` configura o projeto em **modo API-only**: remove middleware/sessões/assets
  voltados a aplicações web tradicionais e mantém apenas o necessário para
  servir JSON. Reflete o cenário do enunciado (API REST pública para parceiros).
- `-d postgresql` define o **PostgreSQL** como adaptador de banco em todos os
  ambientes (`config/database.yml`).

**Efeitos colaterais ativados automaticamente pelo Rails:**

- `--skip-javascript`, `--skip-hotwire`, `--skip-asset-pipeline` — coerentes com
  uma API que não renderiza views.

**Saída relevante:**

- Estrutura padrão criada (`app/`, `config/`, `db/`, etc.).
- `git init` executado automaticamente.
- `bundle install` executado, instalando as 72 gems do `Gemfile`.
- `Gemfile.lock` gerado com a plataforma `x86_64-linux`.

---

## Passo 2 — Geração do scaffold do recurso Cliente

**Comando executado:**

```bash
bin/rails generate scaffold Cliente nome:string email:string
```

**Por que usar `scaffold`:**

O gerador `scaffold` do Rails é o atalho idiomático para criar um recurso REST
completo em uma única chamada. Como o enunciado pede uma **API CRUD** com
arquitetura **MVC**, o scaffold cobre a maior parte do MVC de uma só vez,
respeitando convenções do framework — o que reduz código-cola e mantém o
projeto alinhado ao "padrão Rails".

**Artefatos criados pelo Rails:**

| Camada (MVC)      | Arquivo                                                  | Função |
| ----------------- | -------------------------------------------------------- | ------ |
| Model             | `app/models/cliente.rb`                                  | Classe `Cliente < ApplicationRecord` — mapeia a tabela `clientes` via Active Record. |
| Migration         | `db/migrate/*_create_clientes.rb`                        | Cria a tabela `clientes` com colunas `nome:string`, `email:string` e `timestamps`. |
| Controller        | `app/controllers/clientes_controller.rb`                 | Endpoints REST: `index`, `show`, `create`, `update`, `destroy`, todos respondendo em **JSON** (modo `--api`). |
| Routes            | `config/routes.rb` (`resources :clientes`)               | Roteamento resourceful: gera as 5 rotas RESTful para `/clientes`. |
| Testes            | `test/models/cliente_test.rb`, `test/controllers/clientes_controller_test.rb`, `test/fixtures/clientes.yml` | Esqueletos de teste (Minitest, padrão Rails). |

**Mapeamento com os requisitos do enunciado:**

| Requisito                | Endpoint gerado pelo scaffold       | Status |
| ------------------------ | ----------------------------------- | ------ |
| Create                   | `POST   /clientes`                  | ✅ |
| Read (Find All)          | `GET    /clientes`                  | ✅ |
| Read (Find By ID)        | `GET    /clientes/:id`              | ✅ |
| Update                   | `PATCH/PUT /clientes/:id`           | ✅ |
| Delete                   | `DELETE /clientes/:id`              | ✅ |
| Contagem (`count`)       | —                                   | ⏳ (será adicionado num passo posterior) |
| Find By Name             | —                                   | ⏳ (será adicionado num passo posterior) |

> A **camada Service** pedida no exemplo Java não nasce do scaffold do Rails
> (o framework, por padrão, concentra a lógica no Model + Controller "magro").
> Vamos introduzi-la manualmente num passo seguinte, junto com os endpoints
> extras (`/contar` e `/nome/:nome`), para deixar o desenho MVC explícito.

---

## Passo 3 — Criação dos bancos e execução das migrations

**Comando executado:**

```bash
bin/rails db:create db:migrate
```

**O que cada subcomando faz:**

- `db:create` — lê `config/database.yml` e cria, no PostgreSQL local, os bancos
  de cada ambiente que ainda não existem (no nosso caso `development` e `test`).
  Esse atalho do Rails dispensa o uso direto de `createdb` / `psql`.
- `db:migrate` — aplica, em ordem cronológica, todas as migrations pendentes
  em `db/migrate/`. Aqui aplicou a `CreateClientes`, criando a tabela
  `clientes` com as colunas `nome`, `email`, `created_at`, `updated_at`.

**Saída relevante:**

```
Created database 'desafio_final_pos_development'
Created database 'desafio_final_pos_test'
== 20260524120426 CreateClientes: migrating ===================================
-- create_table(:clientes)
   -> 0.0108s
== 20260524120426 CreateClientes: migrated (0.0108s) ==========================
```

**Efeito colateral importante:**

- O arquivo `db/schema.rb` foi (re)gerado automaticamente pelo Rails. Ele é
  o "snapshot" do estado atual do schema e é o que `db:schema:load` usa para
  recriar o banco do zero em ambientes novos (por exemplo, CI). Deve ser
  versionado no Git.

---

## Passo 4 — Camada de Service + endpoints extras (`count`, `find by name`) + validações

Este passo **não é um gerador do Rails**: a "camada Service" não é uma convenção
nativa do framework (que normalmente recomenda *fat models, skinny controllers*).
Como o exemplo Java do enunciado pede explicitamente uma camada `Service` entre
`Controller` e `Model`, introduzi-la manualmente é o equivalente Rails do
desenho descrito no enunciado.

### 4.1. Criar `app/services/cliente_service.rb`

Por convenção, qualquer pasta criada dentro de `app/` é automaticamente
carregada pelo *autoloader* do Rails (Zeitwerk). Por isso basta criar
`app/services/` e a classe `ClienteService` fica disponível em toda a
aplicação sem `require` manual.

Métodos implementados (espelhando o `ClienteService.java` do enunciado):

| Método Ruby                     | Equivalente Java          | O que faz |
| ------------------------------- | ------------------------- | --------- |
| `listar_todos`                  | `listarTodos`             | `Cliente.all` |
| `buscar_por_id(id)`             | `buscarPorId`             | `Cliente.find_by(id:)` (retorna `nil` se não achar, em vez de lançar exceção) |
| `buscar_por_nome(nome)`         | `buscarPorNome`           | `Cliente.where("nome ILIKE ?", "%nome%")` — busca *case-insensitive* parcial, mais útil que igualdade estrita |
| `contar`                        | `contarClientes`          | `Cliente.count` |
| `salvar(atributos)`             | `salvar`                  | `Cliente.create(atributos)` |
| `atualizar(cliente, atributos)` | (implícito no `salvar`)   | `cliente.update(atributos)` |
| `deletar(cliente)`              | `deletar`                 | `cliente.destroy` |

### 4.2. Refatorar `app/controllers/clientes_controller.rb`

O controller passa a **delegar toda a regra de negócio para o `ClienteService`**.
As ações HTTP só cuidam de: receber parâmetros, chamar o service, e responder
com o status/JSON correto. Foram adicionadas duas novas ações:

- `count` — responde `{ "total": N }` em `GET /clientes/count`
- `by_name` — responde lista filtrada por `nome` em `GET /clientes/nome/:nome`

O `set_cliente` agora também retorna `404` JSON quando o cliente não existe,
em vez de deixar o Rails levantar `ActiveRecord::RecordNotFound`.

### 4.3. Adicionar rotas em `config/routes.rb`

```ruby
resources :clientes do
  collection do
    get :count
    get 'nome/:nome', to: 'clientes#by_name', as: :by_name
  end
end
```

O bloco `collection` mantém as 5 rotas RESTful do `resources` original e
adiciona as duas novas no escopo do recurso (não confundir com `member`,
que seria por ID).

### 4.4. Adicionar validações em `app/models/cliente.rb`

```ruby
validates :nome, presence: true
validates :email, presence: true,
                  format: { with: URI::MailTo::EMAIL_REGEXP, message: "formato inválido" }
```

Boas práticas básicas de domínio: nome e email obrigatórios, email com
formato válido. As validações são executadas no `create`/`update` e fazem
o controller responder `422 Unprocessable Entity` automaticamente em caso
de falha (já tratado em `create` e `update`).

### 4.5. Verificação — rotas finais

Saída de `bin/rails routes -c clientes`:

```
          Prefix Verb   URI Pattern                    Controller#Action
  count_clientes GET    /clientes/count(.:format)      clientes#count
by_name_clientes GET    /clientes/nome/:nome(.:format) clientes#by_name
        clientes GET    /clientes(.:format)            clientes#index
                 POST   /clientes(.:format)            clientes#create
         cliente GET    /clientes/:id(.:format)        clientes#show
                 PATCH  /clientes/:id(.:format)        clientes#update
                 PUT    /clientes/:id(.:format)        clientes#update
                 DELETE /clientes/:id(.:format)        clientes#destroy
```

**Cobertura final dos requisitos do enunciado:**

| Requisito       | Endpoint                  | Status |
| --------------- | ------------------------- | ------ |
| Create          | `POST   /clientes`        | ✅ |
| Find All (Read) | `GET    /clientes`        | ✅ |
| Find By ID      | `GET    /clientes/:id`    | ✅ |
| Update          | `PATCH  /clientes/:id`    | ✅ |
| Delete          | `DELETE /clientes/:id`    | ✅ |
| Contagem        | `GET    /clientes/count`  | ✅ |
| Find By Name    | `GET    /clientes/nome/:nome` | ✅ |

---

## Passo 5 — Diagrama de arquitetura + README de apresentação

Último passo: criar os artefatos de **apresentação** do projeto (não há
gerador do Rails para isso).

### 5.1. `diagrama.md`

Arquivo na raiz do projeto contendo 4 diagramas em **Mermaid**:

1. **Contexto (C4 nível 1)** — quem usa o sistema e com o que ele conversa.
2. **Componentes (C4 nível 3)** — atravessamento do request por
   Routes → Controller → Service → Model → Banco.
3. **Mapa de endpoints** — relação 1-para-1 entre rota HTTP e ação do controller.
4. **Sequência `POST /clientes`** — fluxo passo a passo da criação.

> **Por que Mermaid e não draw.io/PNG?** Mermaid renderiza nativamente
> no GitHub/GitLab/IDE, é texto versionável (diff legível), e dispensa
> binários no repositório. Atende ao "qualquer diagrama de sua preferência"
> permitido pelo enunciado. Se for exigido o `.drawio` ou imagem, basta
> colar o código Mermaid no [draw.io](https://draw.io) (suporta importação).

### 5.2. `README.md`

Substituído o README padrão do Rails por uma apresentação do projeto contendo:

- Descrição do que é a API.
- Stack utilizada.
- Diagrama de componentes embutido (mesmo do `diagrama.md`).
- Estrutura de pastas com tabela explicando o papel de **Model, View
  (ausente), Controller, Service, Routes, Migration**.
- Tabela com os 7 endpoints.
- Instruções de execução (`bundle install`, `db:create db:migrate`, `bin/rails server`).
- Exemplos de `curl` cobrindo cada endpoint.

---

## Estado final dos entregáveis (conforme o enunciado)

| Entregável do enunciado                                  | Arquivo no projeto                  |
| -------------------------------------------------------- | ----------------------------------- |
| 1. Desenho arquitetural (UML/C4/outro)                   | [`diagrama.md`](diagrama.md)        |
| 2. Estrutura de pastas + papel dos componentes           | [`README.md`](README.md) (seção *Estrutura de pastas*) |
| 3. Explicação da estrutura e elementos do código         | [`README.md`](README.md) (seção *Arquitetura* + tabela de componentes) |
| 4. (Opcional) Código funcionando                         | Todo o projeto Rails em `app/`, `config/`, `db/` |
| 5. (Opcional) Persistência funcionando                   | PostgreSQL + Active Record + migration aplicada |

---

## Passo 6 — Validação end-to-end via testes de integração

Em vez de validar com `curl` (bloqueado pelo sandbox neste ambiente),
optamos pelo equivalente em Rails: **testes de integração**
(`ActionDispatch::IntegrationTest`), que exercitam a stack inteira —
roteamento, middleware, controller, service, model, banco — sem
precisar subir o servidor.

### 6.1. Corrigir a fixture gerada pelo scaffold

O scaffold cria `test/fixtures/clientes.yml` com `email: MyString`,
que **falha** a validação de formato adicionada no Passo 4. Substituído
por dois clientes com emails válidos (`maria@example.com`, `joao@example.com`).

### 6.2. Expandir `test/controllers/clientes_controller_test.rb`

O scaffold gerou 5 testes básicos (um por ação CRUD). Foram adicionados
testes para:

- `count` (`GET /clientes/count`)
- `by_name` com match exato, match parcial *case-insensitive* e sem match
- caminho 404 (`show` com id inexistente)
- caminho 422 (`create` com payload sem email)

Asserções agora verificam, além do status HTTP, o **conteúdo JSON** da
resposta (chaves, valores, tamanho de listas).

### 6.3. Rodar a suíte

**Comando executado:**

```bash
bin/rails test
```

**Resultado:**

```
11 runs, 34 assertions, 0 failures, 0 errors, 0 skips
```

Os 11 testes confirmam o comportamento de todos os 7 endpoints, mais os
caminhos de erro 404 e 422 e a validação do model.

---

## Passo 7 — Testes unitários do Model `Cliente`

Os testes do Passo 6 são de **integração** (sobem a stack inteira). Para
isolar a entidade de domínio, foram adicionados **testes unitários puros**
do model `Cliente` em `test/models/cliente_test.rb`, herdando de
`ActiveSupport::TestCase` (sem `ActionDispatch`).

### Cobertura

| Categoria              | Casos cobertos |
| ---------------------- | -------------- |
| Caso feliz             | criação válida; persistência no banco; preenchimento automático de `created_at`/`updated_at` |
| Validação de `nome`    | ausente; string vazia |
| Validação de `email` (presença) | ausente |
| Validação de `email` (formato)  | sem `@`; sem domínio; sem usuário |
| Variações aceitas      | email com subdomínio (`user@mail.example.com`); plus addressing (`user+tag@example.com`) |
| Acúmulo de erros       | ambos `nome` e `email` ausentes — verifica que os dois erros aparecem juntos |
| Fixtures               | `clientes(:one)` e `clientes(:two)` são válidas (garante que as fixtures não regridem) |
| Atualização            | trocar `email` para valor inválido invalida o registro |

### Comando

```bash
bin/rails test test/models/cliente_test.rb
```

**Resultado:** `14 runs, 35 assertions, 0 failures, 0 errors`.

### Suíte completa

```bash
bin/rails test
```

**Resultado final:** `25 runs, 69 assertions, 0 failures, 0 errors`
(11 de controller/integração + 14 de model/unit).

---

## Passo 8 — Fix de bug em `buscar_por_nome` + edge cases no model

### Bug identificado

A implementação anterior (`ClienteService.buscar_por_nome`) interpolava o
input diretamente em `ILIKE`:

```ruby
Cliente.where("nome ILIKE ?", "%#{nome}%")
```

Embora seguro contra **SQL injection** (o `?` faz binding), os caracteres
**curinga do `LIKE`/`ILIKE`** (`%`, `_`, `\`) eram interpretados como tal.
Consequências:

- Buscar `"%"` → casava com **todos** os clientes (efeitos de wildcard).
- Buscar `"a_b"` → o `_` casava qualquer caractere único.
- Buscar `""` (string vazia) → `ILIKE '%%'` → retornava a **tabela inteira**.
- `nil` → exceção.

### Mudança arquitetural

A regra de busca migrou do **Service** para o **Model** (`Cliente.buscar_por_nome`).
Justificativa: detalhes de SQL e *escaping* de curingas são conhecimento do
mapeamento de domínio (Active Record), não da camada de aplicação. O Service
continua existindo como **fachada** e simplesmente delega:

```ruby
# app/services/cliente_service.rb
def self.buscar_por_nome(nome)
  Cliente.buscar_por_nome(nome)
end
```

### Implementação no model

```ruby
# app/models/cliente.rb
def self.buscar_por_nome(nome)
  return none if nome.blank?

  termo = nome.gsub(/[\\%_]/) { |c| "\\#{c}" }
  where("nome ILIKE ?", "%#{termo}%")
end
```

- `none` — retorna um `ActiveRecord::Relation` **vazio** sem ir ao banco,
  para `nil`, `""` e *whitespace puro*.
- `gsub(/[\\%_]/, …)` — escapa `\`, `%` e `_` no input, fazendo-os serem
  tratados como **caracteres literais** pelo `ILIKE` (PostgreSQL usa `\`
  como caractere de escape por padrão).
- O retorno continua sendo `ActiveRecord::Relation` — **encadeável** com
  `order`/`limit`/`where` por chamadores futuros.

### Novos testes (13) em `test/models/cliente_test.rb`

Conforme acordado, **a cobertura adicional fica apenas no nível unitário
do model** — os testes de integração não foram ampliados.

| Categoria         | Casos cobertos |
| ----------------- | -------------- |
| Match básico      | exato, case-insensitive, parcial, sem match |
| Múltiplos matches | dois clientes com "Silva" → retorna ambos |
| Curingas SQL      | `%` literal, `_` literal, `\` literal |
| Entradas vazias   | `""`, `"   "`, `nil` (não lança exceção) |
| Acentos           | comportamento atual documentado: `ILIKE` **não** normaliza diacríticos (`"Joao"` não casa `"João"`); para isso seria preciso a extensão `unaccent` do PostgreSQL |
| Contrato          | retorno é `ActiveRecord::Relation` encadeável |

### Resultado da suíte

```bash
bin/rails test
```

```
38 runs, 91 assertions, 0 failures, 0 errors, 0 skips
```

- 11 testes de controller/integração (inalterados — continuam passando porque o contrato externo `ClienteService.buscar_por_nome` não mudou).
- 27 testes unitários do model (14 originais + 13 novos de borda).

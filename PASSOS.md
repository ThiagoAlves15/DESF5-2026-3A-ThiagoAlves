# Registro de Passos: Construção da API

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

## Passo 1: Criação do projeto Rails em modo API

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

- `--skip-javascript`, `--skip-hotwire`, `--skip-asset-pipeline`: coerentes com
  uma API que não renderiza views.

**Saída relevante:**

- Estrutura padrão criada (`app/`, `config/`, `db/`, etc.).
- `git init` executado automaticamente.
- `bundle install` executado, instalando as 72 gems do `Gemfile`.
- `Gemfile.lock` gerado com a plataforma `x86_64-linux`.

---

## Passo 2: Geração do scaffold do recurso Cliente

**Comando executado:**

```bash
bin/rails generate scaffold Cliente nome:string email:string
```

**Por que usar `scaffold`:**

O gerador `scaffold` do Rails é o atalho idiomático para criar um recurso REST
completo em uma única chamada. Como o enunciado pede uma **API CRUD** com
arquitetura **MVC**, o scaffold cobre a maior parte do MVC de uma só vez,
respeitando convenções do framework e mantém o projeto alinhado ao "padrão Rails".

**Artefatos criados pelo Rails:**

| Camada (MVC)      | Arquivo                                                  | Função |
| ----------------- | -------------------------------------------------------- | ------ |
| Model             | `app/models/cliente.rb`                                  | Classe `Cliente < ApplicationRecord`: mapeia a tabela `clientes` via Active Record. |
| Migration         | `db/migrate/*_create_clientes.rb`                        | Cria a tabela `clientes` com colunas `nome:string`, `email:string` e `timestamps`. |
| Controller        | `app/controllers/clientes_controller.rb`                 | Endpoints REST: `index`, `show`, `create`, `update`, `destroy`, todos respondendo em **JSON** (modo `--api`). |
| Routes            | `config/routes.rb` (`resources :clientes`)               | Roteamento resourceful: gera as 5 rotas RESTful para `/clientes`. |
| Testes            | `test/models/cliente_test.rb`, `test/controllers/clientes_controller_test.rb`, `test/fixtures/clientes.yml` | Esqueletos de teste (Minitest, padrão Rails). |

**Mapeamento com os requisitos do enunciado:**

| Requisito                | Endpoint gerado pelo scaffold       | Status |
| ------------------------ | ----------------------------------- | ------ |
| Create                   | `POST   /clientes`                  | Pronto |
| Read (Find All)          | `GET    /clientes`                  | Pronto |
| Read (Find By ID)        | `GET    /clientes/:id`              | Pronto |
| Update                   | `PATCH/PUT /clientes/:id`           | Pronto |
| Delete                   | `DELETE /clientes/:id`              | Pronto |
| Contagem (`count`)       | -                                   | Pendente (será adicionado num passo posterior) |
| Find By Name             | -                                   | Pendente (será adicionado num passo posterior) |

> A **camada Service** pedida no exemplo Java não nasce do scaffold do Rails
> (o framework, por padrão, concentra a lógica no Model + Controller "magro").
> Vamos introduzi-la manualmente num passo seguinte, junto com os endpoints
> extras (`/contar` e `/nome/:nome`), para deixar o desenho MVC explícito.

---

## Passo 3: Criação dos bancos e execução das migrations

**Comando executado:**

```bash
bin/rails db:create db:migrate
```

**O que cada subcomando faz:**

- `db:create`: lê `config/database.yml` e cria, no PostgreSQL local, os bancos
  de cada ambiente que ainda não existem (no nosso caso `development` e `test`).
  Esse atalho do Rails dispensa o uso direto de `createdb` / `psql`.
- `db:migrate`: aplica, em ordem cronológica, todas as migrations pendentes
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

## Passo 4: Camada de Service + endpoints extras (`count`, `find by name`) + validações

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
| `busca_por_nome(nome)`         | `buscarPorNome`           | `Cliente.where("nome ILIKE ?", "%nome%")`: busca *case-insensitive* parcial, mais útil que igualdade estrita |
| `contar`                        | `contarClientes`          | `Cliente.count` |
| `salvar(atributos)`             | `salvar`                  | `Cliente.create(atributos)` |
| `atualizar(cliente, atributos)` | (implícito no `salvar`)   | `cliente.update(atributos)` |
| `deletar(cliente)`              | `deletar`                 | `cliente.destroy` |

### 4.2. Refatorar `app/controllers/clientes_controller.rb`

O controller passa a **delegar toda a regra de negócio para o `ClienteService`**.
As ações HTTP só cuidam de: receber parâmetros, chamar o service, e responder
com o status/JSON correto. Foram adicionadas duas novas ações:

- `count`: responde `{ "total": N }` em `GET /clientes/count`
- `by_name`: responde lista filtrada por `nome` em `GET /clientes/nome/:nome`

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

### 4.5. Verificação: rotas finais

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
| Create          | `POST   /clientes`        | Pronto |
| Find All (Read) | `GET    /clientes`        | Pronto |
| Find By ID      | `GET    /clientes/:id`    | Pronto |
| Update          | `PATCH  /clientes/:id`    | Pronto |
| Delete          | `DELETE /clientes/:id`    | Pronto |
| Contagem        | `GET    /clientes/count`  | Pronto |
| Find By Name    | `GET    /clientes/nome/:nome` | Pronto |

---

## Passo 5: Diagrama de arquitetura + README de apresentação

Último passo: criar os artefatos de **apresentação** do projeto.

### 5.1. `diagrama.md`

Arquivo na raiz do projeto contendo 4 diagramas em **Mermaid**:

1. **Contexto (C4 nível 1)**: quem usa o sistema e com o que ele conversa.
2. **Componentes (C4 nível 3)**: atravessamento do request por
   Routes → Controller → Service → Model → Banco.
3. **Mapa de endpoints**: relação 1-para-1 entre rota HTTP e ação do controller.
4. **Sequência `POST /clientes`**: fluxo passo a passo da criação.


---

## Estado final dos entregáveis (conforme o enunciado)

| Entregável do enunciado                                  | Arquivo no projeto                  |
| -------------------------------------------------------- | ----------------------------------- |
| 1. Desenho arquitetural (UML/C4/outro)                   | [`diagrama.md`](diagrama.md)        |
| 2. Estrutura de pastas + papel dos componentes           | [`README.md`](README.md) (seção *Estrutura de pastas*) |
| 3. Explicação da estrutura e elementos do código         | [`README.md`](README.md) (seção *Arquitetura* + tabela de componentes) |
| 4. (Opcional) Código funcionando                         | Todo o projeto Rails em `app/`, `config/`, `db/` |
| 5. (Opcional) Persistência funcionando                   | PostgreSQL + Active Record + migration aplicada |

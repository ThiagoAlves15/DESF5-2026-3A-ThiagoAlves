# Registro de Passos

Diário dos comandos rodados pra montar a API. Para descrição e
instruções de uso, ver o `README.md`.

## Pré-requisitos

- Ruby 3.1.6
- Rails 7.1.6
- PostgreSQL local

## 1. Criar o projeto em modo API

```bash
rails new . --api -d postgresql
```

`--api` deixa o Rails sem session/cookies/asset pipeline (não precisamos
disso, apenas retornar JSON). `-d postgresql` configura o adapter em
todos os ambientes (`config/database.yml`).

Rodou `bundle install` automaticamente e gerou o `Gemfile.lock`.

## 2. Gerar o scaffold do recurso Cliente

```bash
bin/rails generate scaffold Cliente nome:string email:string
```

Isso cria o model (`app/models/cliente.rb`), a migration
(`db/migrate/*_create_clientes.rb`), o controller com as 5 ações REST,
as rotas (`resources :clientes`) e os esqueletos de teste.

Falta ainda a camada Service e os endpoints extras de contagem e busca
por nome, que entram no Passo 4.

## 3. Criar os bancos e rodar a migration

```bash
bin/rails db:create db:migrate
```

`db:create` cria os bancos de development e test no PostgreSQL local;
`db:migrate` aplica a `CreateClientes` (cria a tabela `clientes` com
`nome`, `email` e timestamps). O `db/schema.rb` é regerado e fica
versionado.

## 4. Camada de Service + endpoints extras + validações

A camada Service não nasce do scaffold (não é convenção do Rails). Como
o enunciado pede `Controller → Service → Model` espelhando o exemplo
Java, ela entra manualmente.

### 4.1 `app/services/cliente_service.rb`

Qualquer pasta dentro de `app/` é autocarregada pelo Zeitwerk, então
basta criar `app/services/` para a classe ficar disponível. Métodos
implementados: `listar_todos`, `buscar_por_id`, `busca_por_nome`,
`contar`, `salvar`, `atualizar`, `deletar`.

### 4.2 Controller delegando para o service

O `ClientesController` passa a chamar o `ClienteService` em cada ação.
Ele continua respondendo só por HTTP: recebe params, chama o service,
devolve status + JSON. Foram adicionadas duas ações novas: `count` em
`GET /clientes/count` e `by_name` em `GET /clientes/nome/:nome`. O
`set_cliente` devolve 404 JSON quando o id não existe.

### 4.3 Rotas

```ruby
resources :clientes do
  collection do
    get :count
    get 'nome/:nome', to: 'clientes#by_name', as: :by_name
  end
end
```

`collection` mantém as 5 rotas RESTful e adiciona as duas novas no
escopo do recurso (diferente de `member`, que seria por id).

### 4.4 Validações no model

```ruby
validates :nome, presence: true
validates :email, presence: true,
                  format: { with: URI::MailTo::EMAIL_REGEXP, message: "formato inválido" }
```

`create` e `update` já retornam 422 automaticamente quando as
validações falham.

### 4.5 Rotas finais

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

Os 7 endpoints do enunciado cobertos: CRUD, contagem e busca por nome.

## 5. Diagrama e README de apresentação

Os artefatos de apresentação ficam em `diagrama.md` (4 diagramas
Mermaid: contexto C4 nível 1, componentes C4 nível 3, mapa de
endpoints, e a sequência de `POST /clientes`) e no `README.md`.

## 6. Refactors pós code review

Mudanças que entraram depois do code review (resumo, ver
`CODE_REVIEW.md` para o detalhe):

- Filtro por nome migrou de path segment para query param: a rota
  `/clientes/nome/:nome` foi removida e `index` aceita `?nome=...`.
- O service ganhou propósito real: `listar(filtros)` orquestra filtro
  + ordenação default + hard limit de 100 resultados. `atualizar`
  devolve boolean honesto (não mais a instância) para o controller
  poder usar o padrão idiomático de Rails.
- O 404 foi centralizado em `ApplicationController` via `rescue_from
  ActiveRecord::RecordNotFound`. O service voltou a usar `Cliente.find`,
  que levanta a exceção.
- Schema reforçado por nova migration: `null: false`, `limit:` em ambas
  as colunas, índice único em `lower(email)`.
- Model normaliza email (downcase + strip) e nome (strip) em
  `before_validation`; valida unicidade case-insensitive e tamanho.
- Envelope de erro padronizado em `{ errors: { ... } }`: 404 com chave
  `base`, 422 com `ActiveModel::Errors` por campo.
- Locale padrão configurado em `pt-BR`, com traduções das chaves usadas
  pela app em `config/locales/pt-BR.yml`.

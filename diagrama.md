# Diagramas

Quatro diagramas em Mermaid. Renderizam direto no GitHub/GitLab e
podem ser exportados pra PNG/SVG se precisar.

## 1. Contexto (C4 nível 1)

```mermaid
graph LR
    parceiro["Parceiro / Cliente HTTP<br/><i>consumidor da API</i>"]
    api["API de Clientes<br/>Ruby on Rails 7.1<br/><i>CRUD, contagem, busca por nome</i>"]
    db[("PostgreSQL<br/><i>persistência</i>")]

    parceiro -- "HTTPS / JSON" --> api
    api -- "SQL via Active Record" --> db
```

## 2. Componentes (C4 nível 3)

```mermaid
graph TD
    client["Cliente HTTP<br/><i>curl / Postman / parceiro</i>"]

    subgraph rails["API Rails 7.1 (modo --api)"]
        direction TB
        routes["config/routes.rb<br/><i>roteamento RESTful</i>"]
        controller["ClientesController<br/><i>traduz HTTP em chamadas de serviço</i>"]
        service["ClienteService<br/><i>filtros, ordenação, hard limit</i>"]
        model["Cliente (ActiveRecord)<br/><i>validações e busca por nome</i>"]
    end

    db[("PostgreSQL<br/>tabela <code>clientes</code>")]

    client -- "HTTP request" --> routes
    routes -- "dispatch" --> controller
    controller -- "chama métodos de domínio" --> service
    service -- "consulta / persiste" --> model
    model -- "SQL" --> db
    db -- "linhas" --> model
    model -- "objetos Cliente" --> service
    service -- "resultado" --> controller
    controller -- "render json" --> client
```

## 3. Mapa de endpoints

```mermaid
graph LR
    subgraph CRUD["CRUD (resources :clientes)"]
        e1["POST /clientes"] --> a1["create"]
        e2["GET /clientes<br/>(opcional ?nome=...)"] --> a2["index<br/><i>lista, com filtro opcional por nome</i>"]
        e3["GET /clientes/:id"] --> a3["show"]
        e4["PATCH /clientes/:id"] --> a4["update"]
        e5["DELETE /clientes/:id"] --> a5["destroy"]
    end
    subgraph Extras["Extras"]
        e6["GET /clientes/count"] --> a6["count"]
    end
```

## 4. Sequência de `POST /clientes`

```mermaid
sequenceDiagram
    autonumber
    participant C as Cliente HTTP
    participant R as Routes
    participant CT as ClientesController
    participant S as ClienteService
    participant M as Cliente (Model)
    participant DB as PostgreSQL

    C->>R: POST /clientes { nome, email }
    R->>CT: dispatch -> #create
    CT->>CT: cliente_params (strong params)
    CT->>S: salvar(atributos)
    S->>M: Cliente.create(atributos)
    M->>M: normaliza + valida (presença, formato, unicidade)
    M->>DB: INSERT INTO clientes ...
    DB-->>M: id gerado
    M-->>S: instância persistida
    S-->>CT: cliente
    alt cliente.persisted?
        CT-->>C: 201 Created + JSON
    else inválido
        CT-->>C: 422 + { errors: { campo: [...] } }
    end
```

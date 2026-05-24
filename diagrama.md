# Diagrama de Arquitetura — API de Clientes

Diagramas em **Mermaid** (renderizáveis nativamente em GitHub/GitLab e
exportáveis para PNG/SVG). A fonte de cada diagrama está no bloco de código
imediatamente abaixo do seu título.

---

## 1. Visão de Contexto (C4 — Nível 1)

Quem usa o sistema e com o que ele conversa.

```mermaid
graph LR
    parceiro["Parceiro / Cliente HTTP<br/><i>consumidor da API</i>"]
    api["API de Clientes<br/><b>Ruby on Rails 7.1</b><br/><i>expõe CRUD + count + find by name</i>"]
    db[("PostgreSQL<br/><i>persistência dos clientes</i>")]

    parceiro -- "HTTPS / JSON" --> api
    api -- "SQL via Active Record" --> db
```

---

## 2. Visão de Componentes (C4 — Nível 3) — padrão MVC

Como o request HTTP atravessa as camadas internas até chegar ao banco.

```mermaid
graph TD
    client["Cliente HTTP<br/><i>curl / Postman / parceiro</i>"]

    subgraph rails["API Rails 7.1 (modo --api)"]
        direction TB
        routes["config/routes.rb<br/><i>roteamento RESTful resourceful</i>"]
        controller["ClientesController<br/><i>app/controllers/clientes_controller.rb</i><br/>traduz HTTP &lt;-&gt; chamadas de serviço"]
        service["ClienteService<br/><i>app/services/cliente_service.rb</i><br/>regra de negócio (PORO)"]
        model["Cliente (ActiveRecord)<br/><i>app/models/cliente.rb</i><br/>validações + mapeamento ORM"]
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

---

## 3. Mapa de Endpoints

Todos os endpoints expostos e a ação do controller que os atende.

```mermaid
graph LR
    subgraph CRUD["CRUD básico (resources :clientes)"]
        e1["POST /clientes"] --> a1["create"]
        e2["GET /clientes"] --> a2["index<br/><i>find all</i>"]
        e3["GET /clientes/:id"] --> a3["show<br/><i>find by id</i>"]
        e4["PATCH /clientes/:id"] --> a4["update"]
        e5["DELETE /clientes/:id"] --> a5["destroy"]
    end
    subgraph Extras["Endpoints extras"]
        e6["GET /clientes/count"] --> a6["count<br/><i>contagem total</i>"]
        e7["GET /clientes/nome/:nome"] --> a7["by_name<br/><i>find by name (ILIKE)</i>"]
    end
```

---

## 4. Sequência — exemplo: `POST /clientes`

Fluxo de criação de um cliente, da chamada do parceiro até a resposta JSON.

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
    M->>M: validações (presence, email)
    M->>DB: INSERT INTO clientes ...
    DB-->>M: id gerado
    M-->>S: instância persistida
    S-->>CT: cliente
    alt cliente.persisted?
        CT-->>C: 201 Created + JSON
    else inválido
        CT-->>C: 422 Unprocessable Entity + errors
    end
```

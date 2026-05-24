require "test_helper"

class ClientesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @cliente = clientes(:one)
    @outro   = clientes(:two)
  end

  test "GET /clientes retorna lista (find all)" do
    get clientes_url, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_kind_of Array, body
    ids = body.map { |c| c["id"] }
    assert_includes ids, @cliente.id
    assert_includes ids, @outro.id
  end

  test "GET /clientes/:id retorna cliente (find by id)" do
    get cliente_url(@cliente), as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @cliente.nome, body["nome"]
    assert_equal @cliente.email, body["email"]
  end

  test "GET /clientes/:id retorna 404 quando id não existe" do
    get cliente_url(9999), as: :json
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_includes body["errors"]["base"], "Cliente não encontrado"
  end

  test "POST /clientes cria cliente válido" do
    assert_difference("Cliente.count", 1) do
      post clientes_url,
           params: { cliente: { nome: "Ana Lima", email: "ana@example.com" } },
           as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Ana Lima", body["nome"]
    assert_equal "ana@example.com", body["email"]
  end

  test "POST /clientes inválido devolve 422" do
    assert_no_difference("Cliente.count") do
      post clientes_url,
           params: { cliente: { nome: "Sem Email" } },
           as: :json
    end
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_includes body["errors"].keys, "email"
  end

  test "PATCH /clientes/:id atualiza cliente" do
    patch cliente_url(@cliente),
          params: { cliente: { email: "maria.nova@example.com" } },
          as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "maria.nova@example.com", body["email"]
  end

  test "DELETE /clientes/:id remove cliente" do
    assert_difference("Cliente.count", -1) do
      delete cliente_url(@cliente), as: :json
    end
    assert_response :no_content
  end

  test "GET /clientes/count retorna contagem total" do
    get count_clientes_url, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["total"]
  end

  test "GET /clientes?nome=... filtra por nome (find by name)" do
    get clientes_url(nome: "maria"), as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "Maria Silva", body.first["nome"]
  end

  test "GET /clientes?nome=... é case-insensitive e parcial" do
    get clientes_url(nome: "SIL"), as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "Maria Silva", body.first["nome"]
  end

  test "GET /clientes?nome=... sem match retorna lista vazia" do
    get clientes_url(nome: "inexistente"), as: :json
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end
end

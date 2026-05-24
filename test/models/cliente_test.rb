require "test_helper"

class ClienteTest < ActiveSupport::TestCase
  # --- Caso feliz ---

  test "cliente com nome e email válidos é válido" do
    cliente = Cliente.new(nome: "Maria Silva", email: "maria@example.com")
    assert cliente.valid?, "Esperava válido, erros: #{cliente.errors.full_messages}"
  end

  test "cliente válido persiste no banco" do
    assert_difference("Cliente.count", 1) do
      Cliente.create!(nome: "Ana", email: "ana@example.com")
    end
  end

  test "timestamps são preenchidos automaticamente ao criar" do
    cliente = Cliente.create!(nome: "Pedro", email: "pedro@example.com")
    assert_not_nil cliente.created_at
    assert_not_nil cliente.updated_at
  end

  # --- Validação: nome ---

  test "é inválido sem nome" do
    cliente = Cliente.new(email: "x@example.com")
    assert_not cliente.valid?
    assert_includes cliente.errors[:nome], "can't be blank"
  end

  test "é inválido com nome em branco (string vazia)" do
    cliente = Cliente.new(nome: "", email: "x@example.com")
    assert_not cliente.valid?
    assert_includes cliente.errors[:nome], "can't be blank"
  end

  # --- Validação: email presença ---

  test "é inválido sem email" do
    cliente = Cliente.new(nome: "Sem Email")
    assert_not cliente.valid?
    assert_includes cliente.errors[:email], "can't be blank"
  end

  # --- Validação: email formato ---

  test "é inválido com email sem @" do
    cliente = Cliente.new(nome: "X", email: "nao-eh-email")
    assert_not cliente.valid?
    assert_includes cliente.errors[:email], "formato inválido"
  end

  test "é inválido com email sem domínio" do
    cliente = Cliente.new(nome: "X", email: "x@")
    assert_not cliente.valid?
    assert_includes cliente.errors[:email], "formato inválido"
  end

  test "é inválido com email sem usuário" do
    cliente = Cliente.new(nome: "X", email: "@example.com")
    assert_not cliente.valid?
    assert_includes cliente.errors[:email], "formato inválido"
  end

  test "aceita email com subdomínio" do
    cliente = Cliente.new(nome: "X", email: "user@mail.example.com")
    assert cliente.valid?, cliente.errors.full_messages.to_s
  end

  test "aceita email com plus addressing" do
    cliente = Cliente.new(nome: "X", email: "user+tag@example.com")
    assert cliente.valid?, cliente.errors.full_messages.to_s
  end

  # --- Múltiplos erros ---

  test "acumula erros de nome e email quando ambos faltam" do
    cliente = Cliente.new
    assert_not cliente.valid?
    assert_includes cliente.errors[:nome],  "can't be blank"
    assert_includes cliente.errors[:email], "can't be blank"
  end

  # --- Fixtures ---

  test "fixtures :one e :two são válidas" do
    assert clientes(:one).valid?,  "fixture :one inválida: #{clientes(:one).errors.full_messages}"
    assert clientes(:two).valid?,  "fixture :two inválida: #{clientes(:two).errors.full_messages}"
  end

  # --- Atualização ---

  test "atualização com email inválido falha" do
    cliente = clientes(:one)
    cliente.email = "invalido"
    assert_not cliente.valid?
    assert_includes cliente.errors[:email], "formato inválido"
  end

  # --- buscar_por_nome — edge cases ---
  # Fixtures presentes em cada teste: :one (Maria Silva), :two (João Souza)

  test "buscar_por_nome retorna match exato" do
    resultado = Cliente.buscar_por_nome("Maria")
    assert_equal 1, resultado.count
    assert_equal "Maria Silva", resultado.first.nome
  end

  test "buscar_por_nome é case-insensitive" do
    resultado = Cliente.buscar_por_nome("MARIA")
    assert_equal 1, resultado.count
  end

  test "buscar_por_nome faz match parcial" do
    resultado = Cliente.buscar_por_nome("Sil")
    assert_equal 1, resultado.count
    assert_equal "Maria Silva", resultado.first.nome
  end

  test "buscar_por_nome retorna múltiplos matches" do
    Cliente.create!(nome: "Pedro Silva", email: "pedro@example.com")
    resultado = Cliente.buscar_por_nome("Silva")
    assert_equal 2, resultado.count
    nomes = resultado.pluck(:nome).sort
    assert_equal ["Maria Silva", "Pedro Silva"], nomes
  end

  test "buscar_por_nome sem match retorna relation vazia" do
    resultado = Cliente.buscar_por_nome("inexistente")
    assert_equal 0, resultado.count
  end

  # --- escape de curingas SQL ---

  test "buscar_por_nome trata '%' como caractere literal (não curinga)" do
    Cliente.create!(nome: "Promo 50%", email: "promo@example.com")
    # Buscar por "%" sozinho NÃO deve retornar tudo — apenas nomes com '%' literal
    resultado = Cliente.buscar_por_nome("%")
    assert_equal 1, resultado.count
    assert_equal "Promo 50%", resultado.first.nome
  end

  test "buscar_por_nome trata '_' como caractere literal (não curinga)" do
    Cliente.create!(nome: "user_name",  email: "u1@example.com")
    Cliente.create!(nome: "userxname",  email: "u2@example.com")
    # 'user_name' deve casar APENAS 'user_name' (e não 'userxname')
    resultado = Cliente.buscar_por_nome("user_name")
    assert_equal 1, resultado.count
    assert_equal "user_name", resultado.first.nome
  end

  test "buscar_por_nome trata backslash como caractere literal" do
    Cliente.create!(nome: 'foo\\bar', email: "fb@example.com")
    Cliente.create!(nome: 'foobar',   email: "b@example.com")
    resultado = Cliente.buscar_por_nome('foo\\bar')
    assert_equal 1, resultado.count
    assert_equal 'foo\\bar', resultado.first.nome
  end

  # --- entradas vazias / nulas ---

  test "buscar_por_nome com string vazia retorna relation vazia" do
    # Sem o early-return, ILIKE '%%' casaria com todos os registros — bug.
    assert_equal 0, Cliente.buscar_por_nome("").count
  end

  test "buscar_por_nome com whitespace puro retorna relation vazia" do
    assert_equal 0, Cliente.buscar_por_nome("   ").count
  end

  test "buscar_por_nome com nil retorna relation vazia (não lança exceção)" do
    assert_nothing_raised do
      assert_equal 0, Cliente.buscar_por_nome(nil).count
    end
  end

  # --- acentos: comportamento atual (ILIKE não normaliza diacríticos) ---

  test "buscar_por_nome com acento bate apenas com forma acentuada (limitação documentada)" do
    # ILIKE no PostgreSQL é case-insensitive mas não accent-insensitive.
    # Para suporte a acentos seria necessário a extensão `unaccent`.
    assert_equal 1, Cliente.buscar_por_nome("João").count
    assert_equal 0, Cliente.buscar_por_nome("Joao").count
  end

  # --- contrato: tipo de retorno ---

  test "buscar_por_nome retorna ActiveRecord::Relation (encadeável)" do
    relation = Cliente.buscar_por_nome("Silva")
    assert_kind_of ActiveRecord::Relation, relation
    # Permite encadear ainda outros where/order/limit
    assert_equal 1, relation.order(:nome).limit(1).count
  end
end

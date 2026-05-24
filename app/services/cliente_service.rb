class ClienteService
  DEFAULT_ORDER = :nome

  # Hard limit em vez de paginação real, na prática
  # trocar por uma gem como kaminari ou pagy.
  MAX_RESULTADOS = 100

  def self.listar(filtros = {})
    scope = Cliente.all
    scope = scope.busca_por_nome(filtros[:nome]) if filtros[:nome].present?
    scope.order(DEFAULT_ORDER).limit(MAX_RESULTADOS)
  end

  def self.contar
    Cliente.count
  end

  def self.buscar_por_id(id)
    Cliente.find(id)
  end

  def self.salvar(atributos)
    Cliente.create(atributos)
  end

  def self.atualizar(cliente, atributos)
    cliente.update(atributos)
  end

  def self.deletar(cliente)
    cliente.destroy
  end
end

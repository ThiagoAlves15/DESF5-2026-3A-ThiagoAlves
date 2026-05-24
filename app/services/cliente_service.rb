class ClienteService
  def self.listar_todos
    Cliente.all
  end

  def self.buscar_por_id(id)
    Cliente.find_by(id: id)
  end

  def self.buscar_por_nome(nome)
    Cliente.buscar_por_nome(nome)
  end

  def self.contar
    Cliente.count
  end

  def self.salvar(atributos)
    Cliente.create(atributos)
  end

  def self.atualizar(cliente, atributos)
    cliente.update(atributos)
    cliente
  end

  def self.deletar(cliente)
    cliente.destroy
  end
end

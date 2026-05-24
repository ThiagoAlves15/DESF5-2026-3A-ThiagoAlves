class ClientesController < ApplicationController
  before_action :set_cliente, only: %i[show update destroy]

  # GET /clientes
  def index
    render json: ClienteService.listar_todos
  end

  # GET /clientes/:id
  def show
    render json: @cliente
  end

  # GET /clientes/count
  def count
    render json: { total: ClienteService.contar }
  end

  # GET /clientes/nome/:nome
  def by_name
    render json: ClienteService.buscar_por_nome(params[:nome])
  end

  # POST /clientes
  def create
    cliente = ClienteService.salvar(cliente_params)
    if cliente.persisted?
      render json: cliente, status: :created, location: cliente
    else
      render json: cliente.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clientes/:id
  def update
    if ClienteService.atualizar(@cliente, cliente_params).errors.empty?
      render json: @cliente
    else
      render json: @cliente.errors, status: :unprocessable_entity
    end
  end

  # DELETE /clientes/:id
  def destroy
    ClienteService.deletar(@cliente)
    head :no_content
  end

  private

  def set_cliente
    @cliente = ClienteService.buscar_por_id(params[:id])
    render json: { error: "Cliente não encontrado" }, status: :not_found if @cliente.nil?
  end

  def cliente_params
    params.require(:cliente).permit(:nome, :email)
  end
end

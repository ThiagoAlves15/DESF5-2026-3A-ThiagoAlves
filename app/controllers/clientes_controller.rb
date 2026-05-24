class ClientesController < ApplicationController
  before_action :set_cliente, only: %i[show update destroy]

  def index
    render json: ClienteService.listar(nome: params[:nome])
  end

  def show
    render json: @cliente
  end

  def count
    render json: { total: ClienteService.contar }
  end

  def create
    cliente = ClienteService.salvar(cliente_params)
    if cliente.persisted?
      render json: cliente, status: :created, location: cliente
    else
      render json: { errors: cliente.errors }, status: :unprocessable_entity
    end
  end

  def update
    if ClienteService.atualizar(@cliente, cliente_params)
      render json: @cliente
    else
      render json: { errors: @cliente.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    ClienteService.deletar(@cliente)
    head :no_content
  end

  private

  def set_cliente
    @cliente = ClienteService.buscar_por_id(params[:id])
  end

  def cliente_params
    params.require(:cliente).permit(:nome, :email)
  end
end

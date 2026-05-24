class Cliente < ApplicationRecord
  LIKE_WILDCARDS = /[\\%_]/.freeze

  before_validation :normalizar_parametros

  validates :nome,  presence: true, length: { maximum: 120 }
  validates :email, presence: true,
                    length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "formato inválido" },
                    uniqueness: { case_sensitive: false }

  def self.busca_por_nome(nome)
    return none if nome.blank?

    termo = nome.gsub(LIKE_WILDCARDS) { |c| "\\#{c}" }
    where("nome ILIKE ?", "%#{termo}%")
  end

  private

  def normalizar_parametros
    self.email = email.downcase.strip if email
    self.nome  = nome.strip if nome
  end
end

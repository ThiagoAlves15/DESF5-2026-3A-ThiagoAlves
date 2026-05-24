class Cliente < ApplicationRecord
  validates :nome, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "formato inválido" }

  def self.buscar_por_nome(nome)
    return none if nome.blank?

    termo = nome.gsub(/[\\%_]/) { |c| "\\#{c}" }
    where("nome ILIKE ?", "%#{termo}%")
  end
end

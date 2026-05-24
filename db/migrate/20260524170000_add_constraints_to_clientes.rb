class AddConstraintsToClientes < ActiveRecord::Migration[7.1]
  def up
    change_column :clientes, :nome,  :string, null: false, limit: 120
    change_column :clientes, :email, :string, null: false, limit: 254

    add_index :clientes, "lower(email)", unique: true, name: "index_clientes_on_lower_email"
  end

  def down
    remove_index :clientes, name: "index_clientes_on_lower_email"
    change_column :clientes, :email, :string
    change_column :clientes, :nome,  :string
  end
end

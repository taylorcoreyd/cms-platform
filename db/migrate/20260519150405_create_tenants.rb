class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :domain

      t.timestamps
    end

    add_index :tenants, :domain, unique: true
  end
end

class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :domain

      t.timestamps
    end
    add_index :companies, :domain
  end
end

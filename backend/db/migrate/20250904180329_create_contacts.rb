class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :email

      t.timestamps
    end
    add_index :contacts, :email
  end
end

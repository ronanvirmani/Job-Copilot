class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :supabase_user_id
      t.string :email
      t.text :google_access_token
      t.text :google_refresh_token
      t.datetime :token_expires_at
      t.string :gmail_history_id

      t.timestamps
    end
    add_index :users, :supabase_user_id
  end
end

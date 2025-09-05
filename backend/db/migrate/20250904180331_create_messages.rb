class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :application, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :gmail_message_id
      t.string :gmail_thread_id
      t.string :from_addr
      t.string :to_addr
      t.string :subject
      t.text :snippet
      t.string :classification
      t.datetime :internal_ts
      t.jsonb :raw_headers
      t.jsonb :parts_metadata

      t.timestamps
    end
    add_index :messages, :gmail_message_id
    add_index :messages, :gmail_thread_id
  end
end

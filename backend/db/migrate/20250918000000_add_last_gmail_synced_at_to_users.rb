class AddLastGmailSyncedAtToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_gmail_synced_at, :datetime
    add_index :users, :last_gmail_synced_at
  end
end

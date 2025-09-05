class AddAppDedupeIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :applications, [:user_id, :company_id, :role_title], unique: true, name: "idx_apps_dedupe"
  end
end

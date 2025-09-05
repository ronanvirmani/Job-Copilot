class CreateApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :applications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :role_title
      t.string :location
      t.string :source
      t.string :job_url
      t.string :status
      t.datetime :applied_at
      t.datetime :last_email_at
      t.datetime :last_status_change_at
      t.text :notes

      t.timestamps
    end
  end
end

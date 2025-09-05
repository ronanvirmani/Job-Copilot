class CreateApplicationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :application_events do |t|
      t.references :application, null: false, foreign_key: true
      t.string :event_type
      t.jsonb :payload
      t.datetime :occurred_at

      t.timestamps
    end
  end
end

class CreateMitigations < ActiveRecord::Migration[8.0]
  def change
    create_table :mitigations do |t|
      t.references :observation, null: false, foreign_key: true
      t.jsonb :response_data
      t.datetime :submitted_at
      t.string :status
      t.string :request_id

      t.timestamps
    end

    add_index :mitigations, :response_data, using: :gin
    add_index :mitigations, :submitted_at
    add_index :mitigations, :status
  end
end

class CreateObservations < ActiveRecord::Migration[8.0]
  def change
    create_table :observations do |t|
      t.json :observations
      t.text :notes
      t.datetime :recorded_at
      t.references :property, null: false, foreign_key: true

      t.timestamps
    end
  end
end

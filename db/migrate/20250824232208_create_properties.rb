class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :property_type, null: false
      t.string :status, null: false, default: 'pending'
      t.string :street_address, null: false
      t.string :city, null: false
      t.string :state_province
      t.string :postal_code
      t.string :country, null: false, default: 'US'
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.text :normalized_address

      t.timestamps
    end

    add_index :properties, [:latitude, :longitude]
    add_index :properties, :city
    add_index :properties, :property_type
    add_index :properties, :status
  end
end

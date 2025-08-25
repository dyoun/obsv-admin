# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_25_200539) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "mitigations", force: :cascade do |t|
    t.bigint "observation_id", null: false
    t.jsonb "response_data"
    t.datetime "submitted_at"
    t.string "status"
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observation_id"], name: "index_mitigations_on_observation_id"
    t.index ["response_data"], name: "index_mitigations_on_response_data", using: :gin
    t.index ["status"], name: "index_mitigations_on_status"
    t.index ["submitted_at"], name: "index_mitigations_on_submitted_at"
  end

  create_table "observations", force: :cascade do |t|
    t.json "observations"
    t.text "notes"
    t.datetime "recorded_at"
    t.bigint "property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_observations_on_property_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "property_type", null: false
    t.string "status", default: "pending", null: false
    t.string "street_address", null: false
    t.string "city", null: false
    t.string "state_province"
    t.string "postal_code"
    t.string "country", default: "US", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.text "normalized_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_properties_on_city"
    t.index ["latitude", "longitude"], name: "index_properties_on_latitude_and_longitude"
    t.index ["property_type"], name: "index_properties_on_property_type"
    t.index ["status"], name: "index_properties_on_status"
  end

  add_foreign_key "mitigations", "observations"
  add_foreign_key "observations", "properties"
end

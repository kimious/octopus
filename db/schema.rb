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

ActiveRecord::Schema[8.0].define(version: 2025_07_15_063651) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "blobs", force: :cascade do |t|
    t.string "kind", null: false
    t.jsonb "metadata", default: "{}", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_blobs_on_kind"
  end

  create_table "workflow_instances", force: :cascade do |t|
    t.bigint "workflow_id", null: false
    t.jsonb "schema", null: false
    t.string "status", null: false
    t.jsonb "state", null: false
    t.jsonb "context", null: false
    t.jsonb "args", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_workflow_instances_on_status"
    t.index ["workflow_id"], name: "index_workflow_instances_on_workflow_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.jsonb "schema", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "workflow_instances", "workflows"
end

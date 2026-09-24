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

ActiveRecord::Schema[8.1].define(version: 2026_09_24_130000) do
  create_table "easy_flow_definitions", force: :cascade do |t|
    t.string "slug"
    t.string "title"
    t.string "start_label"
    t.string "kind"
    t.string "status", default: "active", null: false
    t.string "persists", default: "unsaved", null: false
    t.json "document"
    t.integer "definition_cursor"
    t.json "changes_since_version"
    t.json "undo_history"
    t.json "undone_changes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "host", null: false
    t.index ["host", "slug"], name: "index_easy_flow_definitions_on_host_and_slug", unique: true
  end

  create_table "easy_flow_runs", force: :cascade do |t|
    t.integer "flow_id", null: false
    t.integer "definition_version_id", null: false
    t.string "owner_type"
    t.integer "owner_id"
    t.json "recorded"
    t.string "label"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["definition_version_id"], name: "index_easy_flow_runs_on_definition_version_id"
    t.index ["flow_id"], name: "index_easy_flow_runs_on_flow_id"
    t.index ["owner_type", "owner_id"], name: "index_easy_flow_runs_on_owner"
  end

  create_table "easy_flow_versions", force: :cascade do |t|
    t.integer "flow_id", null: false
    t.integer "number", null: false
    t.json "definition"
    t.json "changes_captured"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.index ["flow_id", "number"], name: "index_easy_flow_versions_on_flow_id_and_number", unique: true
    t.index ["flow_id"], name: "index_easy_flow_versions_on_flow_id"
    t.index ["flow_id"], name: "index_easy_flow_versions_on_one_live_per_flow", unique: true, where: "status = 'live'"
  end

  add_foreign_key "easy_flow_runs", "easy_flow_definitions", column: "flow_id"
  add_foreign_key "easy_flow_runs", "easy_flow_versions", column: "definition_version_id"
  add_foreign_key "easy_flow_versions", "easy_flow_definitions", column: "flow_id"
end

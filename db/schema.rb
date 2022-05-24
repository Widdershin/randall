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

ActiveRecord::Schema[7.0].define(version: 2022_05_24_133443) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.text "name", null: false
    t.bigint "tournament_id", null: false
    t.integer "start_gg_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_events_on_tournament_id"
  end

  create_table "players", force: :cascade do |t|
    t.text "sponsor", null: false
    t.text "tag", null: false
    t.integer "start_gg_id", null: false
    t.integer "points", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "point_changes", force: :cascade do |t|
    t.text "cause", null: false
    t.integer "point_change", null: false
    t.bigint "player_id", null: false
    t.bigint "event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_point_changes_on_event_id"
    t.index ["player_id"], name: "index_point_changes_on_player_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.text "name", null: false
    t.text "slug", null: false
    t.text "url", null: false
    t.integer "start_gg_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

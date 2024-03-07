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

ActiveRecord::Schema[7.1].define(version: 2024_03_07_130915) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cards", force: :cascade do |t|
    t.string "name"
    t.string "oracle_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "price_entries", force: :cascade do |t|
    t.float "usd"
    t.float "eur"
    t.float "tix"
    t.bigint "card_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_price_entries_on_card_id"
  end

  create_table "pscore_calculations", force: :cascade do |t|
    t.float "overall7"
    t.float "overall7_trend"
    t.float "overall30"
    t.float "overall30_trend"
    t.float "standard7"
    t.float "standard7_trend"
    t.float "standard30"
    t.float "standard30_trend"
    t.float "pioneer7"
    t.float "pioneer7_trend"
    t.float "pioneer30"
    t.float "pioneer30_trend"
    t.float "modern7"
    t.float "modern7_trend"
    t.float "modern30"
    t.float "modern30_trend"
    t.float "pauper7"
    t.float "pauper7_trend"
    t.float "pauper30"
    t.float "pauper30_trend"
    t.float "legacy7"
    t.float "legacy7_trend"
    t.float "legacy30"
    t.float "legacy30_trend"
    t.bigint "card_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_pscore_calculations_on_card_id"
  end

  create_table "pscore_entries", force: :cascade do |t|
    t.float "standard"
    t.float "legacy"
    t.float "modern"
    t.float "pauper"
    t.float "pioneer"
    t.bigint "card_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_pscore_entries_on_card_id"
  end

end

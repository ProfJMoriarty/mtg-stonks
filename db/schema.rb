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

ActiveRecord::Schema[7.1].define(version: 20_240_301_132_558) do # rubocop:disable Metrics/BlockLength
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'cards', force: :cascade do |t|
    t.string 'name'
    t.string 'oracle_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'price_entries', force: :cascade do |t|
    t.float 'usd'
    t.float 'eur'
    t.float 'tix'
    t.bigint 'card_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['card_id'], name: 'index_price_entries_on_card_id'
  end

  create_table 'pscore_entries', force: :cascade do |t|
    t.float 'standard'
    t.float 'legacy'
    t.float 'modern'
    t.float 'pauper'
    t.float 'pioneer'
    t.bigint 'card_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['card_id'], name: 'index_pscore_entries_on_card_id'
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_07_26_151156) do

  create_table "terms", force: :cascade do |t|
    t.integer "vocabulary_id", null: false
    t.string "pref_label", null: false
    t.text "alt_labels"
    t.string "uri", null: false
    t.string "uri_hash", null: false
    t.string "authority"
    t.string "term_type", null: false
    t.text "custom_fields"
    t.string "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri_hash", "vocabulary_id"], name: "index_terms_on_uri_hash_and_vocabulary_id", unique: true
    t.index ["uuid"], name: "index_terms_on_uuid", unique: true
    t.index ["vocabulary_id"], name: "index_terms_on_vocabulary_id"
  end

  create_table "vocabularies", force: :cascade do |t|
    t.string "label", null: false
    t.string "string_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_fields"
    t.index ["string_key"], name: "index_vocabularies_on_string_key", unique: true
  end

end

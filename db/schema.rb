# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151230210846) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "instruments", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "site_id"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "display_points",                  default: 20
    t.integer  "sample_rate_seconds",             default: 5
    t.text     "last_url"
    t.text     "description"
  end

  add_index "instruments", ["site_id"], name: "index_instruments_on_site_id", using: :btree

  create_table "measured_properties", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "label",      limit: 255
    t.string   "url",        limit: 255
    t.text     "definition"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "measurements", force: :cascade do |t|
    t.integer  "instrument_id"
    t.string   "parameter",     limit: 255
    t.float    "value"
    t.string   "unit",          limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.datetime "measured_at"
    t.boolean  "test",                      default: false, null: false
  end

  add_index "measurements", ["instrument_id"], name: "index_measurements_on_instrument_id", using: :btree
  add_index "measurements", ["measured_at"], name: "index_measurements_on_measured_at", using: :btree

  create_table "profiles", force: :cascade do |t|
    t.string   "project",               limit: 255
    t.string   "affiliation",           limit: 255
    t.string   "description",           limit: 1000
    t.binary   "logo"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "timezone",              limit: 255
    t.boolean  "secure_administration",              default: true
    t.boolean  "secure_data_viewing",                default: true
    t.boolean  "secure_data_download",               default: true
    t.boolean  "secure_data_entry",                  default: true
    t.string   "data_entry_key",        limit: 255
  end

  create_table "sites", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.float    "lat"
    t.float    "lon"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.text     "description"
    t.float    "elevation",               default: 0.0
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "is_administrator",                   default: false
    t.boolean  "is_data_viewer",                     default: true
    t.boolean  "is_data_downloader",                 default: true
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vars", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.integer  "instrument_id"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "shortname",            limit: 255
    t.string   "units",                limit: 255, default: "C", null: false
    t.integer  "measured_property_id",             default: 795, null: false
  end

  add_index "vars", ["instrument_id"], name: "index_vars_on_instrument_id", using: :btree
  add_index "vars", ["measured_property_id"], name: "index_vars_on_measured_property_id", using: :btree

  add_foreign_key "instruments", "sites"
  add_foreign_key "measurements", "instruments"
  add_foreign_key "vars", "instruments"
end

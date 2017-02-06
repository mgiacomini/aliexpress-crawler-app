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

ActiveRecord::Schema.define(version: 20170206133524) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aliexpresses", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crawler_logs", force: :cascade do |t|
    t.integer  "crawler_id"
    t.string   "message",      default: ""
    t.integer  "processed",    default: 0
    t.integer  "orders_count", default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "crawler_logs", ["crawler_id"], name: "index_crawler_logs_on_crawler_id", using: :btree

  create_table "crawlers", force: :cascade do |t|
    t.integer  "aliexpress_id"
    t.integer  "wordpress_id"
    t.boolean  "enabled",       default: false
    t.string   "schedule",      default: "daily"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "crawlers", ["aliexpress_id"], name: "index_crawlers_on_aliexpress_id", using: :btree
  add_index "crawlers", ["wordpress_id"], name: "index_crawlers_on_wordpress_id", using: :btree

  create_table "product_types", force: :cascade do |t|
    t.string   "name"
    t.string   "aliexpress_link"
    t.integer  "product_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "option_1"
    t.integer  "option_2"
    t.integer  "option_3"
    t.string   "shipping",        default: ""
    t.integer  "product_errors"
  end

  add_index "product_types", ["product_id"], name: "index_product_types_on_product_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.string   "link"
    t.integer  "wordpress_id"
    t.string   "aliexpress_link"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "id_at_wordpress"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wordpresses", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "consumer_key"
    t.string   "consumer_secret"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_foreign_key "crawler_logs", "crawlers"
  add_foreign_key "crawlers", "aliexpresses"
  add_foreign_key "crawlers", "wordpresses"
  add_foreign_key "product_types", "products"
end

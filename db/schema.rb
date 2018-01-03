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

ActiveRecord::Schema.define(version: 20180103025904) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brick_owl_values", force: :cascade do |t|
    t.datetime "retrieved_at"
    t.float "part_out_value_new"
    t.float "part_out_value_used"
    t.float "current_avg_price"
    t.float "current_high_price"
    t.float "current_low_price"
    t.integer "current_listings"
    t.integer "lego_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lego_set_id"], name: "index_brick_owl_values_on_lego_set_id"
  end

  create_table "ebay_sales", force: :cascade do |t|
    t.datetime "date"
    t.float "avg_sales"
    t.float "high_sale"
    t.float "low_sale"
    t.integer "listings"
    t.integer "lego_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lego_set_id"], name: "index_ebay_sales_on_lego_set_id"
  end

  create_table "lego_sets", force: :cascade do |t|
    t.string "title"
    t.string "number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "msrp"
    t.integer "year"
    t.integer "part_count"
    t.string "brick_owl_url"
    t.string "number_variant"
    t.string "brickset_url"
    t.integer "minifig_count"
    t.boolean "released"
    t.string "packaging_type"
    t.integer "instructions_count"
    t.index ["number", "number_variant"], name: "index_lego_sets_on_number_and_number_variant", unique: true
  end

end

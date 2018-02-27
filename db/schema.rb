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

ActiveRecord::Schema.define(version: 20180227031413) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brick_owl_values", force: :cascade do |t|
    t.datetime "retrieved_at"
    t.float "part_out_value_new"
    t.float "part_out_value_used"
    t.bigint "lego_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "complete_set_new_listings_count"
    t.float "complete_set_new_avg_price"
    t.float "complete_set_new_median_price"
    t.float "complete_set_new_high_price"
    t.float "complete_set_new_low_price"
    t.integer "complete_set_used_listings_count"
    t.float "complete_set_used_avg_price"
    t.float "complete_set_used_median_price"
    t.float "complete_set_used_high_price"
    t.float "complete_set_used_low_price"
    t.integer "instructions_listings_count"
    t.float "instructions_median_price"
    t.float "instructions_avg_price"
    t.float "instructions_high_price"
    t.float "instructions_low_price"
    t.integer "packaging_listings_count"
    t.float "packaging_median_price"
    t.float "packaging_avg_price"
    t.float "packaging_high_price"
    t.float "packaging_low_price"
    t.integer "sticker_listings_count"
    t.float "sticker_median_price"
    t.float "sticker_avg_price"
    t.float "sticker_high_price"
    t.float "sticker_low_price"
    t.float "total_minifigure_value_high"
    t.float "total_minifigure_value_low"
    t.float "total_minifigure_value_avg"
    t.float "total_minifigure_value_median"
    t.boolean "most_recent", default: false, null: false
    t.integer "complete_set_completed_listing_new_listings_count"
    t.float "complete_set_completed_listing_new_avg_price"
    t.float "complete_set_completed_listing_new_median_price"
    t.float "complete_set_completed_listing_new_high_price"
    t.float "complete_set_completed_listing_new_low_price"
    t.integer "complete_set_completed_listing_used_listings_count"
    t.float "complete_set_completed_listing_used_avg_price"
    t.float "complete_set_completed_listing_used_median_price"
    t.float "complete_set_completed_listing_used_high_price"
    t.float "complete_set_completed_listing_used_low_price"
    t.index ["lego_set_id"], name: "index_brick_owl_values_on_lego_set_id"
    t.index ["most_recent"], name: "index_brick_owl_values_on_most_recent", where: "most_recent"
  end

  create_table "bricklink_values", force: :cascade do |t|
    t.datetime "retrieved_at"
    t.integer "complete_set_new_listings_count"
    t.float "complete_set_new_avg_price"
    t.float "complete_set_new_median_price"
    t.float "complete_set_new_high_price"
    t.float "complete_set_new_low_price"
    t.integer "complete_set_used_listings_count"
    t.float "complete_set_used_avg_price"
    t.float "complete_set_used_median_price"
    t.float "complete_set_used_high_price"
    t.float "complete_set_used_low_price"
    t.integer "complete_set_completed_listing_new_listings_count"
    t.float "complete_set_completed_listing_new_avg_price"
    t.float "complete_set_completed_listing_new_median_price"
    t.float "complete_set_completed_listing_new_high_price"
    t.float "complete_set_completed_listing_new_low_price"
    t.integer "complete_set_completed_listing_used_listings_count"
    t.float "complete_set_completed_listing_used_avg_price"
    t.float "complete_set_completed_listing_used_median_price"
    t.float "complete_set_completed_listing_used_high_price"
    t.float "complete_set_completed_listing_used_low_price"
    t.float "part_out_value_last_six_months_used"
    t.float "part_out_value_last_six_months_new"
    t.float "part_out_value_current_used"
    t.float "part_out_value_current_new"
    t.boolean "most_recent", default: false, null: false
    t.bigint "lego_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lego_set_id"], name: "index_bricklink_values_on_lego_set_id"
    t.index ["most_recent"], name: "index_bricklink_values_on_most_recent", where: "most_recent"
  end

  create_table "ebay_values", force: :cascade do |t|
    t.datetime "retrieved_at"
    t.integer "complete_set_completed_listing_used_listings_count"
    t.float "complete_set_completed_listing_used_avg_price"
    t.float "complete_set_completed_listing_used_median_price"
    t.float "complete_set_completed_listing_used_high_price"
    t.float "complete_set_completed_listing_used_low_price"
    t.float "complete_set_completed_listing_used_time_on_market_low"
    t.float "complete_set_completed_listing_used_time_on_market_high"
    t.float "complete_set_completed_listing_used_time_on_market_avg"
    t.float "complete_set_completed_listing_used_time_on_market_median"
    t.integer "complete_set_completed_listing_new_listings_count"
    t.float "complete_set_completed_listing_new_avg_price"
    t.float "complete_set_completed_listing_new_median_price"
    t.float "complete_set_completed_listing_new_high_price"
    t.float "complete_set_completed_listing_new_low_price"
    t.float "complete_set_completed_listing_new_time_on_market_low"
    t.float "complete_set_completed_listing_new_time_on_market_high"
    t.float "complete_set_completed_listing_new_time_on_market_avg"
    t.float "complete_set_completed_listing_new_time_on_market_median"
    t.boolean "most_recent", default: false, null: false
    t.bigint "lego_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "complete_set_used_listings_count"
    t.float "complete_set_used_avg_price"
    t.float "complete_set_used_median_price"
    t.float "complete_set_used_high_price"
    t.float "complete_set_used_low_price"
    t.integer "complete_set_new_listings_count"
    t.float "complete_set_new_avg_price"
    t.float "complete_set_new_median_price"
    t.float "complete_set_new_high_price"
    t.float "complete_set_new_low_price"
    t.index ["lego_set_id"], name: "index_ebay_values_on_lego_set_id"
    t.index ["most_recent"], name: "index_ebay_values_on_most_recent", where: "most_recent"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.datetime "retrieved_at"
    t.jsonb "rates"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "brick_owl_item_id"
    t.boolean "has_variants", default: false, null: false
    t.index ["number", "number_variant"], name: "index_lego_sets_on_number_and_number_variant", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "plus_member", default: false, null: false
    t.jsonb "preferences", default: {}, null: false
    t.string "stripe_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plus_member"], name: "index_users_on_plus_member"
  end

  add_foreign_key "brick_owl_values", "lego_sets"
  add_foreign_key "bricklink_values", "lego_sets"
  add_foreign_key "ebay_values", "lego_sets"
end

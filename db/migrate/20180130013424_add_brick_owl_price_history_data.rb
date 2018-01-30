class AddBrickOwlPriceHistoryData < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :brick_owl_item_id, :string

    add_column :brick_owl_values, :complete_set_completed_listing_new_listings_count, :integer
    add_column :brick_owl_values, :complete_set_completed_listing_new_avg_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_new_median_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_new_high_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_new_low_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_used_listings_count, :integer
    add_column :brick_owl_values, :complete_set_completed_listing_used_avg_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_used_median_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_used_high_price, :float
    add_column :brick_owl_values, :complete_set_completed_listing_used_low_price, :float
  end
end

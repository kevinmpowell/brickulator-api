class AddFieldsToBrickOwlValues < ActiveRecord::Migration[5.1]
  def change
    add_column :brick_owl_values, :complete_set_new_listings_count, :integer
    add_column :brick_owl_values, :complete_set_new_avg_price, :float
    add_column :brick_owl_values, :complete_set_new_median_price, :float
    add_column :brick_owl_values, :complete_set_new_high_price, :float
    add_column :brick_owl_values, :complete_set_new_low_price, :float
    add_column :brick_owl_values, :complete_set_used_listings_count, :integer
    add_column :brick_owl_values, :complete_set_used_avg_price, :float
    add_column :brick_owl_values, :complete_set_used_median_price, :float
    add_column :brick_owl_values, :complete_set_used_high_price, :float
    add_column :brick_owl_values, :complete_set_used_low_price, :float
    add_column :brick_owl_values, :instructions_listings_count, :integer
    add_column :brick_owl_values, :instructions_median_price, :float
    add_column :brick_owl_values, :instructions_avg_price, :float
    add_column :brick_owl_values, :instructions_high_price, :float
    add_column :brick_owl_values, :instructions_low_price, :float
    add_column :brick_owl_values, :packaging_listings_count, :integer
    add_column :brick_owl_values, :packaging_median_price, :float
    add_column :brick_owl_values, :packaging_avg_price, :float
    add_column :brick_owl_values, :packaging_high_price, :float
    add_column :brick_owl_values, :packaging_low_price, :float
    add_column :brick_owl_values, :sticker_listings_count, :integer
    add_column :brick_owl_values, :sticker_median_price, :float
    add_column :brick_owl_values, :sticker_avg_price, :float
    add_column :brick_owl_values, :sticker_high_price, :float
    add_column :brick_owl_values, :sticker_low_price, :float
    add_column :brick_owl_values, :total_minifigure_value_high, :float
    add_column :brick_owl_values, :total_minifigure_value_low, :float
    add_column :brick_owl_values, :total_minifigure_value_avg, :float
    add_column :brick_owl_values, :total_minifigure_value_median, :float

    remove_column :brick_owl_values, :current_avg_price, :float
    remove_column :brick_owl_values, :current_high_price, :float
    remove_column :brick_owl_values, :current_low_price, :float
    remove_column :brick_owl_values, :current_listings, :integer
  end
end

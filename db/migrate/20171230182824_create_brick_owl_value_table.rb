class CreateBrickOwlValueTable < ActiveRecord::Migration[5.1]
  def change
    create_table :brick_owl_values do |t|
      t.datetime :retrieved_at
      t.float :part_out_value_new
      t.float :part_out_value_used
      t.float :current_avg_price
      t.float :current_high_price
      t.float :current_low_price
      t.integer :current_listings
      t.references :lego_set, foreign_key: true

      t.timestamps
    end
  end
end

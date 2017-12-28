class CreateEbaySales < ActiveRecord::Migration[5.1]
  def change
    create_table :ebay_sales do |t|
      t.datetime :date
      t.float :avg_sales
      t.float :high_sale
      t.float :low_sale
      t.integer :listings
      t.references :lego_set, foreign_key: true

      t.timestamps
    end
  end
end

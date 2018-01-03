class AddBrickOwlUrlToLegoSet < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :brick_owl_url, :string
  end
end

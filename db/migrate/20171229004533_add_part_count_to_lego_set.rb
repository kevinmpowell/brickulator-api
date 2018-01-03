class AddPartCountToLegoSet < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :part_count, :integer
  end
end

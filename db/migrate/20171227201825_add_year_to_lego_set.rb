class AddYearToLegoSet < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :year, :integer
  end
end

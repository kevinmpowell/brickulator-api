class AddMsrpToLegoSet < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :msrp, :float
  end
end

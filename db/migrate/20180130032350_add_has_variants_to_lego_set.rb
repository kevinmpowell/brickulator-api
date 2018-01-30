class AddHasVariantsToLegoSet < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :has_variants, :boolean, :default => false, :null => false
  end
end

class AddFieldsToLegoSet < ActiveRecord::Migration[5.1]
  def change
    add_column :lego_sets, :number_variant, :string
    add_column :lego_sets, :brickset_url, :string
    add_column :lego_sets, :minifig_count, :integer
    add_column :lego_sets, :released, :boolean
    add_column :lego_sets, :packaging_type, :string
    add_column :lego_sets, :instructions_count, :integer

    add_index :lego_sets, [:number, :number_variant], unique: true
  end
end

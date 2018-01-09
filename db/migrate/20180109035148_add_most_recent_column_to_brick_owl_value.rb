class AddMostRecentColumnToBrickOwlValue < ActiveRecord::Migration[5.1]
  def change
    add_column :brick_owl_values, :most_recent, :boolean, :default => false, :null => false
    add_index :brick_owl_values, :most_recent, where: :most_recent  # partial index
  end
end

class AddPreferencesToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :preferences, :jsonb, :default => {}, :null => false
  end
end

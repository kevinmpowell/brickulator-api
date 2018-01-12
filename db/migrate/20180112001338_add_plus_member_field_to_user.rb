class AddPlusMemberFieldToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :plus_member, :boolean, :default => false, :null => false
    add_index :users, :plus_member
  end
end

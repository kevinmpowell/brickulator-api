class CreateLegoSets < ActiveRecord::Migration[5.1]
  def change
    create_table :lego_sets do |t|
      t.string :title
      t.string :number

      t.timestamps
    end
  end
end

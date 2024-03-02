class CreatePscoreEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :pscore_entries do |t|
      t.float :standard
      t.float :legacy
      t.float :modern
      t.float :pauper
      t.float :pioneer
      t.belongs_to :card

      t.timestamps
    end
  end
end

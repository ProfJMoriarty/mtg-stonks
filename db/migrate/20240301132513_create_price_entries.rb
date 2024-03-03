class CreatePriceEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :price_entries do |t|
      t.float :usd
      t.float :eur
      t.float :tix
      t.references :card

      t.timestamps
    end
  end
end

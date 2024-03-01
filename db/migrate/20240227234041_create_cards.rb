class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards, id: false, primary_key: :oracle_id do |t|
      t.string :name
      t.string :oracle_id

      t.timestamps
      t.index :oracle_id, unique: true
    end
  end
end

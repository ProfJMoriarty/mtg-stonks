class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.string :name
      t.string :oracle_id
      t.json :prices
      t.json :playability

      t.timestamps
    end
  end
end

class CreatePscoreCalculations < ActiveRecord::Migration[7.1]
  def change
    create_table :pscore_calculations do |t|
      t.float :overall7
      t.float :overall7_trend
      t.float :overall30
      t.float :overall30_trend
      t.float :standard7
      t.float :standard7_trend
      t.float :standard30
      t.float :standard30_trend
      t.float :pioneer7
      t.float :pioneer7_trend
      t.float :pioneer30
      t.float :pioneer30_trend
      t.float :modern7
      t.float :modern7_trend
      t.float :modern30
      t.float :modern30_trend
      t.float :pauper7
      t.float :pauper7_trend
      t.float :pauper30
      t.float :pauper30_trend
      t.float :legacy7
      t.float :legacy7_trend
      t.float :legacy30
      t.float :legacy30_trend
      t.references :card

      t.timestamps
    end
  end
end

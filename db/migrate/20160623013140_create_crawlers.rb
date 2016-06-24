class CreateCrawlers < ActiveRecord::Migration
  def change
    create_table :crawlers do |t|
      t.references :aliexpress, index: true, foreign_key: true
      t.references :wordpress, index: true, foreign_key: true
      t.boolean :enabled, default: false
      t.string :schedule, default: 'daily'

      t.timestamps null: false
    end
  end
end

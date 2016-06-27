class CreateCrawlerLogs < ActiveRecord::Migration
  def change
    create_table :crawler_logs do |t|
      t.references :crawler, index: true, foreign_key: true
      t.string :message, default: ""
      t.integer :processed, default: 0
      t.integer :orders_count, default: 0

      t.timestamps null: false
    end
  end
end

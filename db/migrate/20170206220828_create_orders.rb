class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.belongs_to :crawler, index: true, foreign_key: true
      t.string :aliexpress_number
      t.string :wordpress_reference
      t.string :tracking_number
      t.boolean :tracked, default: false

      t.timestamps null: false
    end
  end
end
class CreateWordpresses < ActiveRecord::Migration
  def change
    create_table :wordpresses do |t|
      t.string :url
      t.string :consumer_key
      t.string :consumer_secret

      t.timestamps null: false
    end
  end
end

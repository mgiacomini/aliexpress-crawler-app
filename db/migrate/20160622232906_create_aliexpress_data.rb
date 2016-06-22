class CreateAliexpressData < ActiveRecord::Migration
  def change
    create_table :aliexpress_data do |t|
      t.string :name
      t.string :email
      t.string :password

      t.timestamps null: false
    end
  end
end

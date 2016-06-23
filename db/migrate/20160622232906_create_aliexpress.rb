class CreateAliexpress < ActiveRecord::Migration
  def change
    create_table :aliexpresses do |t|
      t.string :name
      t.string :email
      t.string :password

      t.timestamps null: false
    end
  end
end

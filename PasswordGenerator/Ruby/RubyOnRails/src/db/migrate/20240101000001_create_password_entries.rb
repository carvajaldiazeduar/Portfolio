class CreatePasswordEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :password_entries do |t|
      t.string :password, null: false
      t.integer :length, default: 16
      t.timestamps
    end
  end
end
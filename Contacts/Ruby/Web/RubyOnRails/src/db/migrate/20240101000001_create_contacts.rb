class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :phone, default: ""
      t.string :email, default: ""
      t.timestamps
    end
  end
end
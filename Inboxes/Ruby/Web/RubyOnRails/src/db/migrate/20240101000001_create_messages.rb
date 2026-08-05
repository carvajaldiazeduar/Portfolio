class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.string :sender, null: false
      t.string :subject, null: false
      t.text :body, default: ""
      t.boolean :read, default: false
      t.timestamps
    end
  end
end
class CreateChats < ActiveRecord::Migration[5.0]
  def change
    create_table :chats do |t|
      t.string :app_token
      t.integer :creation_number
      t.string :messages_count
      t.string :integer

      t.timestamps
    end
  end
end

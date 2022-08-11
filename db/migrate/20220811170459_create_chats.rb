class CreateChats < ActiveRecord::Migration[5.0]
  def change
    create_table :chats do |t|
      t.string :application_token
      t.integer :chat_number
      t.string :messages_count

      t.timestamps
    end
  end
end

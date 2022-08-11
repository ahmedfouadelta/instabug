class AddUniqueIndexToChats < ActiveRecord::Migration[5.0]
  def change
    add_index :chats, [:application_token, :chat_number], unique: true
  end
end

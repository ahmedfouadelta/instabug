class AddUniqueIndexToChats < ActiveRecord::Migration[5.0]
  def change
    add_index :chats, [:creation_number , :application_token], unique: true
  end
end

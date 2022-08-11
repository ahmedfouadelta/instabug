class AddUniqueIndexToMessages < ActiveRecord::Migration[5.0]
  def change
    add_index :messages, [:creation_number, :chat_creation_number , :application_token], unique: true, name: 'messages_triple_index'
  end
end

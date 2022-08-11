class AddUniqueIndexToMessages < ActiveRecord::Migration[5.0]
  def change
    add_index :messages, [:application_token, :chat_number ,:message_number], unique: true, name: "index_messages_on_app_token_and_chat_no_and_msg_no"
  end
end

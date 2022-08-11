class AddChatToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :chat_id, :integer
    add_index :messages, :chat_id
  end
end

class ChangeMessagesCountColumnDefaultInChatModel < ActiveRecord::Migration[5.0]
  def up
    change_column :chats, :messages_count, :integer, default: 0
  end
  
  def down
    change_column :chats, :messages_count, :integer, default: nil
  end
end

class AddChatsCountToApplications < ActiveRecord::Migration[5.0]
  def change
    add_column :applications, :chats_count, :integer, default: 0
  end
end

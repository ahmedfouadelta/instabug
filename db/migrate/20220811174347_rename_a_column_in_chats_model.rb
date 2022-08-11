class RenameAColumnInChatsModel < ActiveRecord::Migration[5.0]
  def change
    rename_column :chats, :app_token, :application_token
  end
end

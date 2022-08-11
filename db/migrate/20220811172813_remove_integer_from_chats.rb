class RemoveIntegerFromChats < ActiveRecord::Migration[5.0]
  def change
    remove_column :chats, :integer, :string
  end
end

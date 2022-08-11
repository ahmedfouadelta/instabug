class AddIndexToTokenInApplication < ActiveRecord::Migration[5.0]
  def change
    add_index :applications, :token, :unique => true
  end
end

class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.string :application_token
      t.integer :chat_number
      t.integer :message_number
      t.string :body

      t.timestamps
    end
  end
end

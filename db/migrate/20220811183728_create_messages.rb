class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.string :application_token
      t.integer :chat_creation_number
      t.integer :creation_number
      t.string :message_body

      t.timestamps
    end
  end
end

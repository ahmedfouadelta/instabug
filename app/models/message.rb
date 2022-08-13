class Message < ApplicationRecord
    belongs_to :chat
    validates :body, presence: true
    validates :chat_number, presence: true
    validates :application_token, presence: true
    validates :message_number, uniqueness: { scope: [:chat_number, :application_token] }
end

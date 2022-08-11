class Message < ApplicationRecord
    belongs_to :chat
    validates :message_body, presence: true
    validates :chat_creation_number, presence: true
    validates :application_token, presence: true
    validates :creation_number, uniqueness: { scope: [:chat_creation_number, :application_token] }
end

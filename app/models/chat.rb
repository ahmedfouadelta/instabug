class Chat < ApplicationRecord
    belongs_to :application
    validates :creation_number , uniqueness: { scope: :application_token}
    validates :application_id, presence: true
    validates :application_token, presence: true
    has_many :messages, dependent: :destroy
end

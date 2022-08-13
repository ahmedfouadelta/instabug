class CreateChatJob
  # sidekiq_options retry: false
  include Sidekiq::Job

  def perform(application_id, application_token, chat_number)
    Chat.create!(application_id: application_id, application_token: application_token, chat_number: chat_number)
  end
end


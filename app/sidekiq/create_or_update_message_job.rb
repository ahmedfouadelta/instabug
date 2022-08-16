require "redis"
class CreateOrUpdateMessageJob
  # sidekiq_options retry: false
  include Sidekiq::Job

  def perform(application_token, chat_number, message_number)
    chat = ChatRepo.new.load_chat(application_token, chat_number)
    raise if chat.nil? # will be logging here

    if chat["id"].nil?
      CreateOrUpdateChatJob.new.perform(
        application_token, chat_number, message_number
      )
    end

    message = MessageRepo.new.load_message(application_token, chat_number, message_number)
    if message.nil?
      raise
    elsif message["id"].nil?
      chat = ChatRepo.new.load_chat(application_token, chat_number) if chat["id"].nil?
      created_message = Message.create!(
        chat_id: chat.id, application_token: application_token, chat_number: chat_number,
        message_number: message_number, body: message.body
      ) 
      @redis = Redis.new(host: "host.docker.internal")
      @redis.set("Message_#{application_token}_#{chat_number}_#{message_number}", created_message.to_json, px: 86400000)
    elsif message.present?
      message.update!(body: message.body)
    end
  end
end

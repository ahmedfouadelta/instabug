require "redis"
class CreateOrUpdateChatJob
  # sidekiq_options retry: false
  include Sidekiq::Job

  def perform(application_token, chat_number)
    chat = ChatRepo.new.load_chat(application_token, chat_number)
    raise if chat.nil?

    if chat["id"].nil?
      app = ApplicationRepo.new.load_app(application_token)
      created_chat = Chat.create(chat.attributes.merge!(application_id: app.id))
      @redis = Redis.new(host: "host.docker.internal")
      @redis.set("Chat_#{application_token}_#{chat_number}", created_chat.to_json, px: 86400000)
    else
      Chat.find_by(id: chat.id).update(messages_count: chat.messages_count)
    end
  end
end


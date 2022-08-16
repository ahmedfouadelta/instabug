require "redis"
class ChatRepo
  def load_chat(application_token, chat_number)
    redis = Redis.new(host: "host.docker.internal")
    chat_json = redis.get("Chat_#{application_token}_#{chat_number}")
    return Chat.new(JSON.parse(chat_json)) if chat_json.present?

    chat = Chat.find_by(application_token: application_token, chat_number: chat_number)
    return nil if chat.nil?

    redis.set("Chat_#{application_token}_#{chat_number}", chat.to_json, nx: true, px: 86400000)
    return chat
  end
end

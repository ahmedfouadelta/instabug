require "redis"
class MessageRepo
  def load_message(application_token, chat_number, message_number)
    redis = Redis.new(host: "host.docker.internal")
    message_json = redis.get("Message_#{application_token}_#{chat_number}_#{message_number}")
    return Message.new(JSON.parse(message_json)) if message_json.present? 

    message = Message.find_by(
      application_token: application_token, chat_number: chat_number, message_number: message_number
    )
    return nil if message.nil?

    redis.set("Message_#{application_token}_#{chat_number}_#{message_number}", app.to_json, nx: true, px: 86400000)
    return message
  end
end

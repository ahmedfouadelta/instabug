require "redis"
class CreateMessageJob
  # sidekiq_options retry: false
  include Sidekiq::Job

  def perform(chat_id, application_token, chat_number, message_number, body)
    redis = Redis.new(host: "host.docker.internal")
    Message.create!(
      chat_id: chat_id, application_token: application_token, chat_number: chat_number,
      message_number: message_number, body: body
    )
    redis.del("#{application_token}_#{chat_number.to_s}_#{message_number.to_s}")
  end
end

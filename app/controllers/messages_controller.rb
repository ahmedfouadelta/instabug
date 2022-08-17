require "redis"
class MessagesController < ApplicationController
  def initialize
    @redis = Redis.new(host: "host.docker.internal")
  end

  def create #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      chat_lock_val = add_lock("Lock_Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}"); raise if chat_lock_val == false

      chat = ChatRepo.new.load_chat(request.headers["TOKEN"], message_params[:chat_number])
      if chat.nil?
        remove_lock("Lock_Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", chat_lock_val)
        return render json: { error: "Chat's not found" }, status: 404
      end

      chat.messages_count+=1;
      message = Message.new(
        application_token: app.token,
        chat_number: chat.chat_number,
        message_number: chat.messages_count,
        body: message_params[:body]
      )

      CreateOrUpdateMessageJob.perform_in( 2.seconds, app.token, chat.chat_number, message.message_number)
      
      CreateOrUpdateChatJob.perform_in(20.seconds, app.token, chat.chat_number 
      )
     
      success = @redis.multi do |multi|
        multi.set(
          "Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", chat.to_json, px: 86400000
        )
         #  multi.hincrby("Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", "messages_count", 1)
        multi.set(
          "Message_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}_#{message.message_number}",
          message.to_json, px: 86400000
        ) 
      end



      remove_lock("Lock_Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", chat_lock_val)

      raise if success != ["OK", "OK"]
      render(
        json: {
          success: true,
          message: MessageSerializer.new(message).to_h
        },
          status: :created,
      )
    rescue
      remove_lock("Lock_Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", chat_lock_val)
      return render json: { error: "Something went wrong" }, status: 500
    end
  end

  def update #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      chat = ChatRepo.new.load_chat(request.headers["TOKEN"], message_params[:chat_number])
      return render json: { error: "Chat's not found" }, status: 404 if chat.nil?

      message = MessageRepo.new.load_message(request.headers["TOKEN"], chat.chat_number, message_params[:message_number])
      return render json: { error: "Message's not found" }, status: 404 if message.nil?

      message = Message.new(message.attributes.except("body").merge!("body": message_params[:body]))

      CreateOrUpdateMessageJob.perform_in( 2.seconds, app.token, chat.chat_number, message.message_number)

      @redis.set(
        "Message_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}_#{message.message_number}",
        message.to_json, px: 86400000
      )

      render(
        json: {
          success: true,
          message: MessageSerializer.new(message).to_h
        },
          status: :ok,
      )

    rescue
      return render json: { error: "Something went wrong" }, status: 500
    end
  end

  def show #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      chat = ChatRepo.new.load_chat(request.headers["TOKEN"], message_params[:chat_number])
      return render json: { error: "Chat's not found" }, status: 404 if chat.nil?

      message = MessageRepo.new.load_message(request.headers["TOKEN"], chat.chat_number, message_params[:message_number])
      return render json: { error: "Message's not found" }, status: 404 if message.nil?

      render(
        json: {
          success: true,
          message: MessageSerializer.new(message).to_h
        },
          status: :ok,
      )

    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  def index
    # depend on redis more than the database (if we have the record on both then take the one on redis)
    app = Application.find_by(token: request.headers["TOKEN"]) 
    if app.nil?
      return render json: { error: "no app exists with this token" }, status: 404 
    end

    chat = app.chats.find_by(chat_number: message_params[:chat_number])
    if chat.nil? && message_params[:chat_number] > app.chats_count
      return render json: { error: "no chat exists with this number" }, status: 404
    elsif chat.nil? && message_params[:chat_number] <= app.chats_count
      return render json: { error: "no messages exist for this chat" }, status: 404
    end

    all_messages_numbers = Array(1..chat.messages_count)
    created_messages_numbers = chat.messages.pluck(:message_number)
    not_created_yet_messages_numbers = all_messages_numbers - created_messages_numbers
    arr_of_messages= MessageSerializer.new(chat.messages).to_h

    redis = Redis.new(host: "host.docker.internal")

    not_created_yet_messages_numbers.each do |message_number|
      message_body = redis.get("#{request.headers["TOKEN"]}_#{message_params[:chat_number].to_s}_#{message_number.to_s}")
      arr_of_messages.push({message_number: message_number, body: message_body})
    end

    render(
      json: {
        success: true,
        messages: arr_of_messages, 
      },
        status: :ok,
    )

  end

  def search
    app = Application.find_by(token: request.headers["TOKEN"]) 
    if app.nil?
      return render json: { error: "no app exists with this token" }, status: 404 
    end

    chat = app.chats.find_by(chat_number: message_params[:chat_number])
    if chat.nil? && message_params[:chat_number] > app.chats_count
      return render json: { error: "no chat exists with this number" }, status: 404
    elsif chat.nil? && message_params[:chat_number] <= app.chats_count
      return render json: { error: "no messages exist for this chat" }, status: 404
    end

    all_messages_numbers = Array(1..chat.messages_count)
    created_messages_numbers = chat.messages.pluck(:chat_number)
    not_created_yet_messages_numbers = all_messages_numbers - created_messages_numbers
    arr_of_messages= MessageSerializer.new(chat.messages).to_h

    redis = Redis.new(host: "host.docker.internal")

    not_created_yet_messages_numbers.each do |message_number|
      message_body = redis.get("#{request.headers["TOKEN"]}_#{message_params[:chat_number].to_s}_#{message_number.to_s}")
      arr_of_messages.push({message_number: message_number, body: message_body})
    end

    render(
      json: {
        success: true,
        messages: arr_of_messages.where("body like ?", "%#{message_params[:body]}%") 
      },
        status: :ok,
    )
  end

  private

  def message_params
    params.require(:message).permit(:chat_number, :body, :message_number)
  end
end

# @redis.mapped_hmset("best3", message.attributes)
#  @redis.hincrby("best3","chat_number", 1)
# ap @redis.hgetall("best3").json?

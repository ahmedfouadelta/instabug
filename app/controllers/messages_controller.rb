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

  def index #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      chat = ChatRepo.new.load_chat(request.headers["TOKEN"], message_params[:chat_number])
      return render json: { error: "Chat's not found" }, status: 404 if chat.nil?
      return render json: { error: "No Messages were found for this Chat" }, status: 404 if chat.messages_count.zero?


      database_messages = chat.messages
      database_messages_ids = chat.messages.pluck(:message_number)
      all_messages_ids = Array(1..chat.messages_count)
      redis_messages_ids = all_messages_ids - database_messages_ids
      messages_arr = []

      database_messages.each do |message|
        messages_arr << {message_number: message.message_number, body: message.body}
      end

      redis_messages_ids.each do |message_number|
        message = JSON.parse(
          @redis.get("Message_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}_#{message_number}")
        )
        messages_arr << {message_number: message["message_number"], body: message["body"]}
      end

      render(
        json: {
          success: true,
          messages: messages_arr, 
        },
          status: :ok,
      )
    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  def search #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      chat = ChatRepo.new.load_chat(request.headers["TOKEN"], message_params[:chat_number])
      return render json: { error: "Chat's not found" }, status: 404 if chat.nil?
      return render json: { error: "No Messages were found for this Chat" }, status: 404 if chat.messages_count.zero?

      messages = chat.messages.where('body LIKE ?', "%#{params[:searched_text]}%")

      render(
        json: {
          success: true,
          messages: MessageSerializer.new(messages).to_h
        },
          status: :ok,
      )
    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  private

  def message_params
    params.require(:message).permit(:chat_number, :body, :message_number)
  end
end

require "redis"
class MessagesController < ApplicationController
  def create
    begin
      # add a lock here on redis for app with this token
      app_lock_val = add_lock("Application_#{request.headers["TOKEN"]}"); raise if app_lock_val == false

      app = Application.find_by(token: request.headers["TOKEN"])
      if app.nil?
        # release the app lock
        raise if remove_lock("Application_#{request.headers["TOKEN"]}", app_lock_val) == false 
        return render json: { error: "no app exists with this token" }, status: 404 
      end

      # add a lock here on redis for chat with this app token and chat number
      chat_lock_val = add_lock("Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}"); raise if chat_lock_val == false

      chat = app.chats.find_by(chat_number: message_params[:chat_number])
      if chat.nil? && message_params[:chat_number] > app.chats_count
        # release the chat lock
        raise if remove_lock("Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", chat_lock_val) == false 
        # release the app lock
        raise if remove_lock("Application_#{request.headers["TOKEN"]}", app_lock_val) == false
        render json: { error: "no chat with this number exists" }, status: 404
      elsif message_params[:chat_number] <= app.chats_count
        if chat.nil? 
          chat = Chat.create!(
            application_id: app.id, application_token: request.headers["TOKEN"],
            messages_count: 1, chat_number: message_params[:chat_number]
          )
        else
          chat.update!(messages_count: chat.messages_count+1)
        end
        redis = Redis.new(host: "host.docker.internal")
        redis.set("#{app.token}_#{chat.chat_number.to_s}_#{chat.messages_count.to_s}", message_params[:body])
        CreateMessageJob.perform_sync(
          chat.id, app.token, chat.chat_number, chat.messages_count, message_params[:body]
        )
        # release the chat lock
        raise if remove_lock("Chat_#{request.headers["TOKEN"]}_#{message_params[:chat_number]}", chat_lock_val) == false 
        # release the app lock
        raise if remove_lock("Application_#{request.headers["TOKEN"]}", app_lock_val) == false 
        render(
          json: {
            success: true,
            message: {
              message_number: chat.messages_count,
              body: message_params[:body],  
            }
          },
            status: :created,
        )

      end
    rescue
      return render json: { error: "Something went wrong" }, status: 500
    end
  end

  def update
    # add a lock here on redis for app with this token
    app = Application.find_by(token: request.headers["TOKEN"]) 
    if app.nil?
      # release the app lock
      return render json: { error: "no app exists with this token" }, status: 404 
    end

    # add a lock here on redis for chat with this app token and chat number
    chat = app.chats.find_by(chat_number: message_params[:chat_number])
    if chat.nil? && message_params[:chat_number] > app.chats_count
      # release the chat lock
      # release the app lock
      return render json: { error: "no chat exists with this number" }, status: 404
    elsif chat.nil? && message_params[:chat_number] <= app.chats_count
      # release the chat lock
      # release the app lock
      return render json: { error: "no message exist with this number" }, status: 404
    end

    message = chat.messages.find_by(
      application_token: request.headers["TOKEN"], message_number: message_params[:message_number],
      chat_number: message_params[:chat_number]
    )

    if message.nil? &&  message_params[:message_number] > chat.messages_count
      # release the chat lock
      # release the app lock
      return render json: { error: "no message exist with this number" }, status: 404
    elsif message.nil? &&  message_params[:message_number] <= chat.messages_count
      # it's better to update the redis key body to the new one and send another update background job then fake the response
      message = Message.create!(
        application_token: request.headers["TOKEN"],
        message_number: message_params[:message_number],
        chat_number: message_params[:chat_number],
        body: message_params[:body],
        chat_id: chat.id
      )
      redis = Redis.new(host: "host.docker.internal")
      redis.del("#{request.headers["TOKEN"]}_#{message_params[:chat_number].to_s}_#{message_params[:message_number].to_s}")
      # release the chat lock
      # release the app lock
      return render(
        json: {
          success: true,
          message: MessageSerializer.new(message).to_h
        },
          status: :ok,
      )
    else
      # it's better to update the redis key body to the new one and send another update background job then fake the response
      # expires after 24 hours
      message.update!(body: message_params[:body])
      # release the chat lock
      # release the app lock
      return render(
        json: {
          success: true,
          message: MessageSerializer.new(message).to_h
        },
          status: :ok,
      )
    end
  end

  def show
    app = Application.find_by(token: request.headers["TOKEN"]) 
    if app.nil?
      return render json: { error: "no app exists with this token" }, status: 404 
    end

    chat = app.chats.find_by(chat_number: message_params[:chat_number])
    if chat.nil? && message_params[:chat_number] > app.chats_count
      return render json: { error: "no chat exists with this number" }, status: 404
    elsif chat.nil? && message_params[:chat_number] <= app.chats_count
      return render json: { error: "no message exist with this number" }, status: 404
    end

    message = chat.messages.find_by(
      application_token: request.headers["TOKEN"], message_number: message_params[:message_number],
      chat_number: message_params[:chat_number]
    )

    if message.nil? &&  message_params[:message_number] > chat.messages_count
      return render json: { error: "no message exist with this number" }, status: 404
    elsif message.nil? &&  message_params[:message_number] <= chat.messages_count
      redis = Redis.new(host: "host.docker.internal")
      message_body = redis.get("#{request.headers["TOKEN"]}_#{message_params[:chat_number].to_s}_#{message_params[:message_number].to_s}")
      return render(
        json: {
          success: true,
          message: {
            message_number: message_params[:message_number],
            body: message_body,
          }
        },
          status: :ok,
      )
    else
      return render(
        json: {
          success: true,
          message: MessageSerializer.new(message).to_h
        },
          status: :ok,
      )
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
